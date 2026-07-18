<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Sale extends Model
{
    protected $fillable = [
        'user_id',
        'customer_id',
        'total_amount',
        'payment_method',
        'amount_paid',
        'change_returned',
        'status',
        'document_type',
        'serie',
        'correlativo',
        'xml_path',
        'cdr_path',
        'estado_sunat',
        'hash_sunat',
        'mensaje_sunat',
        'total_igv',
        'total_gravada'
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(SaleItem::class);
    }
}
