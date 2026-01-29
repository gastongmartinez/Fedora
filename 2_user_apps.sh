#!/usr/bin/env bash

R_USER=$(id -u)
if [ "$R_USER" -eq 0 ]; then
   echo "Este script debe usarse con un usuario regular."
   echo "Saliendo..."
   exit 1
fi

if [ ! -d ~/Apps ]; then
    mkdir ~/Apps
fi

# NerdFonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
unzip JetBrainsMono.zip -d ~/.local/share/fonts
fc-cache -f -v
rm JetBrainsMono.zip

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
if [ ! -d ~/.local/bin ]; then
    mkdir -p ~/.local/bin
fi
export PATH="$HOME/.cargo/bin:$PATH"

# Flatpak
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak --user install flathub io.github.shiftey.Desktop -y
flatpak --user install flathub net.ankiweb.Anki -y
flatpak --user install flathub com.github.tchx84.Flatseal -y
flatpak --user install flathub com.axosoft.GitKraken -y
flatpak --user install flathub io.podman_desktop.PodmanDesktop -y
flatpak --user install flathub org.libretro.RetroArch -y
flatpak --user install flathub io.dbeaver.DBeaverCommunity -y

# Doom Emacs
read -rp "Instalar Doom Emacs? (S/N): " DOOM
if [[ $DOOM =~ ^[Ss]$ ]]; then
    if [ -d ~/.emacs.d ]; then
        rm -Rf ~/.emacs.d
    fi
    go install github.com/fatih/gomodifytags@latest
    go install github.com/cweill/gotests/...@latest
    go install github.com/x-motemen/gore/cmd/gore@latest
    go install golang.org/x/tools/cmd/guru@latest
    pip install nose
    git clone --depth 1 https://github.com/hlissner/doom-emacs ~/.emacs.d
    ~/.emacs.d/bin/doom install
    sleep 5
    rm -rf ~/.doom.d
fi

# Tmux Plugin Manager
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Anaconda
read -rp "Instalar Anaconda3? (S/N): " ANA
if [[ $ANA =~ ^[Ss]$ ]]; then
    wget https://repo.anaconda.com/archive/Anaconda3-2025.06-0-Linux-x86_64.sh
    chmod +x Anaconda3-2025.06-0-Linux-x86_64.sh
    ./Anaconda3-2025.06-0-Linux-x86_64.sh
    rm Anaconda3-2025.06-0-Linux-x86_64.sh
fi

# Bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
sed -i 's/"font"/"powerline"/g' "$HOME/.bashrc"

# Autostart Apps
if [ ! -d ~/.config/autostart ]; then
    mkdir -p ~/.config/autostart
fi
cp /usr/share/applications/ulauncher.desktop ~/.config/autostart/

# Tema Ulauncher
mkdir -p ~/.config/ulauncher/user-themes
git clone https://github.com/Raayib/WhiteSur-Dark-ulauncher.git ~/.config/ulauncher/user-themes/WhiteSur-Dark-ulauncher

# Iconos WhiteSur Grey
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme || return
./install.sh -t grey
cd ..
rm -rf WhiteSur-icon-theme

# ZSH
if [ ! -d ~/.local/share/zsh ]; then
    mkdir -p ~/.local/share/zsh
fi
touch ~/.zshrc
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.local/share/zsh/powerlevel10k
chsh -s /usr/bin/zsh

# LSPs, Linters. tools, etc
go install golang.org/x/tools/gopls@latest
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/go-delve/delve/cmd/dlv@latest
pip install black 'python-lsp-server[all]' pyright yamllint autopep8

rustup component add rust-analyzer

wget https://github.com/tamasfe/taplo/releases/download/0.10.0/taplo-linux-x86_64.gz
gunzip taplo-linux-x86_64.gz
chmod +x taplo-linux-x86_64
mv taplo-linux-x86_64 "$HOME/.local/bin/taplo"

wget https://github.com/JohnnyMorganz/StyLua/releases/download/v2.3.1/stylua-linux-x86_64.zip
unzip stylua-linux-x86_64.zip -d "$HOME/.local/bin/"
rm stylua-linux-x86_64.zip

wget https://github.com/artempyanykh/marksman/releases/download/2024-12-18/marksman-linux-x64
mv marksman-linux-x64 marksman
chmod +x marksman
mv marksman "$HOME/.local/bin/"

sudo npm install -g neovim prettier bash-language-server vscode-langservers-extracted emmet-ls typescript typescript-language-server yaml-language-server live-server markdownlint markdownlint-cli dockerfile-language-server-nodejs stylelint js-beautify

# ZelliJ
wget https://github.com/zellij-org/zellij/releases/download/v0.43.1/zellij-x86_64-unknown-linux-musl.tar.gz
tar -xvf zellij*.tar.gz
chmod +x zellij
rm zellij-x86_64-unknown-linux-musl.tar.gz
mv zellij "$HOME/.local/bin/"

# Atuin
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

# LazyVim
read -rp "Instalar LazyVim? (S/N): " LVIM
if [[ $LVIM =~ ^[Ss]$ ]]; then
    git clone https://github.com/LazyVim/starter ~/.config/lnv
    rm -rf ~/.config/lnv/.git
    echo 'alias lnv="NVIM_APPNAME=lnv nvim"' >> ~/.zshrc
fi

# Zed Editor
curl -f https://zed.dev/install.sh | sh

# Inicializacion MySQL
sudo mysql_secure_installation

sleep 5

reboot

