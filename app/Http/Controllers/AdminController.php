<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use App\Models\CallLog;

class AdminController extends Controller
{
    // ડેશબોર્ડના આંકડા માટેની API
    public function dashboardStats()
    {
        $totalUsers = User::where('role', '!=', 'admin')->count();
        $totalCalls = CallLog::count();
        $todayCalls = CallLog::whereDate('call_time', date('Y-m-d'))->count();

        return response()->json([
            'status' => 'success',
            'data' => [
                'total_users' => $totalUsers,
                'total_calls' => $totalCalls,
                'today_calls' => $todayCalls,
            ]
        ]);
    }

    // બધા યુઝર્સનું લિસ્ટ જોવા માટેની API
    public function getAllUsers()
    {
        $users = User::where('role', '!=', 'admin')->orderBy('created_at', 'desc')->get();
        return response()->json([
            'status' => 'success',
            'data' => $users
        ]);
    }

    public function getAllCalls(Request $request)
    {
        $query = CallLog::orderBy('call_time', 'desc');
        
        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        $perPage = $request->input('per_page', 50);
        $calls = $query->paginate($perPage);
        
        return response()->json([
            'status' => 'success',
            'data' => $calls
        ]);
    }

    public function getResetRequests()
    {
        $requests = \App\Models\PasswordResetRequest::with('user')->where('status', 'pending')->orderBy('created_at', 'desc')->get();
        return response()->json([
            'status' => 'success',
            'data' => $requests
        ]);
    }

    public function approveResetRequest($id)
    {
        $request = \App\Models\PasswordResetRequest::find($id);
        if ($request) {
            $request->status = 'approved';
            $request->save();
            return response()->json(['status' => 'success', 'message' => 'Approved']);
        }
        return response()->json(['status' => 'error', 'message' => 'Not found'], 404);
    }

    public function dismissResetRequest($id)
    {
        $request = \App\Models\PasswordResetRequest::find($id);
        if ($request) {
            $request->status = 'dismissed';
            $request->save();
            return response()->json(['status' => 'success', 'message' => 'Dismissed']);
        }
        return response()->json(['status' => 'error', 'message' => 'Not found'], 404);
    }

    public function getUserRequests()
    {
        $requests = \App\Models\UserRequest::orderBy('created_at', 'desc')->get();
        return response()->json([
            'status' => 'success',
            'data' => $requests
        ]);
    }

    public function updateUserRequest(Request $request, $id)
    {
        $userRequest = \App\Models\UserRequest::find($id);
        if ($userRequest) {
            $userRequest->status = $request->input('status', $userRequest->status);
            $userRequest->save();
            return response()->json(['status' => 'success', 'data' => $userRequest]);
        }
        return response()->json(['status' => 'error', 'message' => 'Not found'], 404);
    }

    public function getHealthAlerts()
    {
        $alerts = \App\Models\HealthAlert::orderBy('created_at', 'desc')->get();
        return response()->json([
            'status' => 'success',
            'data' => $alerts
        ]);
    }
}









