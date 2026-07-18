<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Iniciar sesión y retornar token de Sanctum.
     */
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Las credenciales proporcionadas son incorrectas.'],
            ]);
        }

        if ($user->status !== 'active') {
            return response()->json([
                'message' => 'Tu usuario se encuentra inactivo. Contacta al administrador.'
            ], 403);
        }

        // Crear token
        $token = $user->createToken('pos_auth_token')->plainTextToken;

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'status' => $user->status,
            ],
            'token' => $token
        ]);
    }

    /**
     * Cerrar sesión (revocar token).
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Sesión cerrada correctamente.'
        ]);
    }

    /**
     * Obtener el perfil del usuario autenticado.
     */
    public function profile(Request $request)
    {
        return response()->json($request->user());
    }
}
