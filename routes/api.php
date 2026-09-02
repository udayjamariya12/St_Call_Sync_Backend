<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\CallLogController;
use App\Http\Controllers\Api\CallHistorySyncController;

// પબ્લિક રૂટ (કોઈ પણ એક્સેસ કરી શકે)
Route::post('/login', [AuthController::class, 'login']);

// સિક્યોર રૂટ્સ (જેના માટે Token ની જરૂર પડશે)
Route::middleware('auth:sanctum')->group(function () {
    
    // લોગઆઉટ
    Route::post('/logout', [AuthController::class, 'logout']);

    // કોલ લોગ્સ અપલોડ કરવા
    Route::post('/calls', [CallLogController::class, 'store']);
    Route::get('/call-history-sync/options', [CallHistorySyncController::class, 'getSyncOptions']);
    Route::post('/calls/sync-status', [CallHistorySyncController::class, 'syncStatus']);
    Route::post('/calls/sync-complete', [CallHistorySyncController::class, 'syncComplete']);

    // યુઝર મેનેજમેન્ટ (એડમિન માટે)
    Route::get('/users', [UserController::class, 'index']);
    Route::post('/users', [UserController::class, 'store']);
    Route::put('/users/{id}', [UserController::class, 'update']);
    Route::delete('/users/{id}', [UserController::class, 'destroy']);
    Route::post('/users/{id}/reset-password', [UserController::class, 'resetPassword']);
        // એડમિન માટેની નવી API
    Route::get('/admin/dashboard-stats', [AdminController::class, 'dashboardStats']);
    Route::get('/admin/users', [AdminController::class, 'getAllUsers']);
    Route::get('/admin/calls', [AdminController::class, 'getAllCalls']);

    // Password Resets
    Route::get('/admin/reset-requests', [AdminController::class, 'getResetRequests']);
    Route::post('/admin/reset-requests/{id}/approve', [AdminController::class, 'approveResetRequest']);
    Route::post('/admin/reset-requests/{id}/dismiss', [AdminController::class, 'dismissResetRequest']);

    // User Requests (Approvals)
    Route::get('/admin/user-requests', [AdminController::class, 'getUserRequests']);
    Route::put('/admin/user-requests/{id}', [AdminController::class, 'updateUserRequest']);

    // Health Alerts
    Route::get('/admin/health-alerts', [AdminController::class, 'getHealthAlerts']);

});

Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
