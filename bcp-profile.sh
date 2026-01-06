# see /usr/share/doc/bash-color-prompt/README.md

# only for bash
if [ -n "${BASH_VERSION}" -a -z "${bash_color_prompt_disable}" -a \
        -z "${bash_prompt_color_disable}" ]; then

    # enable only in interactive shell
    case $- in
        *i*) ;;
        *) if [ -z "${bash_prompt_color_test}" ]; then return; fi;;
    esac

    if [ '(' "$PS1" = "[\u@\h \W]\\$ " -o "$PS1" = "\\s-\\v\\\$ " -o \
         "${TOOLBOX_PATH}" = "/usr/bin/toolbox" ')' -a \
         '(' -n "${COLORTERM}" -o "${TERM: -5}" = "color" -o \
         "${TERM}" = "linux" ')' -o -n "${bash_color_prompt_force}" -o \
         -n "${bash_prompt_color_force}" ]; then

        # TODO generate static PS1 at buildtime
        source /usr/share/bash-color-prompt/bcp.sh

        bcp_static
    fi
fi
