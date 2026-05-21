#!/bin/bash
# 00-dependencies.sh - Instala dependências essenciais (NFS, Flatpak, OSTree)
set -euo pipefail
source /etc/customization/utils/logging.sh
source /etc/customization/utils/common.sh
log_module_start "00-dependencies"

check_root

# Instala pacotes necessários para montagem NFS e Flatpak sideload
log_info "📦 Instalando dependências: nfs-common flatpak ostree"
install_packages nfs-common flatpak ostree

log_module_end "00-dependencies"
