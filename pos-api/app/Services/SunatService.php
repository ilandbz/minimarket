<?php

namespace App\Services;

use App\Models\Sale;
use App\Models\Customer;
use Greenter\See;
use Greenter\Model\Company\Company;
use Greenter\Model\Client\Client;
use Greenter\Model\Sale\Invoice;
use Greenter\Model\Sale\SaleDetail;
use Greenter\Model\Sale\Legend;
use Greenter\Ws\Services\SunatEndpoints;
use DateTime;
use Illuminate\Support\Facades\Storage;

class SunatService
{
    /**
     * Obtiene la instancia configurada de Greenter See.
     */
    private function getSee(): See
    {
        $see = new See();
        $see->setService(SunatEndpoints::FE_BETA);
        $see->setCertificate($this->getCertificatePem());
        // Credenciales SOL de prueba de SUNAT
        $see->setClaveSOL('20000000001', 'MODDATOS', 'MODDATOS');

        return $see;
    }

    /**
     * Envía un comprobante de venta a SUNAT.
     */
    public function sendInvoice(Sale $sale): array
    {
        // Si es Nota de Venta, no se envía a SUNAT
        if ($sale->document_type === 'NOTA_VENTA') {
            return [
                'success' => true,
                'message' => 'Nota de Venta registrada internamente.'
            ];
        }

        try {
            $see = $this->getSee();

            // 1. Configurar Emisor
            $company = new Company();
            $company->setRuc('20000000001')
                ->setRazonSocial('MINIMARKET LA ECONOMICA S.A.C.')
                ->setNombreComercial('Minimarket La Económica')
                ->setAddress((new \Greenter\Model\Company\Address())
                    ->setUbigueo('150101') // Lima
                    ->setDepartamento('LIMA')
                    ->setProvincia('LIMA')
                    ->setDistrito('LIMA')
                    ->setUrbanizacion('CENTRO')
                    ->setDireccion('Av. Principal 123'));

            // 2. Configurar Cliente
            $client = new Client();
            $customer = $sale->customer;
            
            if ($customer && $customer->document_type !== 'VARIOS') {
                $tipoDoc = $customer->document_type === 'RUC' ? '6' : '1'; // 6=RUC, 1=DNI
                $client->setTipoDoc($tipoDoc)
                    ->setNumDoc($customer->document_number)
                    ->setRznSocial($customer->name)
                    ->setAddress((new \Greenter\Model\Client\Address())
                        ->setDireccion($customer->address ?? '-'));
            } else {
                // Cliente Genérico (Boleta con DNI 00000000)
                $client->setTipoDoc('0') // No domiciliado/Varios
                    ->setNumDoc('00000000')
                    ->setRznSocial('CLIENTES VARIOS');
            }

            // 3. Crear el Comprobante (Factura o Boleta)
            $invoice = new Invoice();
            $tipoDocComprobante = $sale->document_type === 'FACTURA' ? '01' : '03'; // 01=Factura, 03=Boleta
            
            $invoice->setUblVersion('2.1')
                ->setTipoOperacion('0101') // Venta interna
                ->setTipoDoc($tipoDocComprobante)
                ->setSerie($sale->serie)
                ->setCorrelativo((string)$sale->correlativo)
                ->setFechaEmision(new DateTime($sale->created_at))
                ->setTipoMoneda('PEN')
                ->setCompany($company)
                ->setClient($client)
                ->setMtoOperGravadas($sale->total_gravada)
                ->setMtoIGV($sale->total_igv)
                ->setTotalImpuestos($sale->total_igv)
                ->setValorVenta($sale->total_gravada)
                ->setSubTotal($sale->total_amount)
                ->setMtoImpVenta($sale->total_amount);

            // 4. Agregar Detalles del Comprobante
            $details = [];
            foreach ($sale->items as $index => $item) {
                $detail = new SaleDetail();
                
                $precioUnitario = $item->price;
                $valorUnitario = $precioUnitario / 1.18;
                $cantidad = $item->quantity;
                
                $mtoValorVenta = $valorUnitario * $cantidad;
                $igv = $item->igv;
                
                $detail->setCodProducto('P' . str_pad($item->product_id, 4, '0', STR_PAD_LEFT))
                    ->setUnidad('NIU') // Unidad física
                    ->setCantidad($cantidad)
                    ->setDescripcion($item->product->name)
                    ->setMtoValorUnitario($valorUnitario)
                    ->setMtoBaseIgv($mtoValorVenta)
                    ->setPorcentajeIgv(18.00)
                    ->setIgv($igv)
                    ->setTipAfeIgv('10') // Gravado - Operación Onerosa
                    ->setMtoValorVenta($mtoValorVenta)
                    ->setMtoPrecioUnitario($precioUnitario);

                $details[] = $detail;
            }
            $invoice->setDetails($details);

            // Leyenda de monto en letras (ejemplo simple)
            $totalLetras = $this->num2letras($sale->total_amount);
            $invoice->setLegends([
                (new Legend())
                    ->setCode('1000')
                    ->setValue($totalLetras)
            ]);

            // 5. Enviar a SUNAT
            $result = $see->send($invoice);

            // Guardar XML Firmado
            $xmlSigned = $see->getXmlSigned($invoice);
            $xmlFilename = $sale->document_type . '-' . $sale->serie . '-' . $sale->correlativo . '.xml';
            Storage::put('public/sunat/xml/' . $xmlFilename, $xmlSigned);
            $sale->xml_path = 'storage/sunat/xml/' . $xmlFilename;

            if ($result->isSuccess()) {
                $cdrZip = $result->getCdrZip();
                $cdrFilename = 'R-' . $sale->document_type . '-' . $sale->serie . '-' . $sale->correlativo . '.zip';
                Storage::put('public/sunat/cdr/' . $cdrFilename, $cdrZip);
                
                $cdrResponse = $result->getCdrResponse();
                
                $sale->cdr_path = 'storage/sunat/cdr/' . $cdrFilename;
                $sale->estado_sunat = 'ACEPTADO';
                $sale->hash_sunat = $this->getXmlHash($xmlSigned);
                $sale->mensaje_sunat = $cdrResponse->getDescription();
                $sale->save();

                return [
                    'success' => true,
                    'message' => 'Comprobante aceptado por SUNAT.',
                    'cdr_description' => $cdrResponse->getDescription(),
                    'hash' => $sale->hash_sunat
                ];
            } else {
                $error = $result->getError();
                $errorMessage = 'Código: ' . $error->getCode() . ' - ' . $error->getMessage();
                
                $sale->estado_sunat = 'ERROR';
                $sale->mensaje_sunat = $errorMessage;
                $sale->save();

                return [
                    'success' => false,
                    'message' => 'Error al comunicar con SUNAT.',
                    'error_details' => $errorMessage
                ];
            }
        } catch (\Exception $e) {
            $sale->estado_sunat = 'ERROR';
            $sale->mensaje_sunat = $e->getMessage();
            $sale->save();

            return [
                'success' => false,
                'message' => 'Excepción interna en facturación.',
                'error_details' => $e->getMessage()
            ];
        }
    }

