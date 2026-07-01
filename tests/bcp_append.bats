#!/usr/bin/env bats

load setup

@test "bcp_append: plain text without style" {
    bcp_append "hello"
    [[ "$_bcp_buffer" == "hello" ]]
}

@test "bcp_append: multiple plain appends concatenate" {
    bcp_append "hello"
    bcp_append " world"
    [[ "$_bcp_buffer" == "hello world" ]]
}

@test "bcp_append: text with color" {
    bcp_append "hello" "red"
    [[ "$_bcp_buffer" == '\[\e[31m\]hello\[\e[0m\]' ]]
}

@test "bcp_append: text with color;bold" {
    bcp_append "hello" "green;bold"
    [[ "$_bcp_buffer" == '\[\e[32;1m\]hello\[\e[0m\]' ]]
}

@test "bcp_append: custom reset code" {
    bcp_append "hello" "red" "39"
    [[ "$_bcp_buffer" == '\[\e[31m\]hello\[\e[39m\]' ]]
}

@test "bcp_append: empty reset string suppresses reset" {
    bcp_append "hello" "red" ""
    [[ "$_bcp_buffer" == '\[\e[31m\]hello\[\e[m\]' ]]
}

@test "bcp_append: numeric ANSI code" {
    bcp_append "hello" "38;5;208"
    [[ "$_bcp_buffer" == '\[\e[38;5;208m\]hello\[\e[0m\]' ]]
}

@test "bcp_append: mixed plain and styled" {
    bcp_append "user" "green;bold"
    bcp_append ":"
    bcp_append "/home" "blue"
    [[ "$_bcp_buffer" == '\[\e[32;1m\]user\[\e[0m\]:\[\e[34m\]/home\[\e[0m\]' ]]
}
