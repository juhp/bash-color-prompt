# FIXME: use mapfile -t my_array < <(command)
# FIXME  to define BCP_OS_$1
# Usage eg: bcp_os_release ANSI_COLOR
bcp_os_release() {
    local envvar=$1
    if [[ -r /etc/os-release && -n "$envvar" ]]; then
        eval "$(grep "$envvar" /etc/os-release)"
    fi
}

# create an url link
bcp_url_link() {
    local url=$1
    local text=${2:-$1}
    printf '\e]8;;%s\e\\%s\e]8;;\e\\\n' "$url" "$text"
}
