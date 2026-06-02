#!/bin/bash
# -------------------------------------------------------------------------------
# 02‑bulk‑packages.sh – Instalação consolidada de todos os pacotes APT
#
# Unifica as instalações dos módulos. 
# Centraliza dpkg‑i386 e apt update em uma única transação,
# reduzindo a contenção de I/O e o tempo total da customização.
#
#   - Detecção de ambiente (GNOME/XFCE) para escolha do visualizador de imagens
#   - Configuração do Java 8 como padrão e JAVA_HOME
#
# PROTEÇÃO ADICIONADA:
#   - wait_for_apt_unlock antes de cada operação apt (necessário em ambientes sem cache)
# -------------------------------------------------------------------------------
set -euo pipefail
source /etc/customization/utils/logging.sh
source /etc/customization/utils/common.sh
log_module_start "02‑bulk‑packages"

check_root

log_info "========================================="
log_info " Instalação massiva de pacotes APT"
log_info "========================================="

# 1. Prepara arquitetura i386 (uma única vez)
log_info "Adicionando arquitetura i386..."
dpkg --add-architecture i386

# 2. Atualiza as listas de pacotes (já via proxy se cache detectado)
log_info "Atualizando listas de pacotes..."
wait_for_apt_unlock
apt update -qq

# 3. Lista completa de pacotes comuns a todos os perfis
#    (agrupa tudo o que era instalado separadamente)
COMMON_PKGS="
    unrar rar unace p7zip p7zip-full python3-pyudev flatpak net-tools curl wget git gpg gnupg2
    software-properties-common gparted hardinfo meld recoll pdfsam git python3-pip openssh-server
    sshfs gsmartcontrol smart-notifier adb ideviceinstaller libimobiledevice-utils ifuse usbmuxd
    uxplay printer-driver-cups-pdf python3-smbc seahorse grub2-common grub-pc-bin
    libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-shape0
    libxcb-sync1 libxcb-xfixes0 libxcb-xinerama0 libxcb-xkb1 libxkbcommon-x11-0 libxcb-util1
    libxcb-cursor0 libxcb-xinput0 libxcb-composite0 libgles2 libgles2-mesa-dev
    vlc hplip hplip-gui cups cups-pdf gscan2pdf simple-scan tesseract-ocr tesseract-ocr-por
    curl libnss3-tools 
    pcscd libccid libpcsclite1 opensc pcsc-tools gnupg2 debsigs
    xterm openjdk-8-jre-headless openjdk-11-jre-headless icedtea-netx
    unzip cabextract fuseiso
    libwxbase3.2-1t64 libwxgtk3.2-1t64
    eog
"

# 4. Se estivermos num ambiente XFCE, substitui eog por ristretto
if [ -f /usr/bin/xfce4-session ]; then
    log_info "Ambiente XFCE detectado – substituindo eog por ristretto."
    COMMON_PKGS=$(echo "$COMMON_PKGS" | sed 's/\beog\b/ristretto/')
fi

# 5. Instalação massiva
log_info "Instalando pacotes (isso pode levar alguns minutos)..."

# Proteção absoluta antes da operação principal
wait_for_apt_unlock

if apt install -y -qq $COMMON_PKGS; then
    log_info "✅ Pacotes instalados com sucesso."
else
    log_warning "⚠️ Alguns pacotes podem não ter sido instalados. Tentando corrigir..."
    wait_for_apt_unlock
    apt --fix-broken install -y -qq
fi

# 6. Pós-instalação: Java 8 como padrão (herdado de 13‑extra‑packages)
log_info "Configurando Java 8 como padrão..."
if update-alternatives --list java 2>/dev/null | grep -q java-8; then
    update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
    log_info "Java 8 definido como padrão."
else
    log_info "ℹ️ Java 8 não encontrado; mantendo versão atual."
fi

if ! grep -q "JAVA_HOME" /etc/environment 2>/dev/null; then
    echo "JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/environment
    log_info "✅ JAVA_HOME configurado."
fi

log_info "✅ Instalação massiva concluída com sucesso."
log_module_end "02‑bulk‑packages"
