#!/usr/bin/env bats

load setup

@test "bcp_static: sets PS1 with default layout" {
    bcp_static
    [[ -n "$PS1" ]]
}

@test "bcp_static: PS1 contains user@host and directory prompts" {
    bcp_static
    [[ "$PS1" == *'\u@\h'* ]]
    [[ "$PS1" == *'\w'* ]]
}

@test "bcp_static: uses custom layout function" {
    my_layout() {
        bcp_append "custom> "
    }
    bcp_static my_layout
    [[ "$PS1" == "custom> " ]]
}

@test "bcp_static: removes dynamic hooks from string PROMPT_COMMAND" {
    PROMPT_COMMAND="_bcp_save_ret; my_func; _bcp_build_prompt"
    bcp_static
    [[ "$PROMPT_COMMAND" != *"_bcp_save_ret"* ]]
    [[ "$PROMPT_COMMAND" != *"_bcp_build_prompt"* ]]
    [[ "$PROMPT_COMMAND" == *"my_func"* ]]
}

@test "bcp_static: removes dynamic hooks from array PROMPT_COMMAND" {
    declare -a PROMPT_COMMAND=("_bcp_save_ret" "my_func" "_bcp_build_prompt")
    bcp_static
    local joined="${PROMPT_COMMAND[*]}"
    [[ "$joined" != *"_bcp_save_ret"* ]]
    [[ "$joined" != *"_bcp_build_prompt"* ]]
    [[ "$joined" == *"my_func"* ]]
}
