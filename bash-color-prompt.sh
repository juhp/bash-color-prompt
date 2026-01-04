# ============================================================================
# 1. Internal Helpers (Private)
# ============================================================================

# Translates color names to ANSI numbers
# Returns valid numeric codes (e.g., "red" -> "1") or empty string
_bcp_get_ansi_num() {
    case "$1" in
        black)   echo "0" ;;
        red)     echo "1" ;;
        green)   echo "2" ;;
        yellow)  echo "3" ;;
        blue)    echo "4" ;;
        magenta) echo "5" ;;
        cyan)    echo "6" ;;
        white)   echo "7" ;;
        default) echo "9" ;; # 39/49 is default
        *)       echo ""  ;; # Unknown or empty
    esac
}

# Translates style names to ANSI attribute codes
_bcp_get_style_num() {
    case "$1" in
        bold)      echo "1" ;;
        dim)       echo "2" ;;
        italic)    echo "3" ;;
        underline) echo "4" ;;
        blink)     echo "5" ;;
        rapid)     echo "6" ;;
        reverse)   echo "7" ;;
        hidden)    echo "8" ;;
        *)         echo ""  ;;
    esac
}

# _bcp_parse_tokens <input_string> <color_prefix>
# Example: _bcp_parse_tokens "red;bold" "3"  -> returns "31;1;"
# Example: _bcp_parse_tokens "blue;bold" "4" -> returns "44;1;"
_bcp_parse_tokens() {
    local input="$1"
    local prefix="$2" # "3" for FG, "4" for BG, "" for Style
    local output=""

    # Split string by semicolon into an array
    local IFS=';'
    local tokens
    read -ra tokens <<< "$input"

    for token in "${tokens[@]}"; do
        # 1. Is it a named COLOR? (red, blue, etc.)
        local c_code
        c_code=$(_bcp_get_ansi_num "$token")
        if [[ -n "$c_code" ]]; then
            # Apply the requested prefix (3 or 4) to the color code
            # If prefix is empty (Style slot), defaults to FG (3) behavior or raw
            output+="${prefix:-3}${c_code};"
            continue
        fi

        # 2. Is it a named STYLE? (bold, underline, etc.)
        local s_code
        s_code=$(_bcp_get_style_num "$token")
        if [[ -n "$s_code" ]]; then
            # Styles never get the 3/4 color prefix
            output+="${s_code};"
            continue
        fi

        # 3. Fallback: Raw code or number
        output+="${token};"
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
#   $2 : Foreground Color (red, green, blue, etc.) [Optional]
#   $3 : Background Color (red, green, blue, etc.) [Optional]
#   $4 : Style (bold, dim, reverse, underline)     [Optional]
# ----------------------------------------------------------------------------
# Usage: bcp_append <text> [fg] [bg] [style]
# fg/bg/style can be:
#   - Names: "red", "blue", "bold", "default"
#   - Raw Codes: "1;33" (Bold Yellow), "38;5;208" (Orange), "101" (Hi-Intensity BG)
bcp_append() {
    local text="$1"
    local fg_in="${2:-}"    # Context: Foreground (Prefix 3)
    local bg_in="${3:-}"    # Context: Background (Prefix 4)
    local style_in="${4:-}" # Context: Style (No Prefix)

    local ansi_sequence=""

    # 1. Parse Foreground Slot (Apply '3' to colors)
    if [[ -n "$fg_in" ]]; then
        ansi_sequence+=$(_bcp_parse_tokens "$fg_in" "3")
    fi

    # 2. Parse Background Slot (Apply '4' to colors)
    if [[ -n "$bg_in" ]]; then
        ansi_sequence+=$(_bcp_parse_tokens "$bg_in" "4")
    fi

    # 3. Parse Style Slot (No prefix)
    if [[ -n "$style_in" ]]; then
        ansi_sequence+=$(_bcp_parse_tokens "$style_in" "")
    fi

    # 4. Assembly
    if [[ -n "$ansi_sequence" ]]; then
        ansi_sequence="${ansi_sequence%;}" # Strip trailing semicolon
        _bcp_buffer+="\[\033[${ansi_sequence}m\]${text}\[\033[0m\]"
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

# ============================================================================
# 4. The Engine (Driver)
# ============================================================================

# Default layout (Fallback)
# Used if the user hasn't defined their own bcp_layout yet.
_bcp_default_layout() {
    local exit_code=$1
    bcp_append "\u@\h" "green" "" "bold"
    bcp_append ":"
    bcp_append "\w" "green" "" "bold"
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
