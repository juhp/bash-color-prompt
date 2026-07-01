export BASH_COLOR_PROMPT_VERSION=@BASHCOLORVERSION@

# Internal functions

# Color/style name → ANSI code lookup
declare -A _bcp_ansi=(
    [bold]=1 [dim]=2 [italic]=3 [underline]=4
    [blink]=5 [rapid]=6 [reverse]=7 [hidden]=8
    [black]=30 [red]=31 [green]=32 [yellow]=33
    [blue]=34 [magenta]=35 [cyan]=36 [white]=37 [default]=39
    [bgblack]=40 [bgred]=41 [bggreen]=42 [bgyellow]=43
    [bgblue]=44 [bgmagenta]=45 [bgcyan]=46 [bgwhite]=47 [bgdefault]=49
)

# _bcp_parse_tokens "red;bold" -> _bcp_parsed="31;1;"
# Named colors are resolved; numeric codes pass through as-is
_bcp_parse_tokens() {
    local IFS=';' token
    local -a tokens
    read -ra tokens <<< "$1"
    _bcp_parsed=""
    for token in "${tokens[@]}"; do
        _bcp_parsed+="${_bcp_ansi[$token]:-$token};"
    done
}

# Internal variable (do not touch)
_bcp_timer_file=""

# Triggered by PS0 (before command runs)
_bcp_on_exec() {
    printf '%s\n' "$EPOCHSECONDS" > "$_bcp_timer_file"
}

# Public API

# Internal variable (do not touch)
_bcp_buffer=""

# ----------------------------------------------------------------------------
# bcp_append
# Adds text to the prompt buffer with safe color wrapping.
#
# Arguments:
#   $1 : Text to display
#   $2 : ANSI styling (color/style names or codes) [Optional]
#   $3 : Style end/reset (defaults to reset) [Optional]
# ----------------------------------------------------------------------------
# Usage: bcp_append <text> [fg] [bg] [style]
# fg/bg/style can be:
#   - Names: "red", "blue", "bold", "default"
#   - Raw Codes: "1;33" (Bold Yellow), "38;5;208" (Orange), "101" (Hi-BG)
bcp_append() {
    local text="$1"
    if [[ -n "${2:-}" ]]; then
        _bcp_parse_tokens "$2"
        _bcp_buffer+="\[\e[${_bcp_parsed%;}m\]${text}\[\e[${3-0}m\]"
    else
        _bcp_buffer+="${text}"
    fi
}

_bcp_append_raw() {
    local text="$1"
    local ansi="${2:-}"
    if [[ -n "$ansi" ]]; then
        _bcp_buffer+="\[\e[${ansi%;}m\]${text}\[\e[${3-0}m\]"
    else
        _bcp_buffer+="${text}"
    fi
}

# Helper custom functions

# * Git Integration *

_bcp_is_git_dirty() {
    [[ -n "$(git status --porcelain --untracked-files=no --ignore-submodules=dirty 2>/dev/null)" ]]
}

# ----------------------------------------------------------------------------
# bcp_git_branch
# Appends the current git branch and status symbol.
#
# Arguments:
#   $1 : prefix before branch
#   $2 : Clean Color (default: green)
#   $3 : Dirty Color (default: red)
# ----------------------------------------------------------------------------
# FIXME maybe separate or add bcp_git_status
bcp_git_branch() {
    local prefix="$1"
    # FIXME better defaults?
    local clean_color="${2:-green}"
    local dirty_color="${3:-red}"

    # Get the branch name
    local branch
    # branch or commit (latter can fail right after git init (no commit))
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) || \
    branch=$(git rev-parse --short HEAD 2>/dev/null)

    # If $branch is empty, we aren't in a git repo -> exit immediately
    if [[ -z "$branch" ]]; then
        return
    fi

    if _bcp_is_git_dirty; then
        bcp_append "$prefix($branch*)" "$dirty_color"
    else
        bcp_append "$prefix($branch)" "$clean_color"
    fi
}

# Other custom helpers #

# A function to show if the last command failed
bcp_segment_status() {
    local exit_code=$1
    if [[ $exit_code -ne 0 ]]; then
        bcp_append "[$exit_code]" "red"
    fi
}

# bcp_title "My Title"
bcp_title() {
    # \e]0; = Start window title sequence
    # \a    = End sequence
    echo -n -e "\e]0;${1@P}\a"
}

# Usage: bcp_duration [min_seconds] [color] [prefix] [suffix]
# Example: bcp_duration 2 "yellow" "took " "\n"
# (only show if command takes longer than 2s)
bcp_duration() {
    if [[ -z "$_bcp_timer_file" ]]; then
        # Determine the best location for the timer file
        if [[ -n "$XDG_RUNTIME_DIR" && -d "$XDG_RUNTIME_DIR" ]]; then
            _bcp_timer_file="${XDG_RUNTIME_DIR}/bcp-timer-${$}"
        else
            _bcp_timer_file="/tmp/bcp-timer-${USER}-${$}"
        fi
        # Hook into PS0 for start-time capturing
        if [[ "$PS0" != *"_bcp_on_exec"* ]]; then
            PS0="\$(_bcp_on_exec)$PS0"
        fi
        trap 'rm -f "$_bcp_timer_file"' EXIT
    fi

    if [[ -z "$_bcp_last_duration_s" ]]; then
        return
    fi

    local threshold_s="${1:-2}" # Default: only show if > 2s
    local color="${2:-yellow}"
    local prefix="${3:-took }"
    local suffix="${4:-}"

    local dur=$_bcp_last_duration_s

    # If duration is less than threshold, do nothing
    if (( dur < threshold_s )); then
        return
    fi

    _bcp_last_duration_s=""

    local human_time
    local daysec=$(( 24 * 3600 ))
    if (( dur >= daysec)); then
        local day=$(( dur / daysec ))
        local hour=$(( (dur % daysec) / 3600 ))
        local min=$(( (dur % 3600) / 60 ))
        human_time="${day}d ${hour}h ${min}m"
    elif (( dur >= 3600 )); then
        local hour=$(( dur / 3600 ))
        local min=$(( (dur % 3600) / 60 ))
        human_time="${hour}h ${min}m"
    elif (( dur >= 60 )); then
        local min=$(( dur / 60 ))
        local sec=$(( dur % 60 ))
        human_time="${min}m ${sec}s"
    else
        human_time="${dur}s"
    fi

    bcp_append "${prefix}${human_time}${suffix}" "$color"
}

