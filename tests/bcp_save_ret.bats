#!/usr/bin/env bats

load setup

@test "_bcp_save_ret: captures success exit code" {
    true
    _bcp_save_ret
    [[ "$_bcp_saved_ret" == "0" ]]
}

@test "_bcp_save_ret: reads and removes timer file" {
    _bcp_timer_file="$BATS_TEST_TMPDIR/timer"
    printf '%s\n' "$((EPOCHSECONDS - 10))" > "$_bcp_timer_file"
    _bcp_save_ret
    [[ "$_bcp_last_duration_s" -ge 9 ]]
    [[ ! -f "$_bcp_timer_file" ]]
}

@test "_bcp_save_ret: empty duration when no timer file" {
    _bcp_timer_file="$BATS_TEST_TMPDIR/nonexistent"
    _bcp_save_ret
    [[ "$_bcp_last_duration_s" == "" ]]
}
