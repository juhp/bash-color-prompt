# Bash Color Prompt (bcp)

This is intended to become a replacement or follow on to
Fedora's [bash-color-prompt](https://src.fedoraproject.org/rpms/shell-color-prompt) package with a cleaner declarative builder pattern approach,
which makes it easy for users to create clean highly customized bash prompts.

## Basic setup
Add:
```bash
source bash-color-prompt.sh

bcp_init
```
to `~/.bashrc`.

`bcp_init()` sets up `PROMPT_COMMAND` to build `PS1`.

By default it uses the `_bcp_default_layout()` configuration,
which gives a green bold prompt: `user@localhost:~$ `,
with the same appearance as the current default Fedora prompt.
It could be made to support default prompts for other OS's later perhaps.

## Configuration
Users can optionally define `bcp_layout()` to  specify
a custom prompt using `bpc_append`, etc, to their liking.

See `example.bashrc.sh` for an example.

## Try it
Before adding to your `bashrc`, you can test it out in bash with just:
`source example.bashrc.sh`
(or `source bash-color-prompt.sh` and then `bcp_init`).

Note that bcp's functions may still be subject to change at this time.

## Help and Contribute
Please open an issue in <https://github.com/juhp/bash-color-prompt>.

bash-color-prompt is distributed under the GPL license version 3 or later.
