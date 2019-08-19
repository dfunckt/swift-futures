#!/usr/bin/env sh

set -e

if test -n "$(git status -z --porcelain)"; then
	echo 'ERROR: Found uncommitted changes and/or untracked files.'
	echo '  Run `make precommit` in your working directory, commit'
	echo '  the changes and push again.'
	echo ''
	git status -s
	exit 1
fi
