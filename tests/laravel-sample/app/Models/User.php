<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * GOOD: Singular PascalCase model name
 */
class User extends Model
{
    protected $fillable = [
        'name',
        'email',
        'password',
    ];

    protected $hidden = [
        'password',
    ];
}
