<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'mobileNumber' => 'required|string',
            'password' => 'required|string',
        ]);

        $user = User::where('mobile_number', $request->mobileNumber)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'user' => $user,
            'token' => $token
        ], 200);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out successfully']);
    }

    public function forgotPassword(Request $request)
    {
        $request->validate([
            'mobileNumber' => 'required|string',
        ]);

        $user = User::where('mobile_number', $request->mobileNumber)->first();

        if (!$user) {
            return response()->json(['message' => 'User not found.'], 404);
        }

        // Create reset request
        DB::table('password_reset_requests')->insert([
            'user_id' => $user->id,
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['message' => 'Password reset request submitted successfully.']);
    }
}

