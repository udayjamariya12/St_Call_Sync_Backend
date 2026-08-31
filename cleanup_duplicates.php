<?php
require __DIR__."/vendor/autoload.php";
$app = require_once __DIR__."/bootstrap/app.php";
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

try {
    $minIds = DB::table("call_logs")
        ->select(DB::raw("MIN(id) as min_id"))
        ->groupBy("user_id", "caller_number", "call_timestamp")
        ->pluck("min_id")
        ->toArray();

    $deleted = DB::table("call_logs")->whereNotIn("id", $minIds)->delete();
    
    echo "Successfully deleted $deleted duplicate rows.\n";
    echo "Remaining unique rows: " . DB::table("call_logs")->count() . "\n";
} catch (\Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
