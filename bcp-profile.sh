# see /usr/share/doc/bash-color-prompt/README.md

# only for bash
if [[ -n "${BASH_VERSION}" && -z "${bash_color_prompt_disable}" &&
          -z "${bash_prompt_color_disable}" ]]; then

    # enable only in interactive shell
    case $- in
        *i*) ;;
        *) return ;;
    esac

    if [[ ( ( "$PS1" == "[\u@\h \W]\\$ " || "$PS1" == "\\s-\\v\\\$ " ||
                  "$TOOLBOX_PATH" == "/usr/bin/toolbox" ) &&
                ( -n "$COLORTERM" || "${TERM: -5}" == "color" ||
                      "$TERM" == "linux" ) ) ||
              -n "$bash_color_prompt_force" ]]; then

        # TODO generate static PS1 at buildtime
        # shellcheck source=bash-color-prompt.sh
        source /usr/share/bash-color-prompt/bcp.sh

        # FIXME use:
        # if [[ -n "${NO_COLOR}" && -z "${BASH_PROMPT_USE_COLOR}" || -n "${BASH_PROMPT_NO_COLOR}" ]]; then
        bcp_static _bcp_default_layout
    fi
fi
