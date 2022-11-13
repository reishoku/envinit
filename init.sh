#!/usr/bin/env bash

set -eux pipefail

export ENVINIT_DRYRUN="true"

# dependency check
command -v uname || echo "command `uname` not found."

## macOS
[[ "$(uname -s)" == "Darwin" && test -x "sw_vers" ]]
## Linux
[[ "$(uname -s)" == "Linux" && test -f "/etc/os-release" ]] && \
  (
    source "/etc/os-release"
    [[ "$ID_LIKE" == "*debian*" ]] && \
      (
        sudo apt-get -y --no-install-recommends --no-install-suggests \
          build-essential curl file git fish tmux manpages-ja{,-dev}
      ) && \
      (
        mkdir -p /tmp/envinit.d
        pushd /tmp/envinit.d
          command -v wget && wget -q "https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb"
          command -v curl && curl -sLO "https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb"
          [[ -f "nvim-linux64.deb" ]] && sudo apt-get install -y ./nvim-linux64.deb
        popd
        [[ -d "/tmp/envinit.d" ]] && rm -rf "/tmp/envinit.d"
      )
    [[ "$ID_LIKE" == "*fedora*" ]] && \
      sudo dnf groupinstall -y \
        "Developer Tools" curl file git fish tmux
  )

## FreeBSD
[[ "$(uname -s)" == "FreeBSD" ]]
