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

# 1. VERIFICAÇÃO DE INSTALAÇÃO PRÉVIA
if command -v wine >/dev/null 2>&1; then
    log_info "✅ Wine já está instalado: $(wine --version 2>/dev/null | head -1)"
    exit 0
fi

# 2. INTELIGÊNCIA DE ROAMING (Detecção de Cache)
WINE_PROTO="https"
if [ -f "/etc/acngonoff.sh" ]; then
    log_info "Avaliando infraestrutura de rede para otimização de download..."
    if bash "/etc/acngonoff.sh"; then
        [ -f /tmp/acng_env ] && source /tmp/acng_env
        WINE_PROTO="https"
        log_info "🚀 Cache detectado ($PROXY_URL). Usando HTTP para permitir Mapeamento Direto."
    else
        log_info "🏠 Rede doméstica ou sem cache detectada. Usando HTTPS direto."
    fi
fi

# 3. PREPARAÇÃO DE REPOSITÓRIO (WineHQ)
WINE_KEYRING="/usr/share/keyrings/winehq.gpg"
WINE_SOURCE="/etc/apt/sources.list.d/winehq.list"

if [ ! -f "$WINE_KEYRING" ]; then
    log_info "Baixando chave GPG do WineHQ..."
    mkdir -p "$(dirname "$WINE_KEYRING")"
    TEMP_KEY="/tmp/winehq.key"
    # O download_with_cache já utiliza a lógica de proxy se disponível no common.sh
    if download_with_cache "https://dl.winehq.org/wine-builds/winehq.key" "$TEMP_KEY"; then
        gpg --dearmor -o "$WINE_KEYRING" < "$TEMP_KEY" 2>/dev/null
        log_info "✅ Chave GPG do WineHQ instalada"
    fi
fi

# ─── Detecção correta do codinome do Ubuntu (inclusive para Linux Mint) ───
if [ -f /etc/os-release ]; then
    # Tenta obter a variável UBUNTU_CODENAME (presente no Mint e derivados)
    UBUNTU_CODENAME=$(grep -oP '^UBUNTU_CODENAME=\K.*' /etc/os-release 2>/dev/null || true)
fi

# Se a variável não existir, usa lsb_release (Ubuntu/Debian padrão)
if [ -z "$UBUNTU_CODENAME" ]; then
    UBUNTU_CODENAME=$(lsb_release -sc 2>/dev/null || echo "noble")
fi
log_info "Codinome Ubuntu base detectado: $UBUNTU_CODENAME"

# Adiciona o repositório com o protocolo dinâmico (Roaming) e o codinome correto
if [ ! -f "$WINE_SOURCE" ]; then
    echo "deb [signed-by=$WINE_KEYRING] ${WINE_PROTO}://dl.winehq.org/wine-builds/ubuntu/ $UBUNTU_CODENAME main" | tee "$WINE_SOURCE" >/dev/null
    log_info "Repositório WineHQ adicionado (${WINE_PROTO})."
    # Não é mais necessário o ajuste de codinome para Mint, pois já está correto.
fi

# 4. MAPEAMENTO DIRETO E ATUALIZAÇÃO
log_info "Habilitando suporte 32-bit..."
dpkg --add-architecture i386

# Se estivermos em modo cache, convertemos as fontes antes do update para garantir roaming
if [ "$WINE_PROTO" = "http" ] && [ -f "$SCRIPT_DIR/../scripts/convert-sources-to-proxy.sh" ]; then
    log_info "Aplicando conversão de fontes para Mapeamento Direto..."
    bash "$SCRIPT_DIR/../scripts/convert-sources-to-proxy.sh"
fi

# Proteção contra lock do dpkg
wait_for_apt_unlock
apt update -qq

# 5. INSTALAÇÃO DOS PACOTES
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

# Proteção antes da instalação do winetricks
wait_for_apt_unlock
apt install winetricks -y -qq

# 6. CONGELAMENTO DE VERSÃO PARA GARANTIR ESTABILIDADE (Hold)
apt-mark hold winehq-stable wine-stable wine-stable-amd64 wine-stable-i386 2>/dev/null || true

log_module_end "08-wine"
