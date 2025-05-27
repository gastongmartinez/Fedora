#!/usr/bin/env bash

R_USER=$(id -u)
if [ "$R_USER" -eq 0 ]; then
   echo "Este script debe usarse con un usuario regular."
   echo "Saliendo..."
   exit 1
fi

if [ -z "$DISPLAY" ]; then
    echo -e "Debe ejecutarse dentro del entorno grafico.\n"
    echo "Saliendo..."
    exit 2
fi

DIRE=$(pwd)
# Arc Menu
git clone https://gitlab.com/arcmenu/ArcMenu.git
cd ArcMenu || return
make install
cd "$DIRE" || return
rm -rf ArcMenu

# Vitals
git clone https://github.com/corecoding/Vitals.git ~/.local/share/gnome-shell/extensions/Vitals@CoreCoding.com

# Systemd Manager
git clone https://github.com/hardpixel/systemd-manager.git
cd systemd-manager || return
mv ./systemd-manager@hardpixel.eu ~/.local/share/gnome-shell/extensions/systemd-manager@hardpixel.eu
cd "$DIRE" || return
rm -rf systemd-manager

# Tiling assistant
git clone https://github.com/Leleat/Tiling-Assistant.git
cd Tiling-Assistant/scripts || return
chmod +x build.sh
./build.sh -i
cd "$DIRE" || return
rm -rf Tiling-Assistant

# Removable Drive
git clone https://gitlab.gnome.org/GNOME/gnome-shell-extensions.git
cd gnome-shell-extensions || return
meson build
ninja -C build install
cd "$DIRE" || return
rm -rf gnome-shell-extensions

flatpak --user install flathub com.mattjakeman.ExtensionManager -y

sleep 2

reboot