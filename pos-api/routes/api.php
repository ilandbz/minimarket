<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\CustomerController;
use App\Http\Controllers\SaleController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\UserController;

// Rutas Públicas
Route::post('/login', [AuthController::class, 'login']);

// Rutas Protegidas por Sanctum
Route::middleware('auth:sanctum')->group(function () {
    // Autenticación
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'profile']);

    // Categorías
    Route::apiResource('categories', CategoryController::class);

    // Productos
    Route::get('products/barcode/{barcode}', [ProductController::class, 'searchByBarcode']);
    Route::apiResource('products', ProductController::class);

    // Clientes
    Route::get('customers/document/{docNumber}', [CustomerController::class, 'searchByDocument']);
    Route::apiResource('customers', CustomerController::class);

    // Ventas
    Route::get('sales', [SaleController::class, 'index']);
    Route::post('sales', [SaleController::class, 'store']);
    Route::get('sales/{id}', [SaleController::class, 'show']);
    Route::post('sales/{id}/cancel', [SaleController::class, 'cancel']);

    // Dashboard
    Route::get('dashboard', [DashboardController::class, 'index']);

    // Usuarios (Gestión)
    Route::apiResource('users', UserController::class);
});
