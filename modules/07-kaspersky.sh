#!/bin/bash
# 07-kaspersky.sh - Prepara ambiente para Kaspersky (perfil saúde)
set -euo pipefail
source /etc/customization/utils/logging.sh
log_module_start "07-kaspersky"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

check_root
load_om_ips || true

if [ "${ENABLE_HEALTH_APPS:-false}" != "true" ]; then
    log_info "Perfil saúde não ativo. Kaspersky ignorado."
    exit 0
fi

log_info "Perfil saúde ativo. Preparando Kaspersky..."

CACHE_FILE="/tmp/cache/KSE-12.3.tar"
DEST_FILE="/etc/KSE-12.3.tar"

if [ -f "$CACHE_FILE" ]; then
    cp -f "$CACHE_FILE" "$DEST_FILE"
    chmod 644 "$DEST_FILE"
    log_info "✅ Kaspersky copiado do cache NFS"
    
    # Copia o script de boot
    BOOT_SCRIPT="$SCRIPT_DIR/../scripts/kaspersky-boot-install.sh"
    if [ -f "$BOOT_SCRIPT" ]; then
        cp -f "$BOOT_SCRIPT" /usr/local/bin/kaspersky-boot-install.sh
        chmod 755 /usr/local/bin/kaspersky-boot-install.sh
    fi
    
    # Cria serviço systemd
    cat > /etc/systemd/system/kaspersky-installer.service << 'EOF'
[Unit]
Description=Kaspersky Installer
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/kaspersky-boot-install.sh
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable kaspersky-installer.service
    log_info "Kaspersky preparado (instalação será concluída no próximo boot)."
else
    log_info "Cache NFS não disponível – Kaspersky não será instalado"
fi

log_module_end "07-kaspersky"
