<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    public function index(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Acceso denegado.'], 403);
        }

        return response()->json(User::all());
    }

    public function store(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Acceso denegado.'], 403);
        }

        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
            'role' => 'required|in:admin,vendedor',
            'status' => 'required|in:active,inactive',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => $request->role,
            'status' => $request->status,
        ]);

        return response()->json([
            'message' => 'Usuario creado con éxito.',
            'user' => $user
        ], 201);
    }

    public function update(Request $request, User $user)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Acceso denegado.'], 403);
        }

        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,' . $user->id,
            'password' => 'nullable|string|min:6',
            'role' => 'required|in:admin,vendedor',
            'status' => 'required|in:active,inactive',
        ]);

        $user->name = $request->name;
        $user->email = $request->email;
        $user->role = $request->role;
        $user->status = $request->status;

        if ($request->filled('password')) {
            $user->password = Hash::make($request->password);
        }

        $user->save();

        return response()->json([
            'message' => 'Usuario actualizado con éxito.',
            'user' => $user
        ]);
    }

    public function destroy(Request $request, User $user)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Acceso denegado.'], 403);
        }

        // Evitar que el administrador se elimine a sí mismo
        if ($request->user()->id === $user->id) {
            return response()->json(['message' => 'No puedes eliminar tu propio usuario.'], 422);
        }

        $user->delete();

        return response()->json([
            'message' => 'Usuario eliminado con éxito.'
        ]);
    }
}
