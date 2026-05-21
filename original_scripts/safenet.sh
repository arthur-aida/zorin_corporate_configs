#!/bin/bash
# safenet.sh - Instala drivers para tokens Aladdin e Safenet 5100/5110
# Corrigido: resolve caminho real do script para carregar common.sh

# ----------------------------------------------------------------------
# Resolução robusta do diretório do script (segue links simbólicos)
# ----------------------------------------------------------------------
SCRIPT_REAL=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_REAL")" && pwd)"

# Carrega funções comuns (download_with_cache, log_info, etc.)
if [ -f "$SCRIPT_DIR/../utils/common.sh" ]; then
    source "$SCRIPT_DIR/../utils/common.sh"
else
    echo "ERRO: Não foi possível carregar common.sh" >&2
    exit 1
fi

# ----------------------------------------------------------------------
# Detecta a distribuição para escolher o pacote correto
# ----------------------------------------------------------------------
. /etc/os-release
VSO="$VERSION_CODENAME"

if [ ! -f /usr/bin/SACMonitor ]; then
    cd /tmp

    # Dependências básicas (já podem ter sido instaladas pelo 02‑bulk‑packages)
    apt-get install -y -qq openpace libaec-dev zlib1g-dev
    apt-get install -y -qq pcscd libccid libjbig0 libpcsclite1 opensc-pkcs11

    # ------------------------------------------------------------------
    # Distribuições baseadas em Ubuntu 18.04 / 20.04 / Debian 11
    # ------------------------------------------------------------------
    if [ "$VSO" = "bionic" ] || [ "$VSO" = "focal" ] || [ "$VSO" = "bullseye" ] || \
       [ "$VSO" = "una" ] || [ "$VSO" = "elsie" ]; then
        URL="https://www.globalsign.com/en/safenet-drivers/USB/10.8/Safenet-Ubuntu-2004.zip"
        ZIP_DEST="/tmp/Safenet-Ubuntu-2004.zip"
        CACHE_ZIP="/tmp/cache/Safenet-Ubuntu-2004.zip"

        if [ -f "$CACHE_ZIP" ]; then
            if [ -f "$ZIP_DEST" ] && [ $(stat -c%s "$ZIP_DEST" 2>/dev/null || echo 0) -eq $(stat -c%s "$CACHE_ZIP" 2>/dev/null || echo -1) ]; then
                log_info "✅ ZIP Safenet já presente e idêntico ao cache."
            else
                cp "$CACHE_ZIP" "$ZIP_DEST"
                log_info "✅ ZIP Safenet copiado do cache NFS"
            fi
            unzip -o "$ZIP_DEST" -d /tmp/
            dpkg -i /tmp/Ubuntu-2004/safenetauthenticationclient_*.deb
        else
            log_warning "Cache Safenet não encontrado, baixando..."
            download_with_cache "$URL" "$ZIP_DEST" || exit 1
            unzip -o "$ZIP_DEST" -d /tmp/
            dpkg -i /tmp/Ubuntu-2004/safenetauthenticationclient_*.deb
        fi
    fi

    # ------------------------------------------------------------------
    # Distribuições baseadas em Ubuntu 22.04 / Debian 12 / Mint 21.x
    # ------------------------------------------------------------------
    if [ "$VSO" = "jammy" ] || [ "$VSO" = "victoria" ] || [ "$VSO" = "faye" ] || \
       [ "$VSO" = "bookworm" ] || [ "$VSO" = "virginia" ]; then
        # O bloco estava vazio no original; mantemos a estrutura para futuras versões
        :
    fi

    # ------------------------------------------------------------------
    # Distribuições modernas: Ubuntu 24.04, Zorin 17, Mint 22.x etc.
    # ------------------------------------------------------------------
    if [ "$VSO" = "noble" ] || [ "$VSO" = "wilma" ] || [ "$VSO" = "xia" ] || \
       [ "$VSO" = "zara" ] || [ "$VSO" = "zena" ]; then
        URL="https://www.digicert.com/StaticFiles/Linux_SAC_10.9_GA.zip"
        ZIP_DEST="/tmp/Linux_SAC_10.9_GA.zip"
        CACHE_ZIP="/tmp/cache/Linux_SAC_10.9_GA.zip"

        if [ -f "$CACHE_ZIP" ]; then
            if [ -f "$ZIP_DEST" ] && [ $(stat -c%s "$ZIP_DEST" 2>/dev/null || echo 0) -eq $(stat -c%s "$CACHE_ZIP" 2>/dev/null || echo -1) ]; then
                log_info "✅ ZIP Safenet 10.9 já presente e idêntico ao cache."
            else
                cp "$CACHE_ZIP" "$ZIP_DEST"
                log_info "✅ ZIP Safenet 10.9 copiado do cache NFS"
            fi
            unzip -o "$ZIP_DEST" -d /tmp/
            dpkg -i '/tmp/SAC_10.9 GA/Installation/Standard/Ubuntu-2204/safenetauthenticationclient_10.9.4723_amd64.deb'
        else
            log_warning "Cache Safenet 10.9 não encontrado, baixando..."
            download_with_cache "$URL" "$ZIP_DEST" || exit 1
            unzip -o "$ZIP_DEST" -d /tmp/
            dpkg -i '/tmp/SAC_10.9 GA/Installation/Standard/Ubuntu-2204/safenetauthenticationclient_10.9.4723_amd64.deb'
        fi
    fi

    # Fallback para distribuições não listadas (tenta a versão 10.9)
    if [ -z "${VSO+x}" ] || [ "$VSO" = "" ]; then
        log_warning "Distribuição desconhecida. Tentando Safenet 10.9..."
        # (mesmo bloco do noble)
    fi
fi
