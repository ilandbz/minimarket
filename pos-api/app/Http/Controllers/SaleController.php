<?php

namespace App\Http\Controllers;

use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\Product;
use App\Services\SunatService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SaleController extends Controller
{
    protected $sunatService;

    public function __construct(SunatService $sunatService)
    {
        $this->sunatService = $sunatService;
    }

    public function index(Request $request)
    {
        $query = Sale::with(['user', 'customer'])->orderBy('created_at', 'desc');

        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereBetween('created_at', [$request->start_date . ' 00:00:00', $request->end_date . ' 23:59:59']);
        }

        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        if ($request->has('document_type')) {
            $query->where('document_type', $request->document_type);
        }

        return response()->json($query->get());
    }

    public function show($id)
    {
        $sale = Sale::with(['user', 'customer', 'items.product'])->find($id);

        if (!$sale) {
            return response()->json(['message' => 'Venta no encontrada.'], 404);
        }

        return response()->json($sale);
    }

    public function store(Request $request)
    {
        $request->validate([
            'customer_id' => 'nullable|exists:customers,id',
            'payment_method' => 'required|in:cash,card,transfer',
            'amount_paid' => 'required|numeric|min:0',
            'document_type' => 'required|in:NOTA_VENTA,BOLETA,FACTURA',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
        ]);

        $userId = $request->user()->id;
        $docType = $request->document_type;

        try {
            $sale = DB::transaction(function () use ($request, $userId, $docType) {
                $totalAmount = 0;
                $totalCost = 0;
                $totalIgv = 0;
                $itemsToCreate = [];

                // 1. Validar stock y calcular montos
                foreach ($request->items as $itemData) {
                    $product = Product::findOrFail($itemData['product_id']);
                    
                    if ($product->stock < $itemData['quantity']) {
                        throw new \Exception("Stock insuficiente para el producto: {$product->name}. Stock actual: {$product->stock}");
                    }

                    $qty = $itemData['quantity'];
                    $price = $product->price;
                    $cost = $product->cost_price;
                    $subtotal = $price * $qty;
                    $itemCost = $cost * $qty;
                    
                    // Calcular IGV (18% incluido)
                    $base = $subtotal / 1.18;
                    $igv = $subtotal - $base;

                    $totalAmount += $subtotal;
                    $totalCost += $itemCost;
                    $totalIgv += $igv;

                    $itemsToCreate[] = [
                        'product_id' => $product->id,
                        'quantity' => $qty,
                        'price' => $price,
                        'cost_price' => $cost,
                        'igv' => round($igv, 2),
                        'subtotal' => $subtotal,
                        'product' => $product // Guardar referencia temporal para restar stock
                    ];
                }

                if ($request->amount_paid < $totalAmount && $request->payment_method === 'cash') {
                    throw new \Exception("El monto pagado es menor que el total de la venta.");
                }

                // 2. Determinar Serie y Correlativo para SUNAT
                $serie = null;
                $correlativo = null;
                if ($docType !== 'NOTA_VENTA') {
                    $serie = $docType === 'FACTURA' ? 'F001' : 'B001';
                    $lastCorrelativo = Sale::where('document_type', $docType)
                        ->where('serie', $serie)
                        ->max('correlativo');
                    $correlativo = $lastCorrelativo ? $lastCorrelativo + 1 : 1;
                }

                $change = ($request->payment_method === 'cash') ? ($request->amount_paid - $totalAmount) : 0.00;

                // 3. Crear cabecera de Venta
                $sale = Sale::create([
                    'user_id' => $userId,
                    'customer_id' => $request->customer_id,
                    'total_amount' => $totalAmount,
                    'payment_method' => $request->payment_method,
                    'amount_paid' => $request->amount_paid,
                    'change_returned' => round($change, 2),
                    'status' => 'completed',
                    'document_type' => $docType,
                    'serie' => $serie,
                    'correlativo' => $correlativo,
                    'estado_sunat' => $docType === 'NOTA_VENTA' ? 'PENDIENTE' : 'PENDIENTE',
                    'total_igv' => round($totalIgv, 2),
                    'total_gravada' => round($totalAmount - $totalIgv, 2)
                ]);

                // 4. Crear detalles y actualizar stock
                foreach ($itemsToCreate as $item) {
                    $product = $item['product'];
                    
                    SaleItem::create([
                        'sale_id' => $sale->id,
                        'product_id' => $item['product_id'],
                        'quantity' => $item['quantity'],
                        'price' => $item['price'],
                        'cost_price' => $item['cost_price'],
                        'igv' => $item['igv'],
                        'subtotal' => $item['subtotal']
                    ]);

                    // Restar stock
                    $product->decrement('stock', $item['quantity']);
                }

                return $sale;
            });

            // 5. Si es Boleta o Factura, enviar a SUNAT usando Greenter
            $sunatResult = [];
            if ($docType !== 'NOTA_VENTA') {
                // Volver a cargar la venta con sus relaciones necesarias para SUNAT
                $saleWithRelations = Sale::with(['customer', 'items.product'])->find($sale->id);
                $sunatResult = $this->sunatService->sendInvoice($saleWithRelations);
            }

            return response()->json([
                'message' => 'Venta registrada con éxito.',
                'sale' => Sale::with(['user', 'customer', 'items.product'])->find($sale->id),
                'sunat' => $sunatResult
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al registrar la venta.',
                'error' => $e->getMessage()
            ], 422);
        }
    }

    /**
     * Anular una venta (restaura el stock).
     */
    public function cancel($id, Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Acceso denegado.'], 403);
        }

        try {
            DB::transaction(function () use ($id) {
                $sale = Sale::findOrFail($id);

                if ($sale->status === 'cancelled') {
                    throw new \Exception("Esta venta ya se encuentra anulada.");
                }

                // Devolver stock
                foreach ($sale->items as $item) {
                    Product::findOrFail($item->product_id)->increment('stock', $item->quantity);
                }

                $sale->status = 'cancelled';
                // Si ya fue enviado a SUNAT, en un entorno real se debería enviar una Nota de Crédito o una Comunicación de Baja.
                // Para efectos de esta demo, actualizaremos el estado interno.
                $sale->mensaje_sunat = $sale->mensaje_sunat . ' (DOCUMENTO ANULADO INTERNAMENTE)';
                $sale->save();
            });

            return response()->json([
                'message' => 'Venta anulada con éxito e inventario restablecido.'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al anular la venta.',
                'error' => $e->getMessage()
            ], 422);
        }
    }
}
