# awsclienv

Install and switch between specific versions of the AWS CLI v2 on macOS.

AWS publishes an installer package for macOS but using it replaces the
previously installed version. Luckily, AWS retains older versions on their
download server and the installer can be instructed to use a custom destination
directory. `awsclienv` manages multiple versions installed side-by-side,
allowing you to select one of them by setting an environment variable. This is
similar to what `pyenv` does for Python, and `tfenv` for Terraform. Nothing is
installed outside your home directory, and root privileges are not required.


## Requirements

macOS and Bash.


## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/hannes-ucsc/awsclienv/main/bin/awsclienv | bash
```

This downloads `awsclienv` to `~/.awsclienv/bin` and puts that directory on
your `PATH` by appending a line to your bash startup file. To effectuate the
`PATH` change, close the shell and start a new one.

If you'd rather not download code and run it without prior review, see
[Installing by hand](#installing-by-hand).

**At this point, your existing installations of the AWS CLI v2 are not yet
affected. Uninstall them now, otherwise the next step may not work.**

To let `awsclienv` take control of your installed AWS CLI v2 versions, run:

```bash
awsclienv activate
```

That links the `aws` and `aws_completer` shims, and registers tab completion
for Bash. Open a new shell once more for those changes to take effect. Then
confirm that the shims have taken over:

```bash
$ type -a aws
aws is /Users/you/.awsclienv/bin/aws
```

It should print one line, specifying `~/.awsclienv/bin`. Any additional
lines point to installations you should remove, especially if they precede
the expected line, as they will shadow the shim.

`awsclienv deactivate` reverses this, removing the shims and deregistering the
tab completion. It leaves `awsclienv` and any versions it installed in place.


## Usage

To install the most recent version released by AWS:

```bash
awsclienv install
```

By default, the `aws` shim will use the most recent version that is
installed locally, which in this case is the one we just installed.

```bash
$ aws --version
aws-cli/2.37.9 Python/3.14.6 Darwin/24.6.0 exe/arm64
```

We recommend that you pin a specific version by setting `AWSCLIENV_VERSION`:

```bash
export AWSCLIENV_VERSION=2.36.38
awsclienv install
$ aws --version
aws-cli/2.36.38 Python/3.14.6 Darwin/24.6.0 exe/arm64
```

`AWSCLIENV_VERSION` is read on every invocation, so changing it switches
versions immediately, with no further installation as long as the version is
already present. Installing is idempotent, so running `awsclienv install`
against a version you already have costs nothing.

To see which versions you have:

```bash
$ awsclienv list

Versions available for installation are listed at

https://raw.githubusercontent.com/aws/aws-cli/v2/CHANGELOG.rst

To pin this shell to a locally installed version, copy one of
the commands listed below and paste it into the shell prompt

export AWSCLIENV_VERSION=2.36.38
export AWSCLIENV_VERSION=2.37.9  # default
```

The version in use is marked with a comment, so that line can be copied like
any other. The mark reads `# selected` where `AWSCLIENV_VERSION` asked for
that version, and `# default` where nothing did. `awsclienv` on its own
prints the synopsis and the version in use, with `(selected)` or `(default)`
for the same reason.


## Installing by hand

Piping it to a shell does nothing you cannot do yourself. Download the same
file instead:

```bash
mkdir -p ~/.awsclienv/bin
curl -fsSL -o ~/.awsclienv/bin/awsclienv \
    https://raw.githubusercontent.com/hannes-ucsc/awsclienv/main/bin/awsclienv
chmod +x ~/.awsclienv/bin/awsclienv
```

Uninstall your existing installations of the AWS CLI v2, as under
[Installation](#installation), then link the shims:

```bash
ln -s awsclienv ~/.awsclienv/bin/aws
ln -s awsclienv ~/.awsclienv/bin/aws_completer
```

and add these lines to your startup file:

```bash
export PATH="$HOME/.awsclienv/bin:$PATH"
complete -C awsclienv awsclienv
complete -C aws_completer aws
```

Open a new shell, and confirm that the shims have taken over, as under
[Installation](#installation):

```bash
$ type -a aws
aws is /Users/you/.awsclienv/bin/aws
```

Continue to the [Usage](#usage) section above.


## Installation layout

Each version is installed in a directory underneath `~/.awsclienv/versions`,
and takes up about 230 MiB of space on disk.

```
~/.awsclienv/
├── bin/
│   ├── awsclienv
│   ├── aws → awsclienv
│   └── aws_completer → awsclienv
└── versions/
    ├── 2.36.38/aws-cli/{aws,aws_completer,…}
    └── 2.37.1/aws-cli/{aws,aws_completer,…}
```

Only the `bin` directory is on your `PATH`, and the two shims in it are
symlinks to `awsclienv`, which runs the executable of the same name from the
selected version. No version is ever on your `PATH`.

To reclaim the space taken up by installed versions you no longer use:

```bash
awsclienv purge
```

That deletes every installed version but the one `AWSCLIENV_VERSION`
specifies, or the most recent one if the variable is not set. It refuses to
run if the version specified is not installed, rather than leaving you with
none at all.

To remove one version in particular, delete its directory:

```bash
rm -rf ~/.awsclienv/versions/2.36.38
```


## Updating

```bash
awsclienv self-update
```

That pipes the `awsclienv` at the URL it was installed from to a shell, which
is what installed it in the first place. It replaces the installed copy and
adds any line to your startup file that a newer `awsclienv` wants and an
older one did not.


## Deinstallation

To completely remove `awsclienv` along with every AWS CLI version it installed:

```bash
awsclienv self-remove
```

To part with unused installed versions of the AWS CLI, but keep `awsclienv`,
see [`awsclienv purge`](#installation-layout) instead.


## Tests

```bash
./test/e2e.bash
```

See the comments at the top of that file for what it covers and what it
costs.
