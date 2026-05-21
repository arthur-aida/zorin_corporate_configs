#!/bin/bash
# 03-certificates.sh - Instala certificados ICP-Brasil (primeira execução)
# script executado durante o deploy no ambiente root
set -euo pipefail
source /etc/customization/utils/logging.sh
log_module_start "03-certificates"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

check_root

ORIG_DIR="$SCRIPT_DIR/../original_scripts"

# Executa a instalação inicial (baixa e instala certificados no sistema)
if [ -f "$ORIG_DIR/instalar_certificados_icp_brasil.sh" ]; then
    log_info "Instalando certificados do governo (primeira execução)..."
    bash "$ORIG_DIR/instalar_certificados_icp_brasil.sh" || exit 1
else
    log_info "ERRO: instalar_certificados_icp_brasil.sh não encontrado em $ORIG_DIR"
fi

# Atualiza os certificados do sistema (reforço)
update-ca-certificates 2>/dev/null || log_info "AVISO: Falha ao atualizar certificados"

log_info "Certificados atualizados"
log_module_end "03-certificates"
