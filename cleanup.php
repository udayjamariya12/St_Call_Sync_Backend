
DB::statement('
    DELETE t1 FROM call_logs t1
    INNER JOIN call_logs t2 
    WHERE 
        t1.id < t2.id AND 
        t1.user_id = t2.user_id AND 
        t1.caller_number = t2.caller_number AND 
        t1.call_timestamp = t2.call_timestamp
');
echo 'Cleanup done.';

