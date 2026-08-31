<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CallLog extends Model
{
    use HasFactory;

    protected $casts = ['call_time' => 'datetime'];

    protected $fillable = [
        'user_id',
        'caller_name',
        'caller_number',
        'call_type',
        'call_duration',
        'call_time',
        'call_timestamp',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

