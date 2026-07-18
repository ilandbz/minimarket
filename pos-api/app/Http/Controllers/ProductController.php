<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::with('category');

        if ($request->has('search')) {
            $search = $request->query('search');
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('barcode', '=', $search);
            });
        }

        if ($request->has('category_id')) {
            $query->where('category_id', $request->query('category_id'));
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Acceso denegado.'], 403);
        }

        $request->validate([
            'category_id' => 'required|exists:categories,id',
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'barcode' => 'nullable|string|unique:products,barcode',
            'price' => 'required|numeric|min:0',
            'cost_price' => 'required|numeric|min:0',
            'stock' => 'required|integer|min:0',
            'alert_stock' => 'required|integer|min:0',
            'status' => 'required|in:active,inactive',
            'image_url' => 'nullable|string',
        ]);

        $product = Product::create($request->all());

        return response()->json([
            'message' => 'Producto creado con éxito.',
            'product' => $product->load('category')
        ], 201);
    }

    public function show(Product $product)
    {
        return response()->json($product->load('category'));
    }

    public function update(Request $request, Product $product)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Acceso denegado.'], 403);
        }

        $request->validate([
            'category_id' => 'required|exists:categories,id',
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'barcode' => 'nullable|string|unique:products,barcode,' . $product->id,
            'price' => 'required|numeric|min:0',
            'cost_price' => 'required|numeric|min:0',
            'stock' => 'required|integer|min:0',
            'alert_stock' => 'required|integer|min:0',
            'status' => 'required|in:active,inactive',
            'image_url' => 'nullable|string',
        ]);

        $product->update($request->all());

        return response()->json([
            'message' => 'Producto actualizado con éxito.',
            'product' => $product->load('category')
        ]);
    }

    public function destroy(Product $product)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Acceso denegado.'], 403);
        }

        $product->delete();

        return response()->json([
            'message' => 'Producto eliminado con éxito.'
        ]);
    }

    /**
     * Buscar producto por código de barras.
     */
    public function searchByBarcode($barcode)
    {
        $product = Product::where('barcode', $barcode)
            ->where('status', 'active')
            ->first();

        if (!$product) {
            return response()->json(['message' => 'Producto no encontrado.'], 404);
        }

        return response()->json($product);
    }
}
