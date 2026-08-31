<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('username')->unique()->nullable()->after('name');
            $table->string('employee_id')->nullable()->after('designation');
            $table->string('reporting_manager')->nullable()->after('department');
            $table->date('joining_date')->nullable()->after('reporting_manager');
            $table->text('description')->nullable()->after('joining_date');
            $table->string('status')->default('active')->after('role');
        });
    }

    public function down()
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'username',
                'employee_id',
                'reporting_manager',
                'joining_date',
                'description',
                'status'
            ]);
        });
    }
};
