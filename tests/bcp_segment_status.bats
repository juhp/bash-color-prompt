#!/usr/bin/env bats

load setup

@test "bcp_segment_status: no output on success (0)" {
    bcp_segment_status 0
    [[ "$_bcp_buffer" == "" ]]
}

@test "bcp_segment_status: shows exit code on failure" {
    bcp_segment_status 1
    [[ "$_bcp_buffer" == *"[1]"* ]]
}

@test "bcp_segment_status: shows code 127" {
    bcp_segment_status 127
    [[ "$_bcp_buffer" == *"[127]"* ]]
}

@test "bcp_segment_status: styled red" {
    bcp_segment_status 1
    [[ "$_bcp_buffer" == *"31m"* ]]
}
