#!/bin/bash
# install-kvm.sh - Instala e configura KVM/QEMU
# script executado via menu/Ferramentas (via acesso root)

# Evita execução múltipla (se o script já estiver rodando)
LOCKFILE="/tmp/"$(basename $0)".lock"
if [ -f "$LOCKFILE" ]; then
    exit 0
fi
touch "$LOCKFILE"

# Desativar a Memória de video Compartilhada
export QT_X11_NO_MITSHM=1

if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

set -euo pipefail
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

PACOTE="qemu-kvm"
if dpkg-query -W -f='${Status}' "$PACOTE" 2>/dev/null | grep -q "install ok installed" && command -v zenity >/dev/null && [ -n "${DISPLAY:-}" ]; then
  echo "O pacote $PACOTE está instalado."
  zenity --info --title="Ambiente de virtualização" --text="O KVM-LINUX está instalado!"
  exit 1
fi

log "Iniciando instalação do KVM/QEMU..."

PACKAGES="qemu-kvm qemu-utils virt-manager virtinst virt-viewer libvirt-daemon-system libvirt-clients libvirt-daemon spice-vdagent spice-webdavd bridge-utils"
apt update -qq
apt install -qq -y $PACKAGES

systemctl enable libvirtd || true
systemctl start libvirtd || true

if [ -n "${SUDO_USER:-}" ]; then
    USERNAME="$SUDO_USER"
elif [ -n "${PKEXEC_UID:-}" ]; then
    USERNAME=$(id -nu "$PKEXEC_UID")
else
    USERNAME=$(logname 2>/dev/null || echo "$USER")
fi

if [ -n "$USERNAME" ] && [ "$USERNAME" != "root" ]; then
    adduser "$USERNAME" libvirt
    log "Usuário $USERNAME adicionado ao grupo libvirt"
fi
rm -f "$LOCKFILE"

log "Instalação concluída. Reinicie a para usar o grupo libvirt."
if command -v zenity >/dev/null && [ -n "${DISPLAY:-}" ]; then
    zenity --info --title="Ambiente de virtualização KVM-LINUX" --text="Instalação concluída com sucesso!\n\nReinicie o computador para que as alterações tenham efeito." --width=400
fi


