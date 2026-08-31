<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\CallLog;
use Illuminate\Support\Facades\Auth;

class CallLogController extends Controller
{
    public function index()
    {
        $callLogs = Auth::user()->callLogs()->latest('call_time')->paginate(50);
        return response()->json($callLogs);
    }

    public function store(Request $request)
    {
        // 1000 કોલ્સ સેવ કરતી વખતે PHP સર્વર ક્રેસ ના થાય તે માટે
        set_time_limit(0);

        $request->validate([
            'calls' => 'required|array',
            'calls.*.contactName' => 'nullable|string|max:255',
            'calls.*.phoneNumber' => 'required|string|max:20',
            'calls.*.callType' => 'required|string|in:incoming,outgoing,missed,rejected',
            'calls.*.durationSec' => 'required|integer|min:0',
            'calls.*.callTimestamp' => 'required|integer',
        ]);

        $user = Auth::user();
        $insertedCount = 0;

        foreach ($request->calls as $callData) {
            $user->callLogs()->updateOrCreate(
                [
                    'caller_number' => $callData['phoneNumber'],
                    'call_timestamp' => $callData['callTimestamp'], // અહીં BIGINT આંકડો જ જશે
                ],
                [
                    'caller_name' => $callData['contactName'] ?? null,
                    'call_type' => $callData['callType'],
                    'call_duration' => $callData['durationSec'],
                    'call_time' => date('Y-m-d H:i:s', intval($callData['callTimestamp'] / 1000)), // અહીં તારીખ જશે
                ]
            );
            $insertedCount++;
        }

        return response()->json(['message' => "$insertedCount call logs synced successfully"], 201);
    }

    public function show($id)
    {
        $callLog = Auth::user()->callLogs()->findOrFail($id);
        return response()->json($callLog);
    }

    public function update(Request $request, $id)
    {
        $callLog = Auth::user()->callLogs()->findOrFail($id);

        $request->validate([
            'caller_name' => 'nullable|string|max:255',
            'caller_number' => 'sometimes|required|string|max:20',
            'call_type' => 'sometimes|required|string|in:incoming,outgoing,missed,rejected',
            'call_duration' => 'sometimes|required|integer|min:0',
            'call_time' => 'sometimes|required|date',
        ]);

        $callLog->update($request->all());

        return response()->json($callLog);
    }

    public function destroy($id)
    {
        $callLog = Auth::user()->callLogs()->findOrFail($id);
        $callLog->delete();

        return response()->json(['message' => 'Call log deleted successfully']);
    }
}
