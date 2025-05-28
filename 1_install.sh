#!/usr/bin/env bash

# Validacion del usuario ejecutando el script
R_USER=$(id -u)
if [ "$R_USER" -ne 0 ]; then
    echo -e "\nDebe ejecutar este script como root o utilizando sudo.\n"
    exit 1
fi

read -rp "Establecer el password para root? (S/N): " PR
if [[ $PR =~ ^[Ss]$ ]]; then
    passwd root
fi

read -rp "Establecer el nombre del equipo? (S/N): " HN
if [[ $HN =~ ^[Ss]$ ]]; then
    read -rp "Ingrese el nombre del equipo: " EQUIPO
    if [ -n "$EQUIPO" ]; then
        echo -e "$EQUIPO" > /etc/hostname
    fi
fi

systemctl enable sshd

# Ajuste Swappiness
su - root <<EOF
        echo -e "vm.swappiness=10\n" >> /etc/sysctl.d/90-sysctl.conf
EOF

# Configuracion DNF
{
    echo 'fastestmirror=1'
    echo 'max_parallel_downloads=10'
} >> /etc/dnf/dnf.conf

# RPMFusion
dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm -y
dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm -y

# PGAdmin4
rpm -i https://ftp.postgresql.org/pub/pgadmin/pgadmin4/yum/pgadmin4-fedora-repo-2-1.noarch.rpm

# MESA
read -rp "Cambiar drivers de video a MESA Freeworld? (S/N): " MESA
if [[ $MESA =~ ^[Ss]$ ]]; then
    dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
    dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y
fi

# Repositorios VSCode y Powershell 
rpm --import https://packages.microsoft.com/keys/microsoft.asc
sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
curl https://packages.microsoft.com/config/rhel/7/prod.repo | tee /etc/yum.repos.d/microsoft.repo
dnf check-update
dnf makecache

# Brave
sh -c 'echo -e "[brave-browser-rpm-release.s3.brave.com_x86_64_]\nname=created by dnf config-manager from https://brave-browser-rpm-release.s3.brave.com/x86_64/\nbaseurl=https://brave-browser-rpm-release.s3.brave.com/x86_64/\nenabled=1" > /etc/yum.repos.d/brave-browser-rpm-release.s3.brave.com_x86_64_.repo'
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

# Librewolf
curl -fsSL https://repo.librewolf.net/librewolf.repo | pkexec tee /etc/yum.repos.d/librewolf.repo

# Google Chrome
sh -c 'echo -e "[google-chrome]\nname=google-chrome\nbaseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64\nenabled=1\ngpgcheck=1\ngpgkey=https://dl.google.com/linux/linux_signing_key.pub" > /etc/yum.repos.d/google-chrome.repo'

# CORP
dnf copr enable atim/lazygit -y

# MariaDB
dnf remove mariadb-server -y

dnf update -y

USER=$(grep "1000" /etc/passwd | awk -F : '{ print $1 }')

############################### Apps Generales ################################
PAQUETES=(
    #### Powermanagement ####
    'powertop'

    #### WEB ####
    'google-chrome-stable'
    'librewolf'
    'thunderbird'
    'remmina'
    'qbittorrent'
    'brave-browser'

    #### Shells ####
    'zsh'
    'zsh-autosuggestions'
    'zsh-syntax-highlighting'
    'dialog'
    'autojump'
    'autojump-zsh'
    'ShellCheck'
    'powershell'

    #### Archivos ####
    'mc'
    'thunar'
    'vifm'
    'stow'
    'ripgrep'
    'autofs'

    #### Sistema ####
    'tldr'
    'helix'
    'lsd'
    'corectrl'
    'p7zip'
    'unrar'
    'alacritty'
    'kitty'
    'htop'
    'bpytop'
    'neofetch'
    'lshw'
    'lshw-gui'
    'powerline'
    'neovim'
    'python3-neovim'
    'emacs'
    'util-linux-user'
    'flameshot'
    'klavaro'
    'fd-find'
    'fzf'
    'the_silver_searcher'
    'qalculate'
    'calibre'
    'foliate'
    'hunspell-de'
    'pandoc'
    'ulauncher'
    'dnfdragora'
    'stacer'
    'timeshift'
    'setroubleshoot'

    #### Multimedia ####
    'vlc'
    'python-vlc'
    'mpv'
    'HandBrake'
    'HandBrake-gui'
    'audacious'

    #### Juegos ####
    'chromium-bsu'

    #### Redes ####
    'nmap'
    'wireshark'
    'firewall-applet'
    #'gns3-gui'
    #'gns3-server'

    #### Diseño ####
    'gimp'
    'inkscape'
    'krita'
    'blender'

    #### DEV ####
    'git'
    'clang'
    'clang-tools-extra'
    'cmake'
    'meson'
    'python3-pip'
    'filezilla'
    'sbcl'
    'golang'
    'lldb'
    'code'
    'tidy'
    'nodejs'
    'yarnpkg'
    'lazygit'
    'pcre-cpp'
    'httpd'
    'php'
    'php-common'
    'php-gd'
    'php-mysqlnd'
    'dotnet-sdk-8.0'
    'dotnet-sdk-9.0'

    #### Fuentes ####
    'terminus-fonts'
    'fontawesome-fonts'
    'cascadia-code-fonts'
    'texlive-roboto'
    'dejavu-fonts-all'
    'fira-code-fonts'
    'cabextract'
    'xorg-x11-font-utils'
    'texlive-caladea'
    'fontforge'

    ### Bases de datos ###
    'postgresql-server'
    'pgadmin4'
    'postgis'
    'postgis-client'
    'postgis-utils'
    'mysql-server'
    'sqlite'
    'sqlite-analyzer'
    'sqlite-tools'
    'sqlitebrowser'

    ### Cockpit ###
    'cockpit'
    'cockpit-sosreport'
    'cockpit-machines'
    'cockpit-podman'
    'cockpit-selinux'
    'cockpit-navigator'

    ### Virtualizacion ###
    'virt-manager'
    'ebtables-services'
    'bridge-utils'
    'libguestfs'
)
 