# Usage: bcp_shlvl [color] [prefix_char]
bcp_shlvl() {
    local color="${1:-magenta}"
    local prefix="${2:-}"
    if [[ "${SHLVL:-1}" -gt 1 ]]; then
        bcp_append "${prefix}${SHLVL}" "$color"
    fi
}

bcp_container() {
    if [[ -n "$container" ]]; then
        if [[ "$DESKTOP_SESSION" = "gnome" ]]; then
            bcp_append "${1:-⬢}"
        else
            bcp_append "${1:-⬢ }"
        fi
    fi
}

# The Engine (Driver)

# Default layout (Fallback)
# Used if the user hasn't defined their own bcp_layout yet.
_bcp_default_layout() {
    local color="green"
    # 0.7 used [[ "$USER" = "root" ]]
    if [[ $EUID -eq 0 ]]; then color="magenta"; fi
    bcp_append "\u@\h" "$color;bold"
    bcp_append ":"
    bcp_append "\w" "$color;bold"
    bcp_append "\$ "
}

# Old compat layout
_bcp_compat_layout() {
    local color="32"
    # 0.7 used [[ "$USER" = "root" ]]
    if [[ $EUID -eq 0 ]]; then color="35"; fi
    _bcp_append_raw "\u@\h" "\${PROMPT_COLOR:-$color};1"
    bcp_append ":"
    _bcp_append_raw "\w" "\${PROMPT_DIR_COLOR:-\${PROMPT_COLOR:-$color}};1"
    bcp_append "\$ "
}

# Internal driver function called every time the prompt needs refreshing
_bcp_build_prompt() {
    # CRITICAL: Capture the exit code of the LAST command immediately.
    # If we run any other command before this, $? will be overwritten.
    local last_exit_code="${_bcp_saved_ret:-$?}"

    # 1. Reset the buffer for the new prompt
    _bcp_buffer=""

    # 2. Call the user's layout function (Dependency Injection)
    if declare -f bcp_layout > /dev/null; then
        # Pass the exit code so the user can display it
        bcp_layout "$last_exit_code"
    else
        # Fallback: If user didn't define a layout, use a safe default
        _bcp_default_layout "$last_exit_code"
    fi

    # 3. Apply the buffer to PS1
    # We do not use 'export' here to avoid unnecessary environment overhead
    PS1="${_bcp_buffer}"
}

# Initialization

# Internal variable (do not touch)
_bcp_last_duration_s=""

_bcp_save_ret() {
    # Capture Exit Code
    _bcp_saved_ret=$?

    if [[ -r "$_bcp_timer_file" ]]; then
        local start; start=$(<"$_bcp_timer_file")
        rm -f "$_bcp_timer_file"
        _bcp_last_duration_s=$(( EPOCHSECONDS - start ))
    else
        _bcp_last_duration_s=""
    fi
}

# Simple static PS1 without PROMPT_COMMAND updating
# which can be used instead of dynamic bcp_init
# takes optional layout function (default _bcp_default_layout)
bcp_static() {
    local layout=$1

    # Remove dynamic hooks if bcp_init was called previously
    if [[ "$(declare -p PROMPT_COMMAND 2>/dev/null)" == "declare -a"* ]]; then
        local cmd new_cmd=()
        for cmd in "${PROMPT_COMMAND[@]}"; do
            [[ "$cmd" == "_bcp_save_ret" || "$cmd" == "_bcp_build_prompt" ]] && continue
            new_cmd+=("$cmd")
        done
        PROMPT_COMMAND=("${new_cmd[@]}")
    else
        PROMPT_COMMAND="${PROMPT_COMMAND//_bcp_save_ret; /}"
        PROMPT_COMMAND="${PROMPT_COMMAND//; _bcp_build_prompt/}"
        PROMPT_COMMAND="${PROMPT_COMMAND//_bcp_build_prompt/}"
    fi

    _bcp_buffer=""
    if declare -f "$layout" > /dev/null; then
        $layout
    else
        _bcp_default_layout
    fi
    PS1="${_bcp_buffer}"
}

# bcp_init
# Activates the library. Call this once at the end of your .bashrc
# Usage: bcp_init
bcp_init() {
    if [[ "$(declare -p PROMPT_COMMAND 2>/dev/null)" == "declare -a"* ]]; then
        if [[ "${PROMPT_COMMAND[*]}" != *"_bcp_save_ret"* ]]; then
            PROMPT_COMMAND=("_bcp_save_ret" "${PROMPT_COMMAND[@]}")
        fi
        if [[ "${PROMPT_COMMAND[*]}" != *"_bcp_build_prompt"* ]]; then
            PROMPT_COMMAND+=("_bcp_build_prompt")
        fi
    else
        if [[ "$PROMPT_COMMAND" != *"_bcp_build_prompt"* ]]; then
            PROMPT_COMMAND="_bcp_save_ret; ${PROMPT_COMMAND:+$PROMPT_COMMAND; }_bcp_build_prompt"
        fi
    fi
}
