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

# MESA
read -rp "Cambiar drivers de video a MESA Freeworld? (S/N): " MESA
if [[ $MESA =~ ^[Ss]$ ]]; then
    dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
    dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y
fi

# Repositorios VSCode y Powershell 
rpm --import https://packages.microsoft.com/keys/microsoft.asc
sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null'
curl -sSL -O https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm
rpm -i packages-microsoft-prod.rpm
rm packages-microsoft-prod.rpm
dnf check-update
dnf makecache

# Brave
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

# Librewolf
rpm --import https://rpm.librewolf.net/pubkey.gpg
curl -fsSL https://repo.librewolf.net/librewolf.repo | pkexec tee /etc/yum.repos.d/librewolf.repo

# Google Chrome
dnf config-manager setopt google-chrome.enabled=1

# PGAdmin
# rpm -i https://ftp.postgresql.org/pub/pgadmin/pgadmin4/yum/pgadmin4-fedora-repo-2-1.noarch.rpm

# CORP
dnf copr enable atim/lazygit -y

# MariaDB a MySQL
dnf remove mariadb-server -y
dnf install mysql-server --allowerasing -y

dnf update -y

USER=$(grep "1000" /etc/passwd | awk -F : '{ print $1 }')

############################# Codecs ###########################################
dnf install libavcodec-freeworld -y
dnf group install multimedia -y
dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel -y
dnf swap ffmpeg-free ffmpeg --allowerasing -y
################################################################################

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
    'lshw'
    'lshw-gui'
    'powerline'
    'neovim'
    'python3-neovim'
    'emacs'
    'scribus'
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
    'solaar'
    'splix'

    #### Multimedia ####
    'vlc'
    'python-vlc'
    'mpv'
    'HandBrake'
    'HandBrake-gui'
    'audacious'
    'clipgrab'

    #### Juegos ####
    'chromium-bsu'

    #### Redes ####
    'nmap'
    'wireshark'
    'firewall-applet'
    'NetworkManager-tui'
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
    'filezilla'
    'sbcl'
    'golang'
    'lldb'
    'code'
    'tidy'
    'yarnpkg'
    'lazygit'
    'pcre-cpp'
    'httpd'
    'php'
    'php-gd'
    'php-mysqlnd'
    'dotnet-sdk-10.0'

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
    'postgis'
    'postgis-client'
    'postgis-utils'
    #'pgadmin4'
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
        'kcolorchooser'
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

dnf install https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm -y
dnf install https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.rpm -y
dnf install https://download.oracle.com/java/25/latest/jdk-25_linux-x64_bin.rpm -y
dnf install https://download2.gluonhq.com/scenebuilder/25.0.0/install/linux/SceneBuilder-25.0.0.rpm -y
dnf install https://download.oracle.com/otn_software/java/sqldeveloper/sqldeveloper-24.3.1-347.1826.noarch.rpm -y
dnf install https://download.oracle.com/otn_software/java/sqldeveloper/datamodeler-24.3.1.351.0831-1.noarch.rpm -y
###############################################################################

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
