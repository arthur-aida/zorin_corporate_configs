#!/bin/bash
# 08-wine.sh - Instalação de Wine com Roaming e Mapeamento Direto
# Revisado para integração com acngonoff.sh Multi-Perfil
# Usa codinome do Ubuntu base (UBUNTU_CODENAME) para Linux Mint/Zorin
set -euo pipefail
source /etc/customization/utils/logging.sh
log_module_start "08-wine"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

check_root

log_info "Iniciando instalação da versão mais recente do Wine..."

# =============================================================================
# 1. DETECÇÃO DE PROXY E DEFINIÇÃO DO PROTOCOLO (sempre executado)
# =============================================================================
WINE_PROTO="https"
if [ -f "/etc/acngonoff.sh" ]; then
    log_info "Avaliando infraestrutura de rede para otimização de download..."
    if bash "/etc/acngonoff.sh"; then
        [ -f /tmp/acng_env ] && source /tmp/acng_env
        WINE_PROTO="http"
        log_info "🚀 Cache detectado ($PROXY_URL). Usando HTTP para permitir Mapeamento Direto."
    else
        log_info "🏠 Rede doméstica ou sem cache detectada. Usando HTTPS direto."
    fi
fi

# =============================================================================
# 2. GARANTIR QUE O ARQUIVO DO REPOSITÓRIO ESTEJA COM O PROTOCOLO CORRETO
#    (independentemente de o Wine já estar instalado)
# =============================================================================
WINE_KEYRING="/usr/share/keyrings/winehq.gpg"
WINE_SOURCE="/etc/apt/sources.list.d/winehq.list"

# Detecta o codinome do Ubuntu (necessário para o repositório)
if [ -f /etc/os-release ]; then
    UBUNTU_CODENAME=$(grep -oP '^UBUNTU_CODENAME=\K.*' /etc/os-release 2>/dev/null || true)
fi
if [ -z "$UBUNTU_CODENAME" ]; then
    UBUNTU_CODENAME=$(lsb_release -sc 2>/dev/null || echo "noble")
fi
log_info "Codinome Ubuntu base detectado: $UBUNTU_CODENAME"

# Sobrescreve o arquivo com o protocolo atual (sempre)
echo "deb [signed-by=$WINE_KEYRING] ${WINE_PROTO}://dl.winehq.org/wine-builds/ubuntu/ $UBUNTU_CODENAME main" | tee "$WINE_SOURCE" >/dev/null
log_info "Repositório WineHQ atualizado com protocolo ${WINE_PROTO}."

# =============================================================================
# 3. VERIFICAÇÃO DE INSTALAÇÃO PRÉVIA (agora após a atualização do arquivo)
# =============================================================================
if command -v wine >/dev/null 2>&1; then
    log_info "✅ Wine já está instalado: $(wine --version 2>/dev/null | head -1)"
    log_module_end "08-wine"
    exit 0
fi

# =============================================================================
# 4. PREPARAÇÃO DA CHAVE GPG (se não existir)
# =============================================================================
if [ ! -f "$WINE_KEYRING" ]; then
    log_info "Baixando chave GPG do WineHQ..."
    mkdir -p "$(dirname "$WINE_KEYRING")"
    TEMP_KEY="/tmp/winehq.key"
    if download_with_cache "https://dl.winehq.org/wine-builds/winehq.key" "$TEMP_KEY"; then
        gpg --dearmor -o "$WINE_KEYRING" < "$TEMP_KEY" 2>/dev/null
        log_info "✅ Chave GPG do WineHQ instalada"
    fi
fi

# =============================================================================
# 5. MAPEAMENTO DIRETO E ATUALIZAÇÃO (se proxy ativo)
# =============================================================================
log_info "Habilitando suporte 32-bit..."
dpkg --add-architecture i386

if [ "$WINE_PROTO" = "http" ] && [ -f "$SCRIPT_DIR/../scripts/convert-sources-to-proxy.sh" ]; then
    log_info "Aplicando conversão de fontes para Mapeamento Direto..."
    bash "$SCRIPT_DIR/../scripts/convert-sources-to-proxy.sh"
fi

wait_for_apt_unlock
apt update -qq

# =============================================================================
# 6. INSTALAÇÃO DOS PACOTES
# =============================================================================
log_info "Tentando instalar winehq-stable..."
wait_for_apt_unlock
if apt install -y --no-install-recommends winehq-stable -qq; then
    log_info "✅ WineHQ Stable instalado com sucesso."
else
    log_warning "⚠️ Falha no winehq-stable. Tentando versão do repositório Ubuntu..."
    wait_for_apt_unlock
    apt install -y --no-install-recommends wine -qq || log_error "❌ Falha crítica na instalação do Wine."
fi

wait_for_apt_unlock
apt install winetricks -y -qq

# =============================================================================
# 7. CONGELAMENTO DE VERSÃO
# =============================================================================
apt-mark hold winehq-stable wine-stable wine-stable-amd64 wine-stable-i386 2>/dev/null || true

log_module_end "08-wine"
