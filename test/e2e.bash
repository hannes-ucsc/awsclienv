#!/bin/bash

# End to end, on macOS: install.bash installs awsclienv, the installed
# awsclienv installs the AWS CLI, and the shims run it. Every step consumes
# what the step before it produced, and every step after the first runs in a
# login shell, so that the PATH comes from the startup file install.bash
# wrote, rather than from this script.
#
# It all happens in a scratch HOME that is removed afterwards, leaving the
# machine as it was found. The only substitution is AWSCLIENV_BASE_URL, which
# points at the working copy, so that the files under test are the ones on
# disk rather than the published ones.
#
# Two versions are installed: one with AWSCLIENV_VERSION unset, which resolves
# the most recent version from the upstream CHANGELOG, and one with the
# variable set to the version below. Each costs a download of the package,
# some 60 MB, on every run. The repeated runs that test for idempotence
# download nothing, which is the point of them.

set -o errexit -o nounset -o pipefail

# Any published version older than the most recent one will do
pinned=2.36.38

path_line='export PATH="$HOME/.awsclienv/bin:$PATH"'

repo=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

say() { printf '\n=== %s ===\n' "$*"; }

# A login shell with the scratch HOME, whose .bash_profile is what puts
# awsclienv on the PATH
in_shell() {
	HOME=$scratch bash -l -c "$1" 2>&1 \
		| grep -v "job control\|terminal process"
}

install_bash() {
	curl -fsSL "file://$repo/install.bash" \
		| HOME=$scratch AWSCLIENV_BASE_URL="file://$repo" bash
}

# The version that the shim runs, under the environment given
version_of_aws() {
	in_shell "$1 aws --version" | sed -n 's#^aws-cli/\([^ ]*\) .*#\1#p'
}

same() {
	if test "$2" != "$3"; then
		echo "$1: expected $2, got $3" >&2
		exit 1
	else
		echo "$1: $2"
	fi
}

# Runs a command in a login shell, expecting it to fail and to say why. The
# status is captured without a pipe, which would report grep's status instead.
expect_failure() {
	local what=$1 command=$2 expected=$3 out status=0
	out=$(HOME=$scratch bash -l -c "$command" 2>&1) || status=$?
	grep -v "job control\|terminal process" <<< "$out" || true
	if test $status -eq 0; then
		echo "$what: expected it to fail, but it succeeded" >&2
		exit 1
	elif ! grep -qF "$expected" <<< "$out"; then
		echo "$what: expected the output to mention '$expected'" >&2
		exit 1
	else
		echo "$what: exited $status, saying so"
	fi
}

say "1. install.bash, as the README gives it"
install_bash

say "2. running it again adds nothing and breaks nothing"
install_bash
same "the PATH line appears once" \
	1 "$(grep -cF "$path_line" "$scratch/.bash_profile")"
in_shell 'command -v awsclienv'

say "3. awsclienv activate, found on the PATH step 1 arranged"
in_shell 'awsclienv activate'

say "4. with no version installed, aws and purge say so and fail"
no_version="No AWS CLI v2 version is currently installed"
expect_failure aws 'aws --version' "$no_version"
expect_failure purge 'awsclienv purge' "$no_version"

say "5. that awsclienv installs the most recent AWS CLI version"
in_shell 'awsclienv install' | grep -Ev '^ *[0-9 %]|Dload|Current'
latest=$(basename "$(echo "$scratch/.awsclienv/versions"/*)")

say "6. the shims step 3 linked run the version step 5 installed"
in_shell 'type -a aws; aws --version'
in_shell 'COMP_LINE="aws s3 l" COMP_POINT=8 aws_completer'
same "shim runs the installed version" "$latest" "$(version_of_aws '')"

say "7. a second version, pinned with AWSCLIENV_VERSION"
in_shell "export AWSCLIENV_VERSION=$pinned; awsclienv install" \
	| grep -Ev '^ *[0-9 %]|Dload|Current'
same "pinned shim runs the pin" \
	"$pinned" "$(version_of_aws "AWSCLIENV_VERSION=$pinned")"
same "unpinned shim still runs the most recent" \
	"$latest" "$(version_of_aws '')"

say "8. installing a version that is already there leaves it alone"
before=$(stat -f %m "$scratch/.awsclienv/versions/$pinned")
again=$(in_shell "export AWSCLIENV_VERSION=$pinned; awsclienv install")
echo "$again"
same "it says the version is already installed" \
	1 "$(grep -c "already installed" <<< "$again")"
same "and the version itself is untouched" \
	"$before" "$(stat -f %m "$scratch/.awsclienv/versions/$pinned")"

say "9. list reports both, oldest first"
in_shell 'awsclienv list'
listed=$(in_shell 'awsclienv list 2>/dev/null' \
	| sed 's/.*=//' | tr '\n' ' ' | sed 's/ $//')
same "list is oldest first" "$pinned $latest" "$listed"

say "10. purge keeps the pin and deletes the rest"
in_shell "export AWSCLIENV_VERSION=$pinned; awsclienv purge"
same "only the pin remains" \
	"$pinned" "$(ls "$scratch/.awsclienv/versions" | tr '\n' ' ' | sed 's/ $//')"

say "11. deactivate unwinds step 3"
in_shell 'awsclienv deactivate; type -a aws || echo "aws: gone, as expected"'

say "passed"
