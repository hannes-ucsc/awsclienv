# awsclienv

Install and switch between specific releases of the AWS CLI v2 on macOS.

AWS publishes a macOS package per release, but installing it replaces
whatever is already there, so pinning a particular release — and working on
two projects that pin different ones — means re-running the installer by
hand. `awsclienv` installs each release into a directory of its own and picks
between them with an environment variable, similar to what `pyenv` does for 
Python, and `tfenv` for Terraform.


## Requirements

macOS and Bash.


## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/hannes-ucsc/awsclienv/main/install.bash | bash
```

That downloads `awsclienv` to `~/.awsclienv/bin` and puts that directory on
your `PATH`, by appending a line to your bash startup file. To effectuate the
`PATH` change, close the shell and start a new one.

**At this point, your existing installations of the AWS CLI v2 are not yet
affected. Uninstall them now, otherwise the next step may not work.**

Then, to let `awsclienv` take control of your installed AWS CLI v2 versions,
run:

```bash
awsclienv activate
```

That links the `aws` and `aws_completer` shims, and registers tab completion
for Bash. Open a new shell once more for that to take effect, then confirm
that the shims have taken over:

```bash
$ type -a aws
aws is /Users/you/.awsclienv/bin/aws
```

One line, naming `~/.awsclienv/bin`, is what you want. Any additional line names
an installation you should remove, especially if it comes first, as it is the 
one you will be running, instead of the shims.

`awsclienv deactivate` reverses this, unlinking the shims and removing the
line, which hands `aws` back to whatever provided it before. It leaves
`awsclienv` itself, and the releases it installed, in place.


### Installing by hand

The installer does nothing you cannot do yourself. Download `awsclienv`:

```bash
mkdir -p ~/.awsclienv/bin
curl -fsSL -o ~/.awsclienv/bin/awsclienv \
    https://raw.githubusercontent.com/hannes-ucsc/awsclienv/main/bin/awsclienv
chmod +x ~/.awsclienv/bin/awsclienv
```

Uninstall your existing installations of the AWS CLI v2, as above, then link
the shims:

```bash
ln -s awsclienv ~/.awsclienv/bin/aws
ln -s awsclienv ~/.awsclienv/bin/aws_completer
```

and add these lines to your startup file:

```bash
export PATH="$HOME/.awsclienv/bin:$PATH"
complete -C aws_completer aws
```

Open a new shell, and confirm that the shims have taken over, as above:

```bash
$ type -a aws
aws is /Users/you/.awsclienv/bin/aws
```


## Usage

To install the most recent version released by AWS:

```bash
awsclienv install
```

The `aws` shim will use the most recent version that is installed locally.  

```bash
$ aws --version
aws-cli/2.37.9 Python/3.14.6 Darwin/24.6.0 exe/arm64
````

We recommend that you pin a specific version by setting `AWSCLIENV_VERSION`:

```bash
export AWSCLIENV_VERSION=2.36.38
awsclienv install
$ aws --version
aws-cli/2.36.38 Python/3.14.6 Darwin/24.6.0 exe/arm64
```

`AWSCLIENV_VERSION` is read on every invocation, so changing it switches
releases immediately, with no further installation as long as the release is
already present. Installing is idempotent, so running `awsclienv install`
against a release you already have costs nothing.

To see which releases you have:

```bash
$ awsclienv list

Releases available for installation are listed at

https://raw.githubusercontent.com/aws/aws-cli/v2/CHANGELOG.rst

To pin this shell to a locally installed release, copy one of
the commands listed below and paste it into the shell prompt.

export AWSCLIENV_VERSION=2.36.38
export AWSCLIENV_VERSION=2.37.9
```


## Where releases live

Each release is installed below `~/.awsclienv/versions`, and takes about
230 MB:

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

Only `bin` is on your `PATH`, and the two shims in it are symlinks to
`awsclienv`, which runs the executable of the same name from the selected
release. No release is ever on your `PATH`.

To remove a release, delete its directory:

```bash
rm -rf ~/.awsclienv/versions/2.36.38
```

To remove `awsclienv` itself, along with every release it installed, start by
undoing the activation:

```bash
awsclienv deactivate
```

Then delete the `PATH` line the installer added to your startup file, which is
the one thing `deactivate` does not account for, and finally:

```bash
rm -rf ~/.awsclienv
```
