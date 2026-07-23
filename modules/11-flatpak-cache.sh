#!/bin/bash
# 11-flatpak-cache.sh - Usa cache NFS já montado pelo main.sh
# Não monta nada, não instala dependências.
set -euo pipefail
source /etc/customization/utils/logging.sh
log_module_start "11-flatpak-cache"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

check_root

log_info "========================================="
log_info "Instalação de pacotes Flatpak (usando cache NFS)"
log_info "========================================="

load_om_ips 2>/dev/null || true

if [ "${ENABLE_FLATPAK_CACHE:-false}" != "true" ]; then
    log_info "ℹ️ ENABLE_FLATPAK_CACHE=false - pulando"
    exit 0
fi

# =============================================================================
# Verifica se o cache NFS já está montado pelo main.sh
# =============================================================================
CACHE_AVAILABLE=false
if mountpoint -q /mnt && [ -d /mnt/.ostree/repo ]; then
    CACHE_AVAILABLE=true
    log_info "✅ Cache NFS disponível em /mnt/.ostree/repo (montado pelo main.sh)"
else
    log_info "⚠️ Cache NFS não montado ou sem repositório. Instalando da internet."
fi

# =============================================================================
# Garante que o repositório flathub existe
# =============================================================================
if ! flatpak remotes 2>/dev/null | grep -q flathub; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    log_info "✅ Repositório Flathub adicionado"
fi

if [ "$CACHE_AVAILABLE" = true ]; then
    flatpak remote-modify --collection-id=org.flathub.Stable flathub 2>/dev/null || true
    log_info "✅ Flatpak configurado para usar collection-id"
fi

# =============================================================================
# Lista de pacotes
# =============================================================================
packages=(
    "org.bleachbit.BleachBit"
    "org.keepassxc.KeePassXC"
    "com.obsproject.Studio"
    "org.jitsi.jitsi-meet"
)

if [ "${ENABLE_HEALTH_APPS:-false}" = "true" ]; then
    packages+=("io.github.nroduit.Weasis" "br.app.pw3270.terminal")
    log_info "🏥 Perfil SAÚDE"
else
    packages+=("org.onlyoffice.desktopeditors")
    log_info "🏠 Perfil DOMÉSTICO"
fi

# =============================================================================
# Instalação única usando sideload se cache disponível
# =============================================================================
if [ "$CACHE_AVAILABLE" = true ]; then
    log_info "📦 Instalando via cache NFS (sideload)..."
    log_info "ℹ️ Instalando a partir do cache NFS (sem download) – o progresso pode mostrar 0%, mas a instalação está ocorrendo normalmente."
    if flatpak install --sideload-repo=/mnt/.ostree/repo -y "${packages[@]}" 2>/dev/null; then
        log_info "✅ Todos os pacotes instalados do cache"
    else
        log_warning "Falha no cache, instalando da internet"
        flatpak install flathub -y "${packages[@]}"
    fi
else
    log_info "📦 Instalando da internet..."
    flatpak install flathub -y "${packages[@]}"
fi
flatpak update -y --noninteractive

# Garantir que o diretório de exports do Flatpak esteja no XDG_DATA_DIRS
export_dir="/var/lib/flatpak/exports/share"
profile_script="/etc/profile.d/flatpak-exports.sh"

if [ ! -f "$profile_script" ] || ! grep -q "$export_dir" "$profile_script"; then
    cat > "$profile_script" << 'EOF'
# Adiciona diretório de exports do Flatpak ao XDG_DATA_DIRS
export_dir="/var/lib/flatpak/exports/share"
case ":${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:" in
    *":$export_dir:"*) ;;
    *) XDG_DATA_DIRS="$export_dir:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" ;;
esac
export XDG_DATA_DIRS
EOF
    chmod 0644 "$profile_script"
fi

# Atualizar base de dados de desktop imediatamente (se disponível)
if command -v update-desktop-database >/dev/null 2>&1 && [ -d "$export_dir/applications" ]; then
    update-desktop-database "$export_dir/applications" 2>/dev/null || true
fi


# =============================================================================
# Sincronização para o cache NFS (create-usb) - SEMPRE executa
# OTIMIZAÇÃO 1.6: verifica existência do ref antes de sincronizar
# =============================================================================
if [ "$CACHE_AVAILABLE" = true ] && [ -w /mnt/.ostree/repo ]; then
    log_info "🔄 Sincronizando pacotes para o cache NFS (create-usb)..."
    for pkg in "${packages[@]}"; do
        # Verifica se o ref já existe no repositório NFS
        if ostree refs --repo=/mnt/.ostree/repo 2>/dev/null | grep -q "^${pkg}/"; then
            log_info "   ✅ $pkg já presente no cache NFS. Pulando sincronização."
        else
            log_info "   📤 Sincronizando $pkg..."
            if ! nice -n 19 ionice -c 3 flatpak create-usb --allow-partial /mnt "$pkg" 2>/dev/null; then
    		log_warning "   ⚠️ Falha ao sincronizar $pkg (será ignorado)"
    		ret=$?
    		# Opcional: registrar o nome do pacote para relatório posterior
            else
               ret=0
	    fi
            if [ $ret -eq 0 ]; then
                log_info "   ✅ $pkg sincronizado (ou já presente)"
            else
                log_warning "   ⚠️ Falha ao sincronizar $pkg (pode já estar ok)"
            fi
        fi
    done
fi

# =============================================================================
# Remoção de pacotes conforme perfil (mesmo do flatcache.sh)
# =============================================================================
if [ "${ENABLE_HEALTH_APPS:-false}" = "false" ]; then
    log_info "🗑️ Removendo pacotes não-domésticos..."
    flatpak uninstall --system -y br.app.pw3270.terminal io.github.nroduit.Weasis 2>/dev/null || true
    rm -f /etc/klnagent64*.deb /etc/kesl_12*.deb /etc/kesl-gui_12*.deb /etc/KSEzorin.sh 2>/dev/null || true
fi

# Kaspersky (apenas saúde) – assume que /tmp/cache está montado pelo main.sh
if [ "${ENABLE_HEALTH_APPS:-false}" = "true" ] && [ -d /tmp/cache ] && [ -f /tmp/cache/KSEzorin.sh ]; then
    log_info "🔒 Copiando pacotes Kaspersky..."
    cp -f /tmp/cache/klnagent64*.deb /etc/ 2>/dev/null || true
    cp -f /tmp/cache/kesl_12*.deb /etc/ 2>/dev/null || true
    cp -f /tmp/cache/kesl-gui_12*.deb /etc/ 2>/dev/null || true
    cp -f /tmp/cache/KSEzorin.sh /etc/ && chmod +x /etc/KSEzorin.sh
    sync
fi

ostree-repo-maintenance-mark
rmdir /mnt/.ostree/repo/.maintenance.lock 2>/dev/null   # libera o lock

log_info "✅ Instalação Flatpak concluída"
log_module_end "11-flatpak-cache"
