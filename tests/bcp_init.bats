#!/usr/bin/env bats

load setup

@test "bcp_init: adds _bcp_save_ret and _bcp_build_prompt to string PROMPT_COMMAND" {
    PROMPT_COMMAND=""
    bcp_init
    [[ "$PROMPT_COMMAND" == *"_bcp_save_ret"* ]]
    [[ "$PROMPT_COMMAND" == *"_bcp_build_prompt"* ]]
}

@test "bcp_init: preserves existing string PROMPT_COMMAND" {
    PROMPT_COMMAND="my_func"
    bcp_init
    [[ "$PROMPT_COMMAND" == *"my_func"* ]]
    [[ "$PROMPT_COMMAND" == *"_bcp_save_ret"* ]]
    [[ "$PROMPT_COMMAND" == *"_bcp_build_prompt"* ]]
}

@test "bcp_init: does not duplicate on second call (string)" {
    PROMPT_COMMAND=""
    bcp_init
    local first="$PROMPT_COMMAND"
    bcp_init
    [[ "$PROMPT_COMMAND" == "$first" ]]
}

@test "bcp_init: adds to array PROMPT_COMMAND" {
    declare -a PROMPT_COMMAND=()
    bcp_init
    local joined="${PROMPT_COMMAND[*]}"
    [[ "$joined" == *"_bcp_save_ret"* ]]
    [[ "$joined" == *"_bcp_build_prompt"* ]]
}

@test "bcp_init: _bcp_save_ret is first in array PROMPT_COMMAND" {
    declare -a PROMPT_COMMAND=("existing_func")
    bcp_init
    [[ "${PROMPT_COMMAND[0]}" == "_bcp_save_ret" ]]
}

@test "bcp_init: _bcp_build_prompt is last in array PROMPT_COMMAND" {
    declare -a PROMPT_COMMAND=("existing_func")
    bcp_init
    [[ "${PROMPT_COMMAND[-1]}" == "_bcp_build_prompt" ]]
}

@test "bcp_init: does not duplicate on second call (array)" {
    declare -a PROMPT_COMMAND=()
    bcp_init
    local count=${#PROMPT_COMMAND[@]}
    bcp_init
    [[ ${#PROMPT_COMMAND[@]} -eq $count ]]
}
