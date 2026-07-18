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
        Schema::create('sales', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('customer_id')->nullable()->constrained()->nullOnDelete();
            $table->decimal('total_amount', 10, 2);
            $table->enum('payment_method', ['cash', 'card', 'transfer'])->default('cash');
            $table->decimal('amount_paid', 10, 2);
            $table->decimal('change_returned', 10, 2)->default(0.00);
            $table->enum('status', ['completed', 'cancelled'])->default('completed');
            
            // Campos de Facturación Electrónica (SUNAT)
            $table->enum('document_type', ['NOTA_VENTA', 'BOLETA', 'FACTURA'])->default('NOTA_VENTA');
            $table->string('serie', 4)->nullable();
            $table->integer('correlativo')->nullable();
            $table->string('xml_path')->nullable();
            $table->string('cdr_path')->nullable();
            $table->enum('estado_sunat', ['PENDIENTE', 'ACEPTADO', 'RECHAZADO', 'ERROR'])->default('PENDIENTE');
            $table->string('hash_sunat')->nullable();
            $table->text('mensaje_sunat')->nullable();
            $table->decimal('total_igv', 10, 2)->default(0.00);
            $table->decimal('total_gravada', 10, 2)->default(0.00);

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('sales');
    }
};
