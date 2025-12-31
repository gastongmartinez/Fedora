#!/usr/bin/env bash

# Establece tema de iconos
dconf write /org/gnome/desktop/interface/icon-theme "'WhiteSur-grey'"

# Cursores WhiteSur
read -rp "Instalar WhiteSur Cursors? (S/N): " CUR
if [[ $CUR =~ ^[Ss]$ ]]; then
   git clone https://github.com/vinceliuice/WhiteSur-cursors.git
   cd WhiteSur-cursors || return
   ./install.sh
   cd ..
   rm -rf WhiteSur-cursors

   dconf write /org/gnome/desktop/interface/cursor-theme "'WhiteSur-cursors'"
fi

# Tema WhiteSur GTK
read -rp "Instalar WhiteSur GTK? (S/N): " GTK
if [[ $GTK =~ ^[Ss]$ ]]; then
   pkill firefox
   git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1
   cd WhiteSur-gtk-theme || return
   ./install.sh -l -N glassy --shell -i fedora
   ./tweaks.sh -f
   ./tweaks.sh -F
   sudo flatpak override --filesystem=xdg-config/gtk-4.0
   if [ ! -d ~/.themes ]; then
       mkdir -p ~/.themes
       tar -xf ./release/WhiteSur-Dark.tar.xz -C ~/.themes/
   fi
   cd ..
   rm -rf WhiteSur-gtk-theme

   dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
   dconf write /org/gnome/desktop/interface/gtk-theme "'WhiteSur-Dark'"
   dconf write /org/gnome/shell/extensions/user-theme/name "'WhiteSur-Dark'"
fi

# Tema WhiteSur KDE
read -rp "Instalar WhiteSur KDE? (S/N): " KDE
if [[ $KDE =~ ^[Ss]$ ]]; then
   git clone https://github.com/vinceliuice/WhiteSur-kde.git
   cd WhiteSur-kde || return
   ./install.sh
   read -rp "Instalar Tema WhiteSur SDDM? (S/N): " SDDM
   if [[ $SDDM =~ ^[Ss]$ ]]; then
      cd sddm || return
      sudo ./install.sh
      # necesita plasmashell
   fi
   cd ../..
   rm -rf WhiteSur-kde
fi

