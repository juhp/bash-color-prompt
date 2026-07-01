#!/usr/bin/env bats

load setup

@test "_bcp_append_raw: plain text without ansi" {
    _bcp_append_raw "hello"
    [[ "$_bcp_buffer" == "hello" ]]
}

@test "_bcp_append_raw: text with ansi codes" {
    _bcp_append_raw "hello" "32;1"
    [[ "$_bcp_buffer" == '\[\e[32;1m\]hello\[\e[0m\]' ]]
}

@test "_bcp_append_raw: trailing semicolon is stripped" {
    _bcp_append_raw "hello" "32;1;"
    [[ "$_bcp_buffer" == '\[\e[32;1m\]hello\[\e[0m\]' ]]
}

@test "_bcp_append_raw: custom reset code" {
    _bcp_append_raw "hello" "31" "39"
    [[ "$_bcp_buffer" == '\[\e[31m\]hello\[\e[39m\]' ]]
}

@test "_bcp_append_raw: empty ansi string means plain" {
    _bcp_append_raw "hello" ""
    [[ "$_bcp_buffer" == "hello" ]]
}
