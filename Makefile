shellcheck:
	shellcheck -s bash bash-color-prompt.sh profile.d/bcp-fedora.sh bashrc.d/bcp-cfg.sh examples/local.bashrc.sh

test:
	bats tests

snapshot:
	git archive --prefix=bash-color-prompt-$$(date +%Y%m%dT%H%M%S)/ -o bash-color-prompt-$$(date +%Y%m%dT%H%M%S).tar.gz HEAD
