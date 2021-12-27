#!/bin/bash -e

OP_ROOT=$(git rev-parse --show-toplevel)
ARCH=$(uname -m)

# Install brew if required
if [[ $(command -v brew) == "" ]]; then
  echo "Installing Hombrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

brew bundle --file=- <<-EOS
brew "cmake"
brew "zlib"
brew "bzip2"
brew "rust"
brew "rustup-init"
brew "capnp"
brew "coreutils"
brew "eigen"
brew "ffmpeg"
brew "glfw"
brew "libarchive"
brew "libusb"
brew "libtool"
brew "llvm"
brew "openssl"
brew "pyenv"
brew "qt@5"
brew "zeromq"
brew "swig"
brew "protobuf"
cask "gcc-arm-embedded"
EOS

if [[ $SHELL == "/bin/zsh" ]]; then
  RC_FILE="$HOME/.zshrc"
elif [[ $SHELL == "/bin/bash" ]]; then
  RC_FILE="$HOME/.bash_profile"
fi

# Build requirements for macOS
# https://github.com/pyenv/pyenv/issues/1740
# https://github.com/pyca/cryptography/blob/main/docs/installation.rst
rustup-init -y

# linker
export LDFLAGS="$LDFLAGS -L/usr/local/opt/zlib/lib -L/opt/homebrew/opt/zlib/lib"
export LDFLAGS="$LDFLAGS -L/usr/local/opt/bzip2/lib -L/opt/homebrew/opt/bzip2/lib"
export LDFLAGS="$LDFLAGS -L/usr/local/opt/openssl@1.1/lib -L/opt/homebrew/opt/openssl@1.1/lib"
export LDFLAGS="$LDFLAGS -L/opt/homebrew/opt/qt@5/lib"

# defs
export CPPFLAGS="$CPPFLAGS -I/usr/local/opt/zlib/include -I/opt/homebrew/opt/zlib/include"
export CPPFLAGS="$CPPFLAGS -I/usr/local/opt/bzip2/include -I/opt/homebrew/opt/bzip2/include"
export CPPFLAGS="$CPPFLAGS -I/usr/local/opt/openssl@1.1/include -I/opt/homebvrew/opt/openssl@1.1/include"
export CPPFLAGS="$CPPFLAGS -I/opt/homebrew/opt/qt@5/include"

# execs
export PATH="$PATH:/usr/local/opt/openssl@1.1/bin"
export PATH="$PATH:/opt/homebrew/opt/qt@5/bin"
export PATH="$PATH:/usr/local/bin"

# OpenPilot environment build variables
if [ -z "$OPENPILOT_ENV" ] && [ -n "$RC_FILE" ] && [ -z "$CI" ]; then
  echo "export PATH=\"\$PATH:$HOME/.cargo/bin\"" >> $RC_FILE
  echo "source $OP_ROOT/tools/openpilot_env.sh" >> $RC_FILE
  export PATH="$PATH:\"\$HOME/.cargo/bin\":\"/opt/homebrew/opt/qt@5/bin:$PATH\""
  source "$OP_ROOT/tools/openpilot_env.sh"
  echo "Added openpilot_env to RC file: $RC_FILE"
fi

# TODO build and install casadi
# install python and depends
PYENV_PYTHON_VERSION=$(cat $OP_ROOT/.python-version)
if [[ $ARCH == "arm64" ]]; then
  PYENV_PYTHON_VERSION=3.9.9
fi
PATH=$HOME/.pyenv/bin:$HOME/.pyenv/shims:$PATH
pyenv install -s ${PYENV_PYTHON_VERSION}
pyenv rehash
eval "$(pyenv init -)"

pip install pipenv==2020.8.13
if [[ $ARCH != "arm64" ]] ; then
  pipenv install --dev --deploy install
else
  pipenv install --dev --deploy --skip-lock
fi

echo
echo "----   FINISH OPENPILOT SETUP   ----"
echo "Configure your active shell env by running:"
echo "source $RC_FILE"
