#!/usr/bin/env bash

# written by KOSHIKAWA Kenichi.

# export ENVINIT_DRYRUN="true"
export ENVINIT_ADDITIONAL_PKGS="${ENVINIT_ADDITIONAL_PKGS,neovim,brew:-neovim,brew}"

# dependency check
# shellcheck disable=SC2006,SC2016
command -v uname > /dev/null 2>&1 || echo 'command `uname` not found.'

## macOS
[[ "$(uname -s)" == "Darwin" && -x "$(command -v sw_vers)" ]] && \
  (
    # macOS
    [[ "$ENVINIT_ADDITIONAL_PKGS" == *brew* ]] && \
      (
        [[ ! -x "$(command -v brew)" ]] && \
          NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      )
  )

## Linux (with systemd)
[[ "$(uname -s)" == "Linux" && -f "/etc/os-release" ]] && \
  mkdir -p "$HOME/.cache" "$HOME/.config" && \
  (
    source "/etc/os-release"
    [[ "$ID" == debian || "$ID_LIKE" == *debian* ]] && \
      (
        command -v apt-add-repository > /dev/null 2>&1 && sudo apt-add-repository -y ppa:fish-shell/release-3
        sudo apt-get update -y
        sudo apt-get -y --no-install-recommends --no-install-suggests install \
          etckeeper build-essential curl file git fish tmux manpages-ja{,-dev} ssh-import-id \
          pkg-config devscripts debhelper nodejs wget cmake autoconf automake unzip
        sudo apt-get -y purge nano needrestart
        [[ "$(whoami)" == "reishoku" ]] && ssh-import-id gh:reishoku && sudo chsh -s /usr/bin/fish reishoku
        [[ $(command -v systemctl) && "$(systemctl show | grep Virtualization)" == *kvm ]] && sudo apt-get install -y linux-kvm qemu-guest-agent || true
      ) && \
      (
        mkdir -p /tmp/envinit.d
        pushd /tmp/envinit.d || exit
          [[ "${ENVINIT_ADDITIONAL_PKGS}" == *neovim* || "${ENVINIT_ADDITIONAL_PKGS}" == *nvim* ]] && \
            (
              mkdir -p neovim deno
              pushd neovim || exit
                command -v curl && curl -LOZ --progress-bar "https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb"
                command -v wget && wget -nc "https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb"
                [ -f "nvim-linux64.deb" ] && sudo apt-get install -y ./nvim-linux64.deb
              popd || exit
              pushd deno || exit
                command -v curl && curl -LOZ --progress-bar "https://github.com/denoland/deno/releases/download/v1.28.3/deno-x86_64-unknown-linux-gnu.zip"
                command -v wget && wget -nc "https://github.com/denoland/deno/releases/download/v1.28.3/deno-x86_64-unknown-linux-gnu.zip"
                unzip deno-x86_64-unknown-linux-gnu.zip
                [ -f "deno" ] && sudo mv ./deno /usr/local/bin/
              popd || exit
            )
          [[ "${ENVINIT_ADDITIONAL_PKGS}" == *tailscale* ]] && \
            (
              curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/"${UBUNTU_CODENAME}".noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
              curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/"${UBUNTU_CODENAME}".tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
              sudo apt-get update
              sudo apt-get install -y --no-install-recommends --no-install-suggests tailscale
            )
          [[ "${ENVINIT_ADDITIONAL_PKGS}" == *docker* ]] && \
            (
              sudo apt-get -y remove docker docker-engine docker.io containerd runc
              sudo apt-get update
              sudo apt-get -y install --no-install-recommends --no-install-suggests \
                ca-certificates curl gnupg lsb-release
              sudo mkdir -p /etc/apt/keyrings
              [[ "$NAME" == "Debian GNU/Linux" ]] && \
                (
                  if test ! -f /etc/apt/keyrings/docker.gpg; then
                    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                  fi
                  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                )
              [[ "$NAME" == "Ubuntu" ]] && \
                if test ! -f /etc/apt/keyrings/docker.gpg; then
                  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                fi
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee -a /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt-get update
              sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
              sudo usermod -a -G docker "$(whoami)"
            )
          [[ "${ENVINIT_ADDITIONAL_PKGS}" == *zabbix-agent* ]] && \
            (
              sudo apt-get install -y zabbix-agent
            )
          [[ "${ENVINIT_ADDITIONAL_PKGS}" == *brew* || "${ENVINIT_ADDITIONAL_PKGS}" == *dotfiles* ]] && \
            (
              command -v brew > /dev/null 2>&1 && \
                NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
                echo '# Set PATH, MANPATH, etc., for Homebrew.' >> "${HOME}"/.profile && \
                echo '# Set PATH, MANPATH, etc., for Homebrew.' >> "${HOME}"/.bashrc && \
                # shellcheck disable=SC2016
                echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "${HOME}"/.profile && \
                # shellcheck disable=SC2016
                echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "${HOME}"/.bashrc
              /home/linuxbrew/.linuxbrew/bin/brew install gcc deno tmux vim node coreutils python3 neovim tree-sitter glow fish exa
            )
          [[ "${ENVINIT_ADDITIONAL_PKGS}" == *dotfiles* ]] && \
            (
              pushd "$HOME" || exit
                [[ -d "$HOME/dotfiles" ]] && rm -rf "$HOME/dotfiles"
                git clone --recursive "https://github.com/reishoku/dotfiles.git"
                [[ ! -L "$HOME/.config/nvim" ]] && ln -s "$HOME/dotfiles/.config/nvim" "$HOME/.config/nvim"
                [[ ! -L "$HOME/.tmux.conf" ]] && ln -s "$HOME/dotfiles/.tmux.conf" "$HOME/.tmux.conf"
                [[ ! -L "$HOME/.tmux" ]] && ln -s "$HOME/dotfiles/.tmux" "$HOME/.tmux"
                [[ ! -f "$HOME/.config/fish/config.fish" ]] && mkdir -p "$HOME/.config/fish" && echo "fish_add_path /home/linuxbrew/.linuxbrew/bin" | tee -a "$HOME/.config/fish/config.fish"
                [[ "${SHELL}" == *bash ]] && export PATH="/home/linuxbrew/.linuxbrew/bin":$PATH
                nvim +quit
              popd || exit
            )
        popd || exit
        [ -d "/tmp/envinit.d" ] && rm -rf "/tmp/envinit.d"
      )
    [[ "$ID" == fedora || "$ID_LIKE" == *fedora* || "$ID_LIKE" == *rhel* || "$ID_LIKE" == *centos* ]] && \
      (
        sudo dnf groupinstall -y "Development Tools" "C Development Tools and Libraries"
        sudo dnf install -y curl file git fish tmux cmake
      )
      (
        mkdir -p /tmp/envinit.d
        pushd /tmp/envinit.d || exit
          [[ "${ENVINIT_ADDITIONAL_PKGS}" == *zabbix-agent* ]] && \
            (
              sudo dnf install -y zabbix-agent
            )
          [[ "${ENVINIT_ADDITIONAL_PKGS}" == *brew* ]] && \
            (
              NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
              echo '# Set PATH, MANPATH, etc., for Homebrew.' >> "${HOME}"/.profile
              echo '# Set PATH, MANPATH, etc., for Homebrew.' >> "${HOME}"/.bashrc
              # shellcheck disable=SC2016
              echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "${HOME}"/.profile
              # shellcheck disable=SC2016
              echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "${HOME}"/.bashrc
              eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
              /home/linuxbrew/.linuxbrew/bin/brew install gcc deno tmux vim node coreutils python3 neovim tree-sitter glow fish exa
            )
        popd || exit
        [ -d "/tmp/envinit.d" ] && rm -rf "/tmp/envinit.d"
      )
  )

## FreeBSD
[[ "$(uname -s)" == "FreeBSD" ]]

exit 0
