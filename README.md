# Bash Color Prompt (bcp)

This is a new version of Fedora's
[bash-color-prompt](https://src.fedoraproject.org/rpms/shell-color-prompt)
package with a cleaner declarative builder pattern approach,
which makes it easy for users to create clean highly customized bash prompts.

## How to try it out
Execute or add:
```bash
source bash-color-prompt.sh

bcp_init
```
to `~/.bashrc` say.

`bcp_init()` sets up `PROMPT_COMMAND` to build `PS1`.

By default it uses the `_bcp_default_layout()` configuration,
which gives a green bold prompt: `user@localhost:~$ `,
with the same appearance as the current default Fedora prompt.
It could be made to support default prompts for other OS's later perhaps.

## System installation
- `bcp-profile.sh` should be installed as `/etc/profile.d/bash-color-prompt.sh`
- `bash-color-prompt.sh` should be installed in `/usr/share/bash-color-prompt/bcp.sh`

Users should then add `bcp_setup` to their `.bashrc` (`.bashrc.d/`)
if they wish to activate prompt layout customization,
and they can define their own `bcp_layout` prompt.
(`bcp_setup` loads the bcp functions and runs `bcp_init`.)

## Configuration
Users can optionally define `bcp_layout()` to  specify
a custom prompt using `bcp_append`, etc, to their liking.

See [bashrc.d/bcp-cfg.sh](https://github.com/juhp/bash-color-prompt/blob/main/bashrc.d/bcp-cfg.sh) for a custom example.

Note that bcp's functions may still be subject to change at this time.

## More interesting example
Before adding to your `bashrc`, you can also test this more complex example
in a bash session with:
`source examples/local.bashrc.sh`

## Requirements
Currently it requires Bash 5.1 or later.

## Help and Contribute
Please open an issue in <https://github.com/juhp/bash-color-prompt>.

## License
bash-color-prompt is distributed under the GPL license version 3 or later.
