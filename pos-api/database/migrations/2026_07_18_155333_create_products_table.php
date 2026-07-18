<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->text('description')->nullable();
            $table->string('barcode')->unique()->nullable();
            $table->decimal('price', 10, 2);
            $table->decimal('cost_price', 10, 2)->default(0.00);
            $table->integer('stock')->default(0);
            $table->integer('alert_stock')->default(5);
            $table->enum('status', ['active', 'inactive'])->default('active');
            $table->string('image_url')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
