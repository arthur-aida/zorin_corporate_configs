#!/bin/bash
# 15-kvm-menu.sh - Cria atalho no menu para instalação manual do KVM
# script executado durante o deploy no ambiente root
set -euo pipefail
source /etc/customization/utils/logging.sh
log_module_start "15-kvm-menu"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

check_root

# Copia script instalador para /usr/local/bin/
cp "$SCRIPT_DIR/../scripts/install-kvm.sh" /usr/local/bin/
chmod 755 /usr/local/bin/install-kvm.sh

# Copia atalho .desktop para o menu de aplicações
cp "$SCRIPT_DIR/../scripts/install-kvm.desktop" /usr/share/applications/
chmod 644 /usr/share/applications/install-kvm.desktop

# Opcional: copiar também para /etc/skel/.local/share/applications/ (para novos usuários)
#SKEL_APPS="/etc/skel/.local/share/applications"
#mkdir -p "$SKEL_APPS"
#cp "$SCRIPT_DIR/../scripts/install-kvm.desktop" "$SKEL_APPS/"

log_info "Atalho para instalação do KVM criado no menu (Ferramentas do Sistema)"
log_module_end "15-kvm-menu"
