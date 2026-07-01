#!/usr/bin/env bats

load setup

@test "_bcp_parse_tokens: single color name" {
    _bcp_parse_tokens "red"
    [[ "$_bcp_parsed" == "31;" ]]
}

@test "_bcp_parse_tokens: single style name" {
    _bcp_parse_tokens "bold"
    [[ "$_bcp_parsed" == "1;" ]]
}

@test "_bcp_parse_tokens: combined color;style" {
    _bcp_parse_tokens "green;bold"
    [[ "$_bcp_parsed" == "32;1;" ]]
}

@test "_bcp_parse_tokens: all foreground colors" {
    for pair in black:30 red:31 green:32 yellow:33 blue:34 magenta:35 cyan:36 white:37 default:39; do
        local name="${pair%%:*}" code="${pair##*:}"
        _bcp_parse_tokens "$name"
        [[ "$_bcp_parsed" == "${code};" ]]
    done
}

@test "_bcp_parse_tokens: all background colors" {
    for pair in bgblack:40 bgred:41 bggreen:42 bgyellow:43 bgblue:44 bgmagenta:45 bgcyan:46 bgwhite:47 bgdefault:49; do
        local name="${pair%%:*}" code="${pair##*:}"
        _bcp_parse_tokens "$name"
        [[ "$_bcp_parsed" == "${code};" ]]
    done
}

@test "_bcp_parse_tokens: all style names" {
    for pair in bold:1 dim:2 italic:3 underline:4 blink:5 rapid:6 reverse:7 hidden:8; do
        local name="${pair%%:*}" code="${pair##*:}"
        _bcp_parse_tokens "$name"
        [[ "$_bcp_parsed" == "${code};" ]]
    done
}

@test "_bcp_parse_tokens: numeric code passes through" {
    _bcp_parse_tokens "38;5;208"
    [[ "$_bcp_parsed" == "38;5;208;" ]]
}

@test "_bcp_parse_tokens: mixed named and numeric" {
    _bcp_parse_tokens "bold;38;5;208"
    [[ "$_bcp_parsed" == "1;38;5;208;" ]]
}

@test "_bcp_parse_tokens: unknown token passes through" {
    _bcp_parse_tokens "nonexistent"
    [[ "$_bcp_parsed" == "nonexistent;" ]]
}

@test "_bcp_parse_tokens: multiple styles" {
    _bcp_parse_tokens "red;bold;underline"
    [[ "$_bcp_parsed" == "31;1;4;" ]]
}
