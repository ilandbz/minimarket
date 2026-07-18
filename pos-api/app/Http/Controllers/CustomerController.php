<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    public function index(Request $request)
    {
        $query = Customer::query();

        if ($request->has('search')) {
            $search = $request->query('search');
            $query->where('name', 'like', "%{$search}%")
                  ->orWhere('document_number', 'like', "%{$search}%");
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'document_type' => 'required|in:DNI,RUC,VARIOS',
            'document_number' => 'nullable|string|unique:customers,document_number',
            'phone' => 'nullable|string',
            'email' => 'nullable|email',
            'address' => 'nullable|string',
        ]);

        $customer = Customer::create($request->all());

        return response()->json([
            'message' => 'Cliente registrado con éxito.',
            'customer' => $customer
        ], 201);
    }

    public function show(Customer $customer)
    {
        return response()->json($customer);
    }

    public function update(Request $request, Customer $customer)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'document_type' => 'required|in:DNI,RUC,VARIOS',
            'document_number' => 'nullable|string|unique:customers,document_number,' . $customer->id,
            'phone' => 'nullable|string',
            'email' => 'nullable|email',
            'address' => 'nullable|string',
        ]);

        $customer->update($request->all());

        return response()->json([
            'message' => 'Cliente actualizado con éxito.',
            'customer' => $customer
        ]);
    }

    /**
     * Buscar cliente por número de documento.
     */
    public function searchByDocument($docNumber)
    {
        $customer = Customer::where('document_number', $docNumber)->first();

        if (!$customer) {
            return response()->json(['message' => 'Cliente no encontrado.'], 404);
        }

        return response()->json($customer);
    }
}
