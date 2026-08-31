<?php
require __DIR__."/vendor/autoload.php";
$app = require_once __DIR__."/bootstrap/app.php";
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$requests = \App\Models\PasswordResetRequest::with("user")->orderBy("created_at", "desc")->first();
echo json_encode($requests);

