#!/bin/bash
# 01-sync-scripts.sh - Sincroniza scripts originais
# script executado durante o deploy no ambiente root
set -euo pipefail
source /etc/customization/utils/logging.sh
log_module_start "01-sync-scripts"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

check_root

ORIG_DIR="$SCRIPT_DIR/../original_scripts"
chmod 755 "$ORIG_DIR"/*.sh 2>/dev/null || true

# Verifica se diretório existe
if [ ! -d "$ORIG_DIR" ]; then
    log_info "AVISO: $ORIG_DIR não encontrado. Pulando sincronização."
    exit 0
fi

# Mapeamento de destinos especiais
declare -A special_dest=(
    ["CARREGAdriverTOKEN.sh"]="/bin/"
)
chmod +x "$ORIG_DIR"/*.sh

# Lista de scripts que NÃO devem ter link criado (serão tratados manualmente)
EXCLUDE_SCRIPTS=("TokenDXSafe.sh")

# Cria links para scripts
for file in "$ORIG_DIR"/*.sh; do
    [ -f "$file" ] || continue
    
    fn=$(basename "$file")
    
    # Verifica se o script está na lista de exclusão
    skip=0
    for exclude in "${EXCLUDE_SCRIPTS[@]}"; do
        if [ "$fn" = "$exclude" ]; then
            skip=1
            log_info "Script $fn será tratado separadamente (não será linkado)."
            break
        fi
    done
    [ $skip -eq 1 ] && continue
    
    dest_dir="${special_dest[$fn]:-/etc/}"
    dest_path="${dest_dir}${fn}"
    
    if [ ! -e "$dest_path" ]; then
        ln -sf "$file" "$dest_path"
        log_info "Link criado: $fn -> $dest_path"
    fi
done

ORIG_DIR="$SCRIPT_DIR/../scripts/"

echo "Verificaçao do path scripts/99-apt-cacher-roaming ->" $ORIG_DIR
log_info "Configurando script de manutenção do roaming para caches...$ORIG_DIR"
if [ -f "$ORIG_DIR"/99-apt-cacher-roaming ] && [ ! -f /etc/NetworkManager/dispatcher.d/99-apt-cacher-roaming ]; then
    cp -f "$ORIG_DIR"/99-apt-cacher-roaming /etc/NetworkManager/dispatcher.d/99-apt-cacher-roaming 2>/dev/null
    chmod +x /etc/NetworkManager/dispatcher.d/99-apt-cacher-roaming
    log_info "✅ Script de manutenção do ROAMING de cache instalados."
fi

echo "Verificaçao do path /scripts/flatpak-cache-maintenance.sh ->" $ORIG_DIR
log_info "Configurando script de manutenção do flatpak...$ORIG_DIR"
if [ -d "$ORIG_DIR" ] && [ -f "$ORIG_DIR"/flatpak-cache-maintenance.sh ] && [ ! -f /usr/local/bin/flatpak-cache-maintenance.sh ]; then
    cp -f "$ORIG_DIR"/flatpak-cache-maintenance.sh /usr/local/bin/flatpak-cache-maintenance.sh 2>/dev/null
    chmod +x /usr/local/bin/flatpak-cache-maintenance.sh
    log_info "✅ Script de manutenção do NFS instalados."
fi

log_info "Sincronização de scripts concluída"
log_module_end "01-sync-scripts"
