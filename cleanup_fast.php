
\ = DB::table('call_logs')
    ->select(DB::raw('MIN(id) as min_id'))
    ->groupBy('user_id', 'caller_number', 'call_timestamp')
    ->pluck('min_id');

DB::table('call_logs')->whereNotIn('id', \)->delete();
echo 'Deleted duplicate rows. Remaining unique rows: ' . DB::table('call_logs')->count() . '\n';

