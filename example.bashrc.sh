source bash-color-prompt.sh

bcp_layout() {
    local exit_code=$1

    bcp_duration 1 "yellow" "took "  "\n"
    bcp_append "\t \D{%b %-d (%a)}\n" "dim;reverse"

    # -- Segment: User+Host (Green if user, Red if Root) --
    local user_color="green"
    if [[ $EUID -eq 0 ]]; then user_color="red"; fi

    bcp_append "\u@\h" "$user_color;bold"
    bcp_shlvl "bgmagenta" "^"
    bcp_append " "

    # -- Segment: Directory (Blue) --
    bcp_append "\w" "blue"

    ## already done by vte.sh
    # bcp_title "\u@\h"

    # -- Segment: Git Status --
    bcp_git_branch " " "magenta" "yellow"

    # -- custom status indicator --
    if [[ $exit_code -ne 0 ]]; then
        bcp_append " ✘$exit_code" "red;bold"
    fi

    # -- Segment: The actual prompt char --
    bcp_append "\n\$ " "default"
}

bcp_init
