#!/usr/bin/env bats

load setup

@test "bcp_container: no output outside container" {
    unset container
    bcp_container
    [[ "$_bcp_buffer" == "" ]]
}

@test "bcp_container: shows hexagon in container (non-gnome)" {
    container="podman"
    unset DESKTOP_SESSION
    bcp_container
    [[ "$_bcp_buffer" == "⬢ " ]]
}

@test "bcp_container: shows hexagon without trailing space in gnome" {
    container="toolbox"
    DESKTOP_SESSION="gnome"
    bcp_container
    [[ "$_bcp_buffer" == "⬢" ]]
}

@test "bcp_container: custom symbol" {
    container="podman"
    unset DESKTOP_SESSION
    bcp_container "[C]"
    [[ "$_bcp_buffer" == "[C]" ]]
}
