<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    public function index()
    {
        $users = User::all(); 
        return response()->json($users);
    }

    public function store(Request $request)
    {
        $request->validate([
            'mobile_number' => 'required|unique:users,mobile_number',
            'name' => 'required|string',
            'password' => 'required|min:6',
            'role' => 'required|in:admin,user',
            'status' => 'required|in:active,inactive'
        ]);

        $user = User::create([
            'password' => Hash::make($request->password),
            'mobile_number' => $request->mobile_number,
            'name' => $request->name,
            'designation' => $request->designation,
            'employee_id' => $request->employee_id,
            'department' => $request->department,
            'reporting_manager' => $request->reporting_manager,
            'joining_date' => $request->joining_date,
            'description' => $request->description,
            'role' => $request->role,
            'status' => $request->status,
        ]);

        return response()->json(['message' => 'User created successfully', 'user' => $user], 201);
    }

    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);
        
        $data = $request->except(['password']); 
        
        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
        }

        $user->update($data);

        return response()->json(['message' => 'User updated successfully', 'user' => $user]);
    }

    public function destroy($id)
    {
        $user = User::find($id);
        if (!$user) {
            return response()->json(['message' => 'User not found'], 404);
        }
        $user->delete();
        return response()->json(['message' => 'Success']);
    }

    public function resetPassword(Request $request, $id)
    {
        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'password' => 'required|min:6'
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        $user = User::find($id);
        if (!$user) {
            return response()->json(['message' => 'User not found'], 404);
        }

        $user->update(['password' => Hash::make($request->password)]);
        return response()->json(['message' => 'Success']);
    }
}
