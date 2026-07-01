#!/usr/bin/env bats

load setup

@test "_bcp_build_prompt: sets PS1 with default layout" {
    _bcp_build_prompt
    [[ -n "$PS1" ]]
    [[ "$PS1" == *'\u@\h'* ]]
}

@test "_bcp_build_prompt: uses custom bcp_layout" {
    bcp_layout() {
        bcp_append "test$ "
    }
    _bcp_build_prompt
    [[ "$PS1" == "test$ " ]]
}

@test "_bcp_build_prompt: passes exit code to bcp_layout" {
    bcp_layout() {
        bcp_append "exit=$1 "
    }
    _bcp_saved_ret=42
    _bcp_build_prompt
    [[ "$PS1" == "exit=42 " ]]
}

@test "_bcp_build_prompt: resets buffer each call" {
    bcp_layout() {
        bcp_append "prompt"
    }
    _bcp_build_prompt
    _bcp_build_prompt
    [[ "$PS1" == "prompt" ]]
}
