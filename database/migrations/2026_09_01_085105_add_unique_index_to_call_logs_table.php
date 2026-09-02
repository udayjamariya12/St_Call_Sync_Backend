<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up()
    {
        DB::statement('
            DELETE t1 FROM call_logs t1
            INNER JOIN call_logs t2 
            WHERE 
                t1.id < t2.id AND 
                t1.user_id = t2.user_id AND 
                t1.caller_number = t2.caller_number AND 
                t1.call_timestamp = t2.call_timestamp
        ');

        Schema::table('call_logs', function (Blueprint $table) {
            $table->unique(['user_id', 'caller_number', 'call_timestamp'], 'call_logs_unique_call');
        });
    }

    public function down()
    {
        Schema::table('call_logs', function (Blueprint $table) {
            $table->dropUnique('call_logs_unique_call');
        });
    }
};
