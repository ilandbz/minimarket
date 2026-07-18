<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Category;
use App\Models\Product;
use App\Models\Customer;
use App\Models\Sale;
use App\Models\SaleItem;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Crear Usuarios
        $admin = User::create([
            'name' => 'Administrador POS',
            'email' => 'admin@minimarket.com',
            'password' => Hash::make('admin123'),
            'role' => 'admin',
            'status' => 'active',
        ]);

        $vendedor = User::create([
            'name' => 'Vendedor Juan',
            'email' => 'vendedor@minimarket.com',
            'password' => Hash::make('vendedor123'),
            'role' => 'vendedor',
            'status' => 'active',
        ]);

        // 2. Crear Categorías
        $catAbarrotes = Category::create(['name' => 'Abarrotes', 'description' => 'Productos básicos del hogar']);
        $catBebidas = Category::create(['name' => 'Bebidas', 'description' => 'Gaseosas, aguas, jugos']);
        $catLacteos = Category::create(['name' => 'Lácteos', 'description' => 'Leche, queso, yogures']);
        $catLimpieza = Category::create(['name' => 'Limpieza', 'description' => 'Detergentes, jabones, desinfectantes']);

        // 3. Crear Productos
        $productsData = [
            [
                'category_id' => $catAbarrotes->id,
                'name' => 'Arroz Costeño 1kg',
                'description' => 'Arroz extra costeño',
                'barcode' => '7750102030405',
                'price' => 4.50,
                'cost_price' => 3.20,
                'stock' => 100,
                'alert_stock' => 10,
            ],
            [
                'category_id' => $catAbarrotes->id,
                'name' => 'Aceite Primor Premium 1L',
                'description' => 'Aceite vegetal',
                'barcode' => '7750102030406',
                'price' => 11.50,
                'cost_price' => 8.50,
                'stock' => 50,
                'alert_stock' => 8,
            ],
            [
                'category_id' => $catBebidas->id,
                'name' => 'Coca Cola 1.5L',
                'description' => 'Gaseosa Coca Cola original',
                'barcode' => '7750102030407',
                'price' => 6.00,
                'cost_price' => 4.20,
                'stock' => 120,
                'alert_stock' => 15,
            ],
            [
                'category_id' => $catBebidas->id,
                'name' => 'Agua Cielo sin Gas 625ml',
                'description' => 'Agua de mesa',
                'barcode' => '7750102030408',
                'price' => 2.00,
                'cost_price' => 1.00,
                'stock' => 4, // Stock crítico para ver alertas
                'alert_stock' => 10,
            ],
            [
                'category_id' => $catLacteos->id,
                'name' => 'Leche Gloria Azul 400g',
                'description' => 'Leche evaporada entera',
                'barcode' => '7750102030409',
                'price' => 4.20,
                'cost_price' => 3.10,
                'stock' => 80,
                'alert_stock' => 12,
            ],
            [
                'category_id' => $catLacteos->id,
                'name' => 'Yogurt Gloria Fresa 1L',
                'description' => 'Yogurt bebible',
                'barcode' => '7750102030410',
                'price' => 6.50,
                'cost_price' => 4.80,
                'stock' => 3, // Stock crítico para alertas
                'alert_stock' => 8,
            ],
            [
                'category_id' => $catLimpieza->id,
                'name' => 'Detergente Opal Ultra 1kg',
                'description' => 'Detergente en polvo',
                'barcode' => '7750102030411',
                'price' => 9.80,
                'cost_price' => 7.00,
                'stock' => 40,
                'alert_stock' => 5,
            ],
        ];

        $products = [];
        foreach ($productsData as $pData) {
            $products[] = Product::create($pData);
        }

        // 4. Crear Clientes
        $cGeneric = Customer::create([
            'name' => 'Clientes Varios',
            'document_type' => 'VARIOS',
            'document_number' => '00000000',
        ]);

        $cDni = Customer::create([
            'name' => 'Carlos Pérez',
            'document_type' => 'DNI',
            'document_number' => '12345678',
            'phone' => '987654321',
            'email' => 'carlos@gmail.com',
            'address' => 'Av. Larco 123, Miraflores',
        ]);

        $cRuc = Customer::create([
            'name' => 'Distribuidora Alianza S.A.C.',
            'document_type' => 'RUC',
            'document_number' => '20601234567',
            'phone' => '014445555',
            'email' => 'contacto@alianza.pe',
            'address' => 'Jr. Puno 456, Lima Centro',
        ]);

        // 5. Crear Ventas de prueba en los últimos 7 días
        $paymentMethods = ['cash', 'card', 'transfer'];
        $documentTypes = ['NOTA_VENTA', 'BOLETA', 'FACTURA'];
        
        $correlativos = [
            'BOLETA' => 1,
            'FACTURA' => 1,
        ];

        for ($i = 6; $i >= 0; $i--) {
            // Generar entre 2 y 4 ventas por día
            $salesCount = rand(2, 4);
            $date = Carbon::now()->subDays($i)->setHour(rand(9, 21))->setMinute(rand(0, 59));
            
            for ($s = 0; $s < $salesCount; $s++) {
                $docType = $documentTypes[rand(0, 2)];
                $customer = $cGeneric;
                
                if ($docType == 'BOLETA') {
                    $customer = rand(0, 1) ? $cDni : $cGeneric;
                } elseif ($docType == 'FACTURA') {
                    $customer = $cRuc;
                }
                
                $method = $paymentMethods[rand(0, 2)];
                $sellerUser = rand(0, 1) ? $vendedor : $admin;
                
                // Seleccionar entre 1 y 3 productos al azar
                $itemsCount = rand(1, 3);
                $selectedProducts = array_slice($products, 0, $itemsCount);
                
                $totalVal = 0;
                $totalCost = 0;
                $totalIgv = 0;
                
                $tempItems = [];
                
                foreach ($selectedProducts as $p) {
                    $qty = rand(1, 3);
                    $sub = $p->price * $qty;
                    $itemCost = $p->cost_price * $qty;
                    
                    // Cálculo de IGV (18% incluido en el precio)
                    // Precio = Base * 1.18 -> Base = Precio / 1.18 -> IGV = Precio - Base
                    $base = $sub / 1.18;
                    $igv = $sub - $base;
                    
                    $totalVal += $sub;
                    $totalCost += $itemCost;
                    $totalIgv += $igv;
                    
                    $tempItems[] = [
                        'product_id' => $p->id,
                        'quantity' => $qty,
                        'price' => $p->price,
                        'cost_price' => $p->cost_price,
                        'igv' => round($igv, 2),
                        'subtotal' => $sub,
                    ];
                }
                
                $serie = null;
                $correlativoVal = null;
                $estadoSunat = 'PENDIENTE';
                
                if ($docType == 'BOLETA') {
                    $serie = 'B001';
                    $correlativoVal = $correlativos['BOLETA']++;
                    $estadoSunat = 'ACEPTADO';
                } elseif ($docType == 'FACTURA') {
                    $serie = 'F001';
                    $correlativoVal = $correlativos['FACTURA']++;
                    $estadoSunat = 'ACEPTADO';
                }
                
                $paid = ceil($totalVal / 10) * 10;
                if ($method != 'cash') {
                    $paid = $totalVal;
                }
                
                $sale = Sale::create([
                    'user_id' => $sellerUser->id,
                    'customer_id' => $customer->id,
                    'total_amount' => $totalVal,
                    'payment_method' => $method,
                    'amount_paid' => $paid,
                    'change_returned' => round($paid - $totalVal, 2),
                    'status' => 'completed',
                    'document_type' => $docType,
                    'serie' => $serie,
                    'correlativo' => $correlativoVal,
                    'estado_sunat' => $estadoSunat,
                    'hash_sunat' => $docType != 'NOTA_VENTA' ? md5($serie . '-' . $correlativoVal) : null,
                    'mensaje_sunat' => $docType != 'NOTA_VENTA' ? 'El comprobante ha sido aceptado.' : null,
                    'total_igv' => round($totalIgv, 2),
                    'total_gravada' => round($totalVal - $totalIgv, 2),
                    'created_at' => $date,
                    'updated_at' => $date,
                ]);
                
                foreach ($tempItems as $item) {
                    $item['sale_id'] = $sale->id;
                    $item['created_at'] = $date;
                    $item['updated_at'] = $date;
                    SaleItem::create($item);
                }
            }
        }
    }
}
