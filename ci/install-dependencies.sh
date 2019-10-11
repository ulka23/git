#!/usr/bin/env bash
#
# Install dependencies required to build and test Git on Linux and macOS
#

set -x
set -e

export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1
brew install caskroom/cask/perforce

p4d -V
p4 -V
