bcp_setup

bcp_layout() {
    local exit_code=$1

    # show duration of commands
    bcp_duration 1 "yellow" "took " "\n"
    # datestamp
    bcp_append "\t \D{%b %-d (%a)}\n" "dim;reverse"

    # SHLVL
    bcp_shlvl "bgmagenta" "^"

    # hexagon
    bcp_container
    # user@host
    local user_color="green"
    if [[ $EUID -eq 0 ]]; then user_color="red"; fi
    bcp_append "\h" "$user_color;bold"
    bcp_title "\h:\w"

    # directory
    bcp_append "\w" "blue"

    # git status
    bcp_git_branch " " "magenta" "yellow"

    # status indicator
    if [[ $exit_code -ne 0 ]]; then
        bcp_append " ✘$exit_code" "red;bold"
    fi

    # actual prompt char
    bcp_append "\n\$ " "default"
}
