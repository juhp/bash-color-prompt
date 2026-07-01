#!/usr/bin/env bats

load setup

# EUID is readonly in bash, so we can't test the root/non-root color
# branches directly; we just verify the layout structure.

@test "_bcp_default_layout: contains user@host" {
    _bcp_buffer=""
    _bcp_default_layout
    [[ "$_bcp_buffer" == *'\u@\h'* ]]
}

@test "_bcp_default_layout: contains working directory" {
    _bcp_buffer=""
    _bcp_default_layout
    [[ "$_bcp_buffer" == *'\w'* ]]
}

@test "_bcp_default_layout: ends with dollar-space" {
    _bcp_buffer=""
    _bcp_default_layout
    # bcp_append "\$ " — in double quotes \$ is literal $
    [[ "$_bcp_buffer" == *'$ '* ]]
}

@test "_bcp_default_layout: uses bold styling" {
    _bcp_buffer=""
    _bcp_default_layout
    [[ "$_bcp_buffer" == *";1m"* ]]
}
