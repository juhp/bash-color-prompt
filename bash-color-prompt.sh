# ============================================================================
# 1. Internal Helpers (Private)
# ============================================================================

# Translates color names to ANSI numbers
# Returns valid numeric codes (e.g., "red" -> "1") or empty string
_bcp_get_ansi_num() {
    case "$1" in
        [0-9]*)    echo "$1" ;;
        bold)      echo "1" ;;
        dim)       echo "2" ;;
        italic)    echo "3" ;;
        underline) echo "4" ;;
        blink)     echo "5" ;;
        rapid)     echo "6" ;;
        reverse)   echo "7" ;;
        hidden)    echo "8" ;;
        black)     echo "30" ;;
        red)       echo "31" ;;
        green)     echo "32" ;;
        yellow)    echo "33" ;;
        blue)      echo "34" ;;
        magenta)   echo "35" ;;
        cyan)      echo "36" ;;
        white)     echo "37" ;;
        default)   echo "39" ;;
        bgblack)   echo "40" ;;
        bgred)     echo "41" ;;
        bggreen)   echo "42" ;;
        bgyellow)  echo "43" ;;
        bgblue)    echo "44" ;;
        bgmagenta) echo "45" ;;
        bgcyan)    echo "46" ;;
        bgwhite)   echo "47" ;;
        bgdefault) echo "49" ;;
        *)         echo ""  ;; # Unknown or empty
    esac
}

# _bcp_parse_tokens <input_string>
# Example: _bcp_parse_tokens "red;bold"  -> returns "31;1;"
# Example: _bcp_parse_tokens "bgblue;bold" -> returns "44;1;"
_bcp_parse_tokens() {
    local input="$1"
    local output=""

    # Split string by semicolon into an array
    local IFS=';'
    local tokens
    read -ra tokens <<< "$input"

    for token in "${tokens[@]}"; do
        # Is it a named COLOR? (red, blue, etc.)
        local c_code
        c_code=$(_bcp_get_ansi_num "$token")
        if [[ -n "$c_code" ]]; then
            output+="${c_code};"
        fi
    done

    echo "$output"
}

# ============================================================================
# 2. Public API
# ============================================================================

# Internal buffer variable (do not touch manually)
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
    local ansi_input="${2:-}"

    local ansi_sequence=""

    # Parse ANSI names or codes
    if [[ -n "$ansi_input" ]]; then
        ansi_sequence+=$(_bcp_parse_tokens "$ansi_input")
    fi
    # Assembly
    if [[ -n "$ansi_sequence" ]]; then
        # Strip trailing semicolon
        _bcp_buffer+="\[\033[${ansi_sequence%;}m\]${text}\[\033[${3-0}m\]"
    else
        _bcp_buffer+="${text}"
    fi
}

# ============================================================================
# 3. Helper custom functions
# ============================================================================

# * Git Integration *

# Internal helper to check dirty state quickly
# Returns: "1" if dirty, "" if clean
_bcp_is_git_dirty() {
    # --porcelain: easy to parse
    # --untracked-files=no: huge speedup in large repos (optional, but recommended for prompts)
    # --ignore-submodules: prevents hanging on network checks for submodules

    local status
    status=$(git status --porcelain --ignore-submodules=dirty 2>/dev/null | head -n1)

    if [[ -n "$status" ]]; then
        echo "1"
    fi
}

# ----------------------------------------------------------------------------
# bcp_git_branch
# Appends the current git branch and status symbol.
#
# Arguments:
#   $1 : Clean Color (default: green)
#   $2 : Dirty Color (default: red)
# ----------------------------------------------------------------------------
bcp_git_branch() {
    local clean_color="${1:-green}"
    local dirty_color="${2:-red}"

    # 1. Get the branch name (fastest method)
    # 2> /dev/null suppresses error if not in a git repo
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) || \
    branch=$(git rev-parse --short HEAD 2>/dev/null)

    # If $branch is empty, we aren't in a git repo -> exit immediately
    if [[ -z "$branch" ]]; then
        return
    fi

    # 2. Check Dirty State
    if [[ -n "$(_bcp_is_git_dirty)" ]]; then
        # Dirty State: Branch name + Dirty Marker
        # You can customize the symbol here (e.g., *, ±, ✗)
        bcp_append " ($branch*)" "$dirty_color"
    else
        # Clean State
        bcp_append " ($branch)" "$clean_color"
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
    # \[...\] is NOT needed here because this doesn't print to the buffer width
    _bcp_buffer+="\e]0;$1\a"
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
    if [ -n "$container" ]; then
        if [ "$DESKTOP_SESSION" = "gnome" ]; then
            bcp_append "${1:-⬢}"
        else
            bcp_append "${1:-⬢ }"
        fi
    fi
}

# ============================================================================
# 4. The Engine (Driver)
# ============================================================================

# Default layout (Fallback)
# Used if the user hasn't defined their own bcp_layout yet.
_bcp_default_layout() {
    local exit_code=$1
    bcp_append "\u@\h" "green;bold"
    bcp_append ":"
    bcp_append "\w" "green;bold"
    bcp_segment_status "$exit_code"
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

# ============================================================================
# 5. Initialization
# ============================================================================

_bcp_save_ret() {
    _bcp_saved_ret=$?
}

# bcp_init
# Activates the library. Call this once at the end of your .bashrc
bcp_init() {
    # Bash 5.1+ supports PROMPT_COMMAND array
    if (( BASH_VERSINFO[0] > 5 )) || (( BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 1 )); then
        # convert to an array if necessary
        if [[ "$(declare -p PROMPT_COMMAND 2>/dev/null)" != "declare -a"* ]]; then
            PROMPT_COMMAND=(${PROMPT_COMMAND:+"$PROMPT_COMMAND"})
        fi

        # Prepend our Capture Function (so it runs first)
        # We ensure it isn't already there to prevent dupes
        if [[ "${PROMPT_COMMAND[*]}" != *"_bcp_save_ret"* ]]; then
            PROMPT_COMMAND=("_bcp_save_ret" "${PROMPT_COMMAND[@]}")
        fi

        # Append our Build Function (so it sets PS1 last)
        if [[ "${PROMPT_COMMAND[*]}" != *"_bcp_build_prompt"* ]]; then
            PROMPT_COMMAND+=("_bcp_build_prompt")
        fi

    else
        # Prevent double-sourcing
        if [[ "$PROMPT_COMMAND" == *"_bcp_build_prompt"* ]]; then return; fi

        if [[ -z "$PROMPT_COMMAND" ]]; then
            PROMPT_COMMAND="_bcp_save_ret; _bcp_build_prompt"
        else
            # Inject capture at start, builder at end
            PROMPT_COMMAND="_bcp_save_ret; $PROMPT_COMMAND; _bcp_build_prompt"
        fi
    fi
}
