#!/bin/bash
# 05‑tokens.sh – Configura tokens criptográficos (drivers proprietários)
set -euo pipefail
source /etc/customization/utils/logging.sh
log_module_start "05‑tokens"
source /etc/customization/utils/common.sh

check_root

log_info "Executando instaladores de tokens..."

# Proteção contra lock do dpkg antes de iniciar instalações via apt/dpkg
wait_for_apt_unlock

for script in tokenGD.sh safenet.sh; do
    if [ -f "/etc/$script" ]; then
        log_info "   Executando $script..."
        bash "/etc/$script" || log_warning "   ⚠️ Falha em $script"
    fi
done

# Links simbólicos mantidos
ln -sf /bin/CARREGAdriverTOKEN.sh /bin/carregadrivertoken 2>/dev/null || true
ln -sf /bin/CARREGAdriverTOKEN.sh /bin/carregadrivertokens 2>/dev/null || true

log_info "✅ Drivers de tokens configurados."
log_module_end "05‑tokens"
