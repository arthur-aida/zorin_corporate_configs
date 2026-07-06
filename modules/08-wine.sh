#!/bin/bash
# 08-wine.sh - Instalação de Wine
# Usa codinome do Ubuntu base (UBUNTU_CODENAME) para Linux Mint/Zorin/Ubuntu (ver função carrega_repos em main.sh)

set -euo pipefail
source /etc/customization/utils/logging.sh
log_module_start "08-wine"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

check_root

log_info "Iniciando instalação da versão mais recente do Wine..."

# 1. VERIFICAÇÃO DE INSTALAÇÃO PRÉVIA
if command -v wine >/dev/null 2>&1; then
    log_info "✅ Wine já está instalado: $(wine --version 2>/dev/null | head -1)"
    exit 0
fi

# 2. Habilitando suporte 32-bit
log_info "Habilitando suporte 32-bit..."
dpkg --add-architecture i386

# 3. INSTALAÇÃO DOS PACOTES
log_info "Tentando instalar winehq-stable..."

# Proteção antes da instalação principal
wait_for_apt_unlock
if apt install -y --no-install-recommends winehq-stable -qq; then
    log_info "✅ WineHQ Stable instalado com sucesso."
else
    log_warning "⚠️ Falha no winehq-stable. Tentando versão do repositório Ubuntu..."
    wait_for_apt_unlock
    apt install -y --no-install-recommends wine -qq || log_error "❌ Falha crítica na instalação do Wine."
fi
apt install winetricks -y -qq

# 4. CONGELAMENTO DE VERSÃO PARA GARANTIR ESTABILIDADE (Hold)
#  apt-mark hold winehq-stable wine-stable wine-stable-amd64 wine-stable-i386 2>/dev/null || true

log_module_end "08-wine"
