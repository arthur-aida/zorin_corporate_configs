#!/bin/bash
# 04-browsers.sh - Configura navegadores e Java
# script executado durante o deploy no ambiente root
set -euo pipefail
source /etc/customization/utils/logging.sh
log_module_start "04-browsers"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

check_root

# Executa scripts de navegadores se existirem
bash /etc/firefox-manager.sh stable
bash /etc/firefox-manager.sh esr

log_info "Navegadores configurados"
log_module_end "04-browsers"
