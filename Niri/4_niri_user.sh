#!/usr/bin/env bash

R_USER=$(id -u)
if [ "$R_USER" -eq 0 ]; then
   echo "Este script debe usarse con un usuario regular."
   echo "Saliendo..."
   exit 1
fi

# Instalacion noctalia-shell
#mkdir -p ~/.config/quickshell/noctalia-shell
#curl -sL https://github.com/noctalia-dev/noctalia-shell/releases/latest/download/noctalia-latest.tar.gz | tar -xz --strip-components=1 -C ~/.config/quickshell/noctalia-shell

# Servicios de usuario
systemctl --user enable --now dsearch
systemctl --user add-wants niri.service dms

# Deshabilita MATUGEN
echo 'export DMS_DISABLE_MATUGEN=1' >> ~/.zshrc

# Inicializa firefox
firefox

# Niri Config
if [ ! -d ~/.config/niri ]; then
    mkdir -p ~/.config/niri
fi
cp config.kdl ~/.config/niri/

