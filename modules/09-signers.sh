#!/bin/bash
# 09-signers.sh - Instala suporte (WEB) a assinadores digitais
# CRÍTICO: libssl1.1 e WebPKI são obrigatórios para funcionamento dos assinadores.
#           Falhas nestas etapas abortam o módulo.
set -euo pipefail
source /etc/customization/utils/logging.sh
log_module_start "09-signers"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

check_root

# -----------------------------------------------------------------------------
# 1. Instala libssl1.1 (Necessária para compatibilidade com assinadores antigos)
# -----------------------------------------------------------------------------
if [ ! -f /usr/lib/x86_64-linux-gnu/libssl.so.1.1 ]; then
    log_info "Instalando libssl1.1..."
    if download_with_cache \
        "http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb" \
        "/tmp/libssl1.1.deb"; then
        wait_for_apt_unlock
        if ! dpkg -i /tmp/libssl1.1.deb; then
            log_warning "Falha no dpkg, tentando corrigir dependências..."
            apt-get --fix-broken install -y -qq || {
                log_error "Não foi possível instalar o libssl1.1 mesmo após --fix-broken."
                exit 1
            }
        fi
        log_info "✅ libssl1.1 instalado com sucesso."
    else
        log_error "🌐 Falha CRÍTICA no download do libssl1.1. Abortando instalação de assinadores."
        exit 1
    fi
else
    log_info "libssl1.1 já presente no sistema."
fi

# -----------------------------------------------------------------------------
# 2. Instala WebPKI (Lacuna) – obrigatório para maioria dos assinadores web
# -----------------------------------------------------------------------------
if ! dpkg -l 2>/dev/null | grep -q webpki; then
    log_info "Instalando WebPKI..."
    if download_with_cache \
        "https://get.webpkiplugin.com/Downloads/2.15.0/setup-deb-64" \
        "/tmp/webpki.deb"; then
        
        wait_for_apt_unlock
        if ! dpkg -i /tmp/webpki.deb; then
            log_warning "Falha no dpkg, tentando corrigir dependências..."
            apt-get --fix-broken install -y -qq || {
                log_error "Não foi possível instalar o WebPKI mesmo após --fix-broken."
                exit 1
            }
        fi
        log_info "✅ WebPKI instalado com sucesso."
    else
        log_error "🌐 Falha CRÍTICA no download do WebPKI. Abortando instalação de assinadores."
        exit 1
    fi
else
    log_info "WebPKI já instalado."
fi

# -----------------------------------------------------------------------------
# 3. Suporte a outros assinadores (Shodō / PJe Office) via cache
#    – falhas aqui NÃO são críticas; apenas registramos aviso.
# -----------------------------------------------------------------------------
if [ -d /tmp/cache ]; then
    for signer in /tmp/cache/pje-office*.deb /tmp/cache/shodo*.deb; do
        if [ -f "$signer" ]; then
            log_info "✅ Instalando assinador do cache: $(basename "$signer")"
            wait_for_apt_unlock
            if ! dpkg -i "$signer"; then
                log_warning "⚠️ Falha ao instalar $(basename "$signer"). Tentando corrigir..."
                apt-get --fix-broken install -y -qq || log_warning "Não foi possível corrigir dependências do assinador."
            fi
        fi
    done
fi

log_module_end "09-signers"
