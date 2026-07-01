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
}
