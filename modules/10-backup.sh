#!/bin/bash
# 10-backup.sh - Instala a ferramenta de backup conforme o perfil 
# script executado durante o deploy no ambiente root
set -euo pipefail
source /etc/customization/utils/logging.sh
log_module_start "10-backup"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

check_root

# Carrega configurações
load_om_ips || true

if [ "${ENABLE_BACKUP:-false}" != "true" ]; then
    log_info "ENABLE_BACKUP não está habilitado. Pulando configuração."
    exit 0
fi

ORIG_DIR="$SCRIPT_DIR/../original_scripts"

# Executa script de backup se existir
if [ -f "$ORIG_DIR/proxmoxbackupclient.sh" ]; then
    log_info "Configurando backup..."
    
    # Proteção: aguarda liberação do lock do dpkg antes de executar script com apt
    wait_for_apt_unlock
    bash "$ORIG_DIR/proxmoxbackupclient.sh" || log_warning "AVISO: Falha no proxmoxbackupclient.sh"
else
    log_info "ℹ️ proxmoxbackupclient.sh não encontrado. Pulando."
fi

log_info "Backup para o Proxmox configurado"

log_module_end "10-backup"
