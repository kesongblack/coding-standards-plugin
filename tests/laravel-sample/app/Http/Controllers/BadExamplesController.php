<?php

namespace App\Http\Controllers;

use App\Models\User;

/**
 * BAD: Plural name (should be BadExampleController)
 * This file intentionally violates naming standards for testing
 */
class BadExamplesController extends Controller
{
    // BAD: Method name too generic
    public function getData()
    {
        return User::all();
    }

    // BAD: No type hints
    public function process($data)
    {
        return $data;
    }

    // BAD: God method - does too much
    public function handleEverything($request)
    {
        $user = User::find($request->id);
        $user->name = $request->name;
        $user->email = $request->email;
        $user->save();

        // Send email
        // Log activity
        // Update cache
        // Notify admin

        return $user;
    }
}
