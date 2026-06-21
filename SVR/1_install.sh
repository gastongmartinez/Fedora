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

# Ajuste Swappiness
su - root <<EOF
        echo -e "vm.swappiness=10\n" >> /etc/sysctl.d/90-sysctl.conf
EOF

# Configuracion DNF
{
    echo 'fastestmirror=1'
    echo 'max_parallel_downloads=10'
} >> /etc/dnf/dnf.conf


############################### Paquetes ################################
PAQUETES=(
    ### Cockpit ###
    'cockpit-sosreport'
    #'cockpit-machines'
    #'cockpit-podman'
    'cockpit-files'

    ### Sistema ###
    'zsh'
    'zsh-autosuggestions'
    'zsh-syntax-highlighting'
    'autojump'
    'autojump-zsh'
    'ShellCheck'
    'mc'
    'lsd'
    'btop'
    'neovim'
)
for PAQ in "${PAQUETES[@]}"; do
    dnf install "$PAQ" -y
done

### DOTNET
read -rp "Instalar .NET? (S/N): " DNET
if [[ $DNET =~ ^[Ss]$ ]]; then
    dnf install dotnet-sdk-10.0 -y
fi

### PostgreSQL
read -rp "Instalar PostgreSQL? (S/N): " DNET
if [[ $DNET =~ ^[Ss]$ ]]; then
    dnf install postgresql-server -y
    postgresql-setup --initdb --unit postgresql
fi

### MS SQL
read -rp "Instalar MS SQL Server? (S/N): " MS
if [[ $MS =~ ^[Ss]$ ]]; then
    curl -o /etc/yum.repos.d/mssql-server.repo https://packages.microsoft.com/config/rhel/10/mssql-server-2025.repo
    dnf install -y mssql-server

    /opt/mssql/bin/mssql-conf setup

    firewall-cmd --zone=public --add-port=1433/tcp --permanent
    firewall-cmd --reload

    curl https://packages.microsoft.com/config/rhel/10/prod.repo | tee /etc/yum.repos.d/mssql-release.repo
    dnf install -y mssql-tools18 unixODBC-devel
fi
