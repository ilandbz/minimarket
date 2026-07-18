<?php

namespace App\Http\Controllers;

use App\Models\Category;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    public function index()
    {
        return response()->json(Category::withCount('products')->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|unique:categories,name|max:255',
            'description' => 'nullable|string',
        ]);

        $category = Category::create($request->only('name', 'description'));

        return response()->json([
            'message' => 'Categoría creada con éxito.',
            'category' => $category
        ], 201);
    }

    public function show(Category $category)
    {
        return response()->json($category);
    }

    public function update(Request $request, Category $category)
    {
        $request->validate([
            'name' => 'required|string|max:255|unique:categories,name,' . $category->id,
            'description' => 'nullable|string',
        ]);

        $category->update($request->only('name', 'description'));

        return response()->json([
            'message' => 'Categoría actualizada con éxito.',
            'category' => $category
        ]);
    }

    public function destroy(Category $category)
    {
        // Solo administradores pueden eliminar
        if (request()->user()->role !== 'admin') {
            return response()->json(['message' => 'Acceso denegado. Se requieren permisos de administrador.'], 403);
        }

        if ($category->products()->count() > 0) {
            return response()->json([
                'message' => 'No se puede eliminar la categoría porque contiene productos asociados.'
            ], 422);
        }

        $category->delete();

        return response()->json([
            'message' => 'Categoría eliminada con éxito.'
        ]);
    }
}
