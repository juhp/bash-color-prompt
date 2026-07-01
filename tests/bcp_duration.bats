#!/usr/bin/env bats

load setup

@test "bcp_duration: no output when _bcp_last_duration_s is empty" {
    _bcp_last_duration_s=""
    bcp_duration
    [[ "$_bcp_buffer" == "" ]]
}

@test "bcp_duration: no output below default threshold (2s)" {
    _bcp_timer_file="/tmp/bcp-test-$$"
    _bcp_last_duration_s=1
    bcp_duration
    [[ "$_bcp_buffer" == "" ]]
}

@test "bcp_duration: shows seconds" {
    _bcp_timer_file="/tmp/bcp-test-$$"
    _bcp_last_duration_s=5
    bcp_duration
    [[ "$_bcp_buffer" == *"5s"* ]]
}

@test "bcp_duration: shows minutes and seconds" {
    _bcp_timer_file="/tmp/bcp-test-$$"
    _bcp_last_duration_s=125
    bcp_duration
    [[ "$_bcp_buffer" == *"2m 5s"* ]]
}

@test "bcp_duration: shows hours and minutes" {
    _bcp_timer_file="/tmp/bcp-test-$$"
    _bcp_last_duration_s=3661
    bcp_duration
    [[ "$_bcp_buffer" == *"1h 1m"* ]]
}

@test "bcp_duration: shows days, hours, and minutes" {
    _bcp_timer_file="/tmp/bcp-test-$$"
    _bcp_last_duration_s=$(( 2*86400 + 3*3600 + 15*60 ))
    bcp_duration
    [[ "$_bcp_buffer" == *"2d 3h 15m"* ]]
}

@test "bcp_duration: custom threshold" {
    _bcp_timer_file="/tmp/bcp-test-$$"
    _bcp_last_duration_s=3
    bcp_duration 5
    [[ "$_bcp_buffer" == "" ]]
}

@test "bcp_duration: at custom threshold shows output" {
    _bcp_timer_file="/tmp/bcp-test-$$"
    _bcp_last_duration_s=5
    bcp_duration 5
    [[ "$_bcp_buffer" == *"5s"* ]]
}

@test "bcp_duration: default prefix is 'took '" {
    _bcp_timer_file="/tmp/bcp-test-$$"
    _bcp_last_duration_s=10
    bcp_duration
    [[ "$_bcp_buffer" == *"took 10s"* ]]
}

@test "bcp_duration: custom prefix" {
    _bcp_timer_file="/tmp/bcp-test-$$"
    _bcp_last_duration_s=10
    bcp_duration 2 "yellow" "elapsed: "
    [[ "$_bcp_buffer" == *"elapsed: 10s"* ]]
}

@test "bcp_duration: custom suffix" {
    _bcp_timer_file="/tmp/bcp-test-$$"
    _bcp_last_duration_s=10
    bcp_duration 2 "yellow" "took " "!"
    [[ "$_bcp_buffer" == *"took 10s!"* ]]
}

@test "bcp_duration: clears _bcp_last_duration_s after display" {
    _bcp_timer_file="/tmp/bcp-test-$$"
    _bcp_last_duration_s=10
    bcp_duration
    [[ "$_bcp_last_duration_s" == "" ]]
}

@test "bcp_duration: exactly 60s shows 1m 0s" {
    _bcp_timer_file="/tmp/bcp-test-$$"
    _bcp_last_duration_s=60
    bcp_duration
    [[ "$_bcp_buffer" == *"1m 0s"* ]]
}

@test "bcp_duration: exactly 3600s shows 1h 0m" {
    _bcp_timer_file="/tmp/bcp-test-$$"
    _bcp_last_duration_s=3600
    bcp_duration
    [[ "$_bcp_buffer" == *"1h 0m"* ]]
}
