#!/usr/bin/env bats

load setup

@test "bcp_shlvl: no output at SHLVL=1" {
    SHLVL=1
    bcp_shlvl
    [[ "$_bcp_buffer" == "" ]]
}

@test "bcp_shlvl: shows level at SHLVL=2" {
    SHLVL=2
    bcp_shlvl
    [[ "$_bcp_buffer" == *"2"* ]]
}

@test "bcp_shlvl: shows level at SHLVL=5" {
    SHLVL=5
    bcp_shlvl
    [[ "$_bcp_buffer" == *"5"* ]]
}

@test "bcp_shlvl: default color is magenta" {
    SHLVL=2
    bcp_shlvl
    [[ "$_bcp_buffer" == *"35m"* ]]
}

@test "bcp_shlvl: custom color" {
    SHLVL=2
    bcp_shlvl "cyan"
    [[ "$_bcp_buffer" == *"36m"* ]]
}

@test "bcp_shlvl: custom prefix" {
    SHLVL=3
    bcp_shlvl "magenta" "^"
    [[ "$_bcp_buffer" == *"^3"* ]]
}

@test "bcp_shlvl: no output when SHLVL unset" {
    unset SHLVL
    bcp_shlvl
    [[ "$_bcp_buffer" == "" ]]
}
