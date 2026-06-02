#!/bin/bash
# =============================================================================
# tokenGD.sh - Instala drivers para Token G&D SafeSign (todas as distribuições)
# Utiliza download com cache (NFS ou local) e fallback para internet.
# Mantém a compatibilidade com Ubuntu 18.04 a 24.04 e derivados.
# =============================================================================

set -euo pipefail

# ------------------------------------------------------------------
# 1. Carregamento de ambiente e funções comuns
# ------------------------------------------------------------------
if [ -f /etc/customization/utils/common.sh ]; then
    source /etc/customization/utils/common.sh
else
    download_with_cache() {
        local url="$1" output="$2"
        if [ -f "/tmp/cache/$(basename "$url")" ]; then
            cp "/tmp/cache/$(basename "$url")" "$output"
        else
            wget --timeout=30 --tries=3 -q --show-progress -O "$output" "$url"
        fi
    }
    log_info()  { echo "[INFO]  $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
    log_warn()  { echo "[WARN]  $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }
    log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }
fi

# ------------------------------------------------------------------
# 2. Carrega variáveis do sistema operacional e perfil de rede
# ------------------------------------------------------------------
. /etc/os-release
[ -f /etc/om.ips ] && . /etc/om.ips

VSO="$VERSION_CODENAME"
PACOTE_NOME="safesignidentityclient"

if dpkg --get-selections 2>/dev/null | grep -q "^${PACOTE_NOME}"; then
    log_info "Token G&D SafeSign já está instalado. Nada a fazer."
    exit 0
fi

log_info "Instalação do Token G&D SafeSign iniciada."
cd /tmp

# =============================================================================
# BLOCO POR DISTRIBUIÇÃO (usando download_with_cache)
# =============================================================================

if [ "$VSO" = "bionic" ]; then
    log_info "Distribuição bionic detectada."
    download_with_cache "http://ftp.br.debian.org/debian/pool/main/libp/libpng/libpng12-0_1.2.50-2+deb8u3_amd64.deb" \
        "/tmp/libpng12-0_1.2.50-2+deb8u3_amd64.deb" || exit 1
    download_with_cache "https://storage.digiforte.com.br/libpng12-0_1.2.50-2%2Bdeb8u3_amd64.deb" \
        "/tmp/libpng12-0_1.2.50-2%2Bdeb8u3_amd64.deb" || log_warn "Mirror libpng12 indisponível."
    download_with_cache "http://us.archive.ubuntu.com/ubuntu/pool/universe/w/wxwidgets3.0/libwxgtk3.0-0v5_3.0.4+dfsg-3_amd64.deb" \
        "/tmp/libwxgtk3.0-0v5_3.0.4+dfsg-3_amd64.deb" || exit 1
    download_with_cache "https://safesign.gdamericadosul.com.br/content/SafeSign_IC_Standard_Linux_3.7.0.0_AET.000_ub1804_x86_64.rar" \
        "/tmp/SafeSign_IC_Standard_Linux_3.7.0.0_AET.000_ub1804_x86_64.rar" || exit 1

    apt-get install --assume-yes multiarch-support -qq
    dpkg -i /tmp/libpng12-0_1.2.50-2+deb8u3_amd64.deb || true
    dpkg -i /tmp/libpng12-0_1.2.50-2%2Bdeb8u3_amd64.deb 2>/dev/null || true
    apt install -y -qq /tmp/libwxgtk3.0-0v5_3.0.4+dfsg-3_amd64.deb
    unrar e -o+ "/tmp/SafeSign_IC_Standard_Linux_3.7.0.0_AET.000_ub1804_x86_64.rar" /tmp/
    apt install -y -qq /tmp/SafeSign_IC_Standard_Linux_3.7.0.0_AET.000_ub1804_x86_64.deb

elif [ "$VSO" = "focal" ] || [ "$VSO" = "una" ] || [ "$VSO" = "bullseye" ] || [ "$VSO" = "elsie" ] || [ "$VSO" = "bookworm" ] || [ "$VSO" = "uma" ] || [ "$VSO" = "ulyssa" ] || [ "$VSO" = "ulyana" ]; then
    log_info "Distribuição focal (20.04) ou similar detectada."
    download_with_cache "http://us.archive.ubuntu.com/ubuntu/pool/universe/w/wxwidgets3.0/libwxgtk3.0-0v5_3.0.4+dfsg-3_amd64.deb" \
        "/tmp/libwxgtk3.0-0v5_3.0.4+dfsg-3_amd64.deb" || exit 1
    apt install -y -qq /tmp/libwxgtk3.0-0v5_3.0.4+dfsg-3_amd64.deb

    download_with_cache "https://safesign.gdamericadosul.com.br/content/SafeSign_IC_Standard_Linux_3.7.0.0_AET.000_ub2004_x86_64.rar" \
        "/tmp/SafeSign_IC_Standard_Linux_3.7.0.0_AET.000_ub2004_x86_64.rar" || exit 1
    unrar e -o+ "/tmp/SafeSign_IC_Standard_Linux_3.7.0.0_AET.000_ub2004_x86_64.rar" /tmp/

    add-apt-repository ppa:linuxuprising/libpng12 -y
    apt-get update -qq
    apt-get install --assume-yes libpng12-0 -qq
    apt install -y -qq /tmp/SafeSign_IC_Standard_Linux_3.7.0.0_AET.000_ub2004_x86_64.deb

elif [ "$VSO" = "jammy" ] || [ "$VSO" = "virginia" ] || [ "$VSO" = "victoria" ] || [ "$VSO" = "vera" ] || [ "$VSO" = "vanessa" ]; then
    log_info "Distribuição jammy (22.04) ou similar detectada."
    download_with_cache "https://safesign.gdamericadosul.com.br/content/SafeSign_IC_Standard_Linux_ub2204_3.8.0.0_AET.000.zip" \
        "/tmp/safesign-jammy.zip" || exit 1
    unzip -qo "/tmp/safesign-jammy.zip" -d /tmp/
    apt install -y -qq /tmp/SafeSign*.deb

elif [ "$VSO" = "noble" ] || [ "$VSO" = "wilma" ] || [ "$VSO" = "xia" ] || [ "$VSO" = "zara" ] || [ "$VSO" = "zena" ]; then
    log_info "Distribuição noble (24.04) ou similar detectada."
    download_with_cache "https://safesign.gdamericadosul.com.br/content/SafeSign%20IC%20Standard%20Linux%20ub2404%204.6.0.0-AET.000.zip" \
        "/tmp/safesign-noble.zip" || exit 1
    unzip -qo "/tmp/safesign-noble.zip" -d /tmp/
    apt install -y -qq '/tmp/SafeSign IC Standard Linux 4.6.0.0-AET.000 ub2404 x86_64.deb'

else
    log_error "Distribuição $VSO não suportada pelo script tokenGD.sh."
    exit 1
fi

log_info "✅ Token G&D SafeSign instalado com sucesso."
exit 0
