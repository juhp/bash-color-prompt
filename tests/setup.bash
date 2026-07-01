setup() {
    _bcp_buffer=""
    _bcp_timer_file=""
    _bcp_last_duration_s=""
    _bcp_saved_ret=""
    PROMPT_COMMAND=""
    PS0=""
    PS1=""

    # shellcheck source=../bash-color-prompt.sh
    source "$BATS_TEST_DIRNAME/../bash-color-prompt.sh"
    # bats wraps everything in functions, so declare -A in the sourced
    # file creates a function-local; promote to global for the test body
    eval "$(declare -p _bcp_ansi | sed 's/declare -A/declare -gA/')"
}
