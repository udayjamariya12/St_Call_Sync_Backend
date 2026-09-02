<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CallHistorySyncController extends Controller
{
    public function getSyncOptions(Request $request)
    {
        $user = Auth::user();
        
        $lastCall = $user->callLogs()->orderBy('call_timestamp', 'desc')->first();
        $lastSyncTimestamp = null;
        if ($lastCall && $lastCall->call_timestamp) {
            $lastSyncTimestamp = gmdate("Y-m-d\TH:i:s.000\Z", intval($lastCall->call_timestamp / 1000));
        }

        if (!$user->has_completed_initial_sync) {
            return response()->json([
                'hasSyncedBefore' => false,
                'options' => [
                    [ 'id' => 'none', 'label' => "Don't sync past calls" ],
                    [ 'id' => '1_month', 'label' => 'Last 1 month' ],
                    [ 'id' => '3_months', 'label' => 'Last 3 months' ],
                    [ 'id' => 'all', 'label' => 'All available on device' ]
                ],
                'lastSyncTimestamp' => null
            ]);
        } else {
            return response()->json([
                'hasSyncedBefore' => true,
                'options' => [
                    [ 'id' => 'none', 'label' => "Don't sync past calls" ],
                    [ 'id' => 'new_only', 'label' => 'Sync new calls only' ]
                ],
                'lastSyncTimestamp' => $lastSyncTimestamp
            ]);
        }
    }

    public function syncComplete(Request $request)
    {
        $user = Auth::user();
        $user->has_completed_initial_sync = true;
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Initial sync marked as complete'
        ]);
    }

    public function syncStatus(Request $request)
    {
        $request->validate([
            'device_call_ids' => 'required|array',
            'device_call_ids.*' => 'required|string',
        ]);

        $user = Auth::user();
        
        $deviceCallIds = array_unique($request->device_call_ids);
        $deviceCallCount = count($deviceCallIds);
        $syncedCallCount = 0;

        // Process in chunks to avoid memory/SQL limits for large arrays
        $chunks = array_chunk($deviceCallIds, 500);

        foreach ($chunks as $chunk) {
            $syncedInChunk = $user->callLogs()
                ->whereIn('call_timestamp', $chunk)
                ->count();
            $syncedCallCount += $syncedInChunk;
        }
        
        $unsyncedCallCount = max(0, $deviceCallCount - $syncedCallCount);
        
        return response()->json([
            'unsynced_call_count' => $unsyncedCallCount
        ]);
    }
}
