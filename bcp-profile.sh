# see /usr/share/doc/bash-color-prompt/README.md

# only for bash
if [ -n "${BASH_VERSION}" -a -z "${bash_color_prompt_disable}" -a -z "${bash_prompt_color_disable}" ]; then

    # enable only in interactive shell
    case $- in
        *i*) ;;
        *) if [ -z "${bash_prompt_color_test}" ]; then return; fi;;
    esac

    source /usr/share/bash-color-prompt/bcp.sh

    bcp_init
fi
