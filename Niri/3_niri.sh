#!/usr/bin/env bash

# Validacion del usuario ejecutando el script
R_USER=$(id -u)
if [ "$R_USER" -ne 0 ]; then
    echo -e "\nDebe ejecutar este script como root o utilizando sudo.\n"
    exit 1
fi

# Extra Repos
dnf copr enable avengemedia/dms -y
dnf copr enable brycensranch/gpu-screen-recorder-git -y
dnf copr enable avengemedia/danklinux -y

# Instalación Niri & DankMaterialShell
dnf install niri dms -y

# Dependencias Noctalia Shell
#dnf install ddcutil -y
#dnf install brightnessctl -y
#dnf install gpu-screen-recorder-ui -y
#dnf install wlsunset -y
#dnf install evolution-data-server -y