    /**
     * Genera u obtiene un certificado digital auto-firmado de prueba en formato PEM.
     */
    private function getCertificatePem(): string
    {
        $path = storage_path('app/sunat/certificate.pem');
        
        if (!file_exists(dirname($path))) {
            mkdir(dirname($path), 0755, true);
        }

        if (!file_exists($path)) {
            // Generar clave privada y certificado de prueba autofirmado
            $privateKey = openssl_pkey_new([
                "private_key_bits" => 2048,
                "private_key_type" => OPENSSL_KEYTYPE_RSA,
            ]);
            
            $dn = [
                "countryName" => "PE",
                "stateOrProvinceName" => "Lima",
                "localityName" => "Lima",
                "organizationName" => "Minimarket La Economica S.A.C.",
                "organizationalUnitName" => "Sistemas",
                "commonName" => "20000000001", // RUC de prueba
                "emailAddress" => "facturacion@minimarket.com"
            ];
            
            $csr = openssl_csr_new($dn, $privateKey, ['digest_alg' => 'sha256']);
            $x509 = openssl_csr_sign($csr, null, $privateKey, 365, ['digest_alg' => 'sha256']);
            
            openssl_x509_export($x509, $certOut);
            openssl_pkey_export($privateKey, $pkeyOut);
            
            $pemContent = $certOut . "\n" . $pkeyOut;
            file_put_contents($path, $pemContent);
        }

        return file_get_contents($path);
    }

    /**
     * Extrae el código Hash del XML firmado.
     */
    private function getXmlHash(string $xmlContent): string
    {
        $dom = new \DOMDocument();
        $dom->loadXML($xmlContent);
        $xpath = new \DOMXPath($dom);
        $xpath->registerNamespace('ds', 'http://www.w3.org/2000/09/xmldsig#');
        $nodes = $xpath->query('//ds:DigestValue');
        if ($nodes->length > 0) {
            return $nodes->item(0)->nodeValue;
        }
        return '';
    }

    /**
     * Convierte montos numéricos a texto de Leyenda.
     */
    private function num2letras(float $numero): string
    {
        $enteros = floor($numero);
        $centavos = round(($numero - $enteros) * 100);
        $centavosStr = str_pad((string)$centavos, 2, '0', STR_PAD_LEFT);
        
        $formatter = new \NumberFormatter('es', \NumberFormatter::SPELLOUT);
        $texto = $formatter->format($enteros);
        
        return strtoupper($texto) . ' CON ' . $centavosStr . '/100 SOLES';
    }
}
