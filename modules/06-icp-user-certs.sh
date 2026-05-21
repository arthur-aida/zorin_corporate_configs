#!/bin/bash
# 06-icp-user-certs.sh - Este script prepara a importação de certificados ICP no espaço dos futuros usuários
# script executado durante o deploy no ambiente root
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"
source /etc/customization/utils/logging.sh
log_module_start "06-icp-user-certs"

check_root

# Caminhos dos novos arquivos (devem estar em ../scripts/)
NEW_SCRIPT="$SCRIPT_DIR/../scripts/import-icp-brasil.sh"
NEW_DESKTOP="$SCRIPT_DIR/../scripts/import-certs.desktop"

if [ ! -f "$NEW_SCRIPT" ] || [ ! -f "$NEW_DESKTOP" ]; then
    log_info "ERRO: Arquivos de certificados não encontrados em ../scripts/"
    exit 1
fi

# ------------------------------------------------------------------------------
# 1. Configuração para novos usuários (skel)
# ------------------------------------------------------------------------------
SKEL_BIN="/etc/skel/.local/bin"
SKEL_AUTOSTART="/etc/skel/.config/autostart"
mkdir -p "$SKEL_BIN" "$SKEL_AUTOSTART"
chmod 755 "$SKEL_BIN"
chmod 755 "$SKEL_AUTOSTART"

cp "$NEW_SCRIPT" "/etc/import-icp-brasil.sh"
chmod 755 "/etc/import-icp-brasil.sh"
chmod +x "/etc/import-icp-brasil.sh"

log_info "Scripts instalados no skel para novos usuários."

# ------------------------------------------------------------------------------
# 2. Para usuários existentes
# ------------------------------------------------------------------------------
for user_home in /home/*; do
    [ -d "$user_home" ] || continue
    username=$(basename "$user_home")

    mkdir -p "$user_home/.local/bin" "$user_home/.config/autostart"
    cp "$NEW_SCRIPT" "$user_home/.local/bin/import-icp-brasil.sh"
    chown "$username":"$username" "$user_home/.local/bin/import-icp-brasil.sh"
    chmod 755 "$user_home/.local/bin/import-icp-brasil.sh"
    chmod +x "$user_home/.local/bin/import-icp-brasil.sh"

    cp "$NEW_DESKTOP" "$user_home/.config/autostart/import-certs.desktop"
    chown "$username":"$username" "$user_home/.config/autostart/import-certs.desktop"
    chmod 755 "$user_home/.config/autostart/import-certs.desktop"
    chmod +x "$user_home/.config/autostart/import-certs.desktop"

    log_info "Certificados ICP configurados para usuário: $username"
done

# ------------------------------------------------------------------------------
# 3. Permissões para Flatpaks (acesso aos drivers de tokens)
# ------------------------------------------------------------------------------
for pkg in org.chromium.Chromium org.mozilla.firefox com.google.Chrome com.microsoft.Edge com.brave.Browser; do
    flatpak override "$pkg" --filesystem=/usr/lib:ro 2>/dev/null || true
done

log_info "Script concluído. Preparação da importação de certificados ICP no espaço dos futuros usuários OK."
log_module_end "06-icp-user-certs"
