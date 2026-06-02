#!/bin/bash
# aptcacher.sh - Script de manutenção periódica (cron) – Otimizado Fase 3
# Mantida a verificação de conectividade com DNS da intranet e execução do Kaspersky

# =============================================================================
# CARREGAMENTO DO PERFIL ATIVO (independente do main.sh)
# =============================================================================
if [ -z "${MAIN_ACTIVE:-}" ] && [ -f /etc/customization/active-profile.env ]; then
    set -a
    . /etc/customization/active-profile.env
    set +a
fi

# Marcador de atualização inicial
echo "" >/tmp/$(date +%F_%H%M%S)".ini"

# CARREGA VARIÁVEIS DO SISTEMA
. /etc/os-release

if [ -f /etc/om.ips ]; then
    . /etc/om.ips
else
    echo "Erro ao carregar variaveis em $(basename '$0')"
fi

onde=$(dirname $(readlink -f $0))
var2=$ID
SCRIPT_DIR="/etc/customization"

# =============================================================================
# GESTÃO INTELIGENTE DE CACHE
# =============================================================================
if bash "/etc/acngonoff.sh"; then
    [ -f /tmp/acng_env ] && . /tmp/acng_env
    echo "[INFO] Servidor de Cache Operacional ($PROXY_URL). Refazendo mapeamento direto..." | logger -t "aptcacher"
    if [ -f "$SCRIPT_DIR/scripts/convert-sources-to-proxy.sh" ]; then
        export ACTUAL_PROXY_URL="$PROXY_URL"
        bash "$SCRIPT_DIR/scripts/convert-sources-to-proxy.sh"
    fi
else
    echo "[WARN] Servidor de Cache Inacessível. Revertendo configurações..." | logger -t "aptcacher"
    rm -f /etc/apt/apt.conf.d/00aptproxy 2>/dev/null
    if [ -f "$SCRIPT_DIR/scripts/restore-sources-from-backup.sh" ]; then
        bash "$SCRIPT_DIR/scripts/restore-sources-from-backup.sh"
    fi
fi

# =============================================================================
# VERIFICAÇÃO DE CONECTIVIDADE COM DNS DA INTRANET E EXECUÇÃO DO KASPERSKY
# =============================================================================
if nc -w 2 -z "$DNS" 53 2>/dev/null && [ -f /etc/KSEzorin.sh ]; then
        sh /etc/KSEzorin.sh 2>&1 | logger -t "KSEzorin.sh"
fi

# =============================================================================
# ATUALIZAÇÃO APENAS DAS LISTAS (sem full-upgrade para reduzir I/O)
# =============================================================================
apt update

# =============================================================================
# ATUALIZAÇÃO DE NAVEGADORES (apenas para distribuições suportadas)
# =============================================================================
if [ "$var2" = 'zorin' ] || [ "$var2" = 'ubuntu' ] || [ "$var2" = 'linuxmint' ]; then
    sh /etc/firefox-manager.sh stable
    sh /etc/firefox-manager.sh esr
fi

# =============================================================================
# Abaixo é recriado um gancho para que APPLETS JAVA sejam executados pela versão específica do java em /usr/local/jre1.8.0_221/ 
# =============================================================================
if [ ! -f /usr/share/applications/icedtea-netx-javaws.desktop ]; then
    cat > /usr/share/applications/icedtea-netx-javaws.desktop << 'EOF2'
[Desktop Entry]
Name=IcedTea Web Start
GenericName=Java Web Start
Comment=IcedTea Application Launcher
Exec=/usr/local/jre1.8.0_221/bin/javaws %u
Icon=javaws
Terminal=false
Type=Application
NoDisplay=true
Categories=Application;Network;
MimeType=application/x-java-jnlp-file;x-scheme-handler/jnlp;x-scheme-handler/jnlps
EOF2
    chmod 644 /usr/share/applications/icedtea-netx-javaws.desktop
    chmod +x /usr/share/applications/icedtea-netx-javaws.desktop
fi

# Marcador de atualização final
echo "" >/tmp/$(date +%F_%H%M%S)".fim"

# =============================================================================
# ATIVA TRIM EM SSD, SFC
# =============================================================================
DRIVE=$(lsblk -no pkname $(findmnt -n / | awk '{ print $2 }'))
if ! grep -q "discard" /etc/fstab; then
    if [ "$(cat /sys/block/$DRIVE/queue/rotational 2>/dev/null)" = "0" ]; then
        systemctl enable fstrim.timer
        systemctl start fstrim.timer
    fi
fi
