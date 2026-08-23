shellcheck:
	shellcheck -s bash bash-color-prompt.sh profile.d/bcp-fedora.sh bashrc.d/bcp-cfg.sh examples/local.bashrc.sh

test:
	bats tests