for PAQ in "${PAQUETES[@]}"; do
    dnf install "$PAQ" -y
done

#### KDE Apps####
read -rp "Instalar KDE Apps? (S/N): " KAPPS
if [[ $KAPPS =~ ^[Ss]$ ]]; then
    KDEAPPS=(
        'kvantum'
        'kate'
        'kwallet'
        'ksystemlog'
        'ksysguard'
        'kcolorchooser'
        'filelight'
        'yakuake'
        'lokalize'
        'kompare'
        'kruler'
        'sweeper'
        'kalarm'
        'ktouch'
        'knotes'
        'krusader'
        'artikulate'
        'qalculate-qt'
    )

    for PAQ in "${KDEAPPS[@]}"; do
        dnf install "$PAQ" -y
    done
fi

#### Gnome Apps####
read -rp "Instalar GNOME Apps? (S/N): " GAPPS
if [[ $GAPPS =~ ^[Ss]$ ]]; then
    GNAPPS=(
        'gnome-tweaks'
        'gnome-feeds'
        'gnome-extensions-app'
        'gnome-shell-extension-user-theme'
        'gnome-shell-extension-blur-my-shell'
        'gnome-shell-extension-native-window-placement'
        'gnome-shell-extension-dash-to-dock'
        'gnome-shell-extension-no-overview'
        'gnome-shell-extension-caffeine'
        'gnome-commander'
        'file-roller-nautilus'
        'qalculate-gtk'
        'dconf-editor'
    )

    for PAQ in "${GNAPPS[@]}"; do
        dnf install "$PAQ" -y
    done

    sed -i "s/Icon=\/var\/lib\/AccountsService\/icons\/$USER/Icon=\/usr\/share\/backgrounds\/wallpapers\/Fringe\/fibonacci3.jpg/g" "/var/lib/AccountsService/users/$USER"
fi

rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
wget https://corretto.aws/downloads/latest/amazon-corretto-17-x64-linux-jdk.rpm
wget https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.rpm
dnf install amazon-corretto-17-x64-linux-jdk.rpm -y
dnf install amazon-corretto-21-x64-linux-jdk.rpm -y
###############################################################################

############################# Codecs ###########################################
dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel -y
dnf install lame\* --exclude=lame-devel -y
dnf group upgrade --with-optional Multimedia -y
dnf swap ffmpeg-free ffmpeg --allowerasing -y
################################################################################

################################ Wallpapers #####################################
echo -e "\nInstalando wallpapers..."
git clone https://github.com/gastongmartinez/wallpapers.git
mv -f wallpapers/ "/usr/share/backgrounds/"
#################################################################################

############################### GRUB ############################################
git clone https://github.com/vinceliuice/grub2-themes.git
cd grub2-themes || return
./install.sh
cd .. || return
#################################################################################

rm -rf grub2-themes
rm amazon-corretto-17-x64-linux-jdk.rpm
rm amazon-corretto-21-x64-linux-jdk.rpm

usermod -aG libvirt "$USER"
usermod -aG kvm "$USER"

postgresql-setup --initdb --unit postgresql
systemctl enable --now mysqld
systemctl enable --now cockpit.socket
firewall-cmd --add-service=cockpit --permanent
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https --permanent

alternatives --set java /usr/lib/jvm/java-21-amazon-corretto/bin/java
alternatives --set javac /usr/lib/jvm/java-21-amazon-corretto/bin/javac

read -rp "Modificar fstab? (S/N): " FST
if [[ $FST =~ ^[Ss]$ ]]; then
    sed -i 's/subvol=@/compress=zstd,noatime,space_cache=v2,ssd,discard=async,subvol=@/g' "/etc/fstab"
fi

cd /usr/bin || return
ln -s lldb-dap lldb-vscode

sleep 2

reboot
