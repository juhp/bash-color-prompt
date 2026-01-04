#source /path/to/bcp-lib.sh

bcp_layout() {
    local exit_code=$1

    # -- Segment: Hostname (Green if user, Red if Root) --
    local user_color="green"
    if [[ $EUID -eq 0 ]]; then user_color="red"; fi

    bcp_append "\u@\h" "$user_color" "default" "bold"
    bcp_append " "

    # -- Segment: Directory (Blue) --
    bcp_append "\w" "blue"

    # -- Segment: Git Status --
    bcp_git_branch "magenta" "yellow"

    ## already done by vte.sh
    # bcp_title "\u@\h"

    # -- Segment: Status Indicator --
    if [[ $exit_code -ne 0 ]]; then
        bcp_append " ✘$exit_code" "red" "default" "bold"
    fi
    # -- Segment: The actual prompt char --
    bcp_append "\n\$ " "default"
}

bcp_init
