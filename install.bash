#!/bin/bash

# Download awsclienv to ~/.awsclienv/bin and put that directory on the PATH by
# adding a line to the bash startup file. Run this with
#
#     curl -fsSL https://raw.githubusercontent.com/hannes-ucsc/awsclienv/main/install.bash | bash
#
# and then, in a new shell, `awsclienv activate`, to link the shims and
# register the shell completions.
#
# Set AWSCLIENV_BASE_URL to install from somewhere else, like a fork.

set -o errexit -o nounset -o pipefail

default_base_url=https://raw.githubusercontent.com/hannes-ucsc/awsclienv/main
base_url=${AWSCLIENV_BASE_URL:-$default_base_url}
bin=$HOME/.awsclienv/bin

mkdir -p "$bin"
curl --fail --silent --show-error --location \
	--output "$bin/awsclienv.download" \
	"$base_url/bin/awsclienv"
# Only a complete download replaces an installed awsclienv, so that a failure
# part way through leaves the working copy alone
chmod +x "$bin/awsclienv.download"
mv "$bin/awsclienv.download" "$bin/awsclienv"
echo "Downloaded awsclienv to $bin"

# The file awsclienv itself would pick, and for the same reason: a macOS
# terminal starts a login shell, which reads .bash_profile and reaches .bashrc
# only by way of the user sourcing it there.
if test -f "$HOME/.bash_profile"; then
	file=$HOME/.bash_profile
elif test -f "$HOME/.bashrc"; then
	file=$HOME/.bashrc
else
	file=$HOME/.bash_profile
fi

# Not the expanded path, so that the line survives a different home directory
line='export PATH="$HOME/.awsclienv/bin:$PATH"'
if test -f "$file" && grep -qF "$line" "$file"; then
	echo "$file puts $bin on the PATH already"
else
	printf '\n%s\n' "$line" >> "$file"
	echo "Added $bin to the PATH in $file"
fi

echo
# Whether a new shell is needed is a question about the PATH of the shell this
# script was invoked from, not about the startup file: this script runs in a
# child of that shell, so it cannot touch its PATH, only the PATH of shells
# started from now on.
case ":${PATH:-}:" in
	*":$bin:"*)
		echo "Next, run"
		;;
	*)
		echo "Open a new shell, then run"
		;;
esac
echo
echo "    awsclienv activate"
echo
