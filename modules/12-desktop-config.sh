#!/bin/bash
# 12‑desktop‑config.sh – Configurações de desktop, atalhos e periféricos
# NÃO instala pacotes APT – eles são consolidados em 02‑bulk‑packages.
# Mantém todas as funcionalidades originais: BleachBit, drivers Epson,
# dicionários LibreOffice, cancelamento de ruído, atalhos .desktop,
# ícones personalizados e Token DXSafe.
set -euo pipefail
source /etc/customization/utils/logging.sh
log_module_start "12‑desktop‑config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"
check_root

load_om_ips 2>/dev/null || true
log_info "Iniciando configurações de desktop e atalhos..."

# --------------------------------------------------------------------
# 1. VISUALIZADOR DE IMAGENS
#    (já instalado pelo 02‑bulk‑packages: eog ou ristretto)
# --------------------------------------------------------------------
if [ -f /usr/bin/xfce4-session ]; then
    log_info "Ambiente XFCE – Ristretto já deve estar instalado."
else
    log_info "Ambiente GNOME – Eye of GNOME já deve estar instalado."
fi

# --------------------------------------------------------------------
# 2. BLEACHBIT
# --------------------------------------------------------------------
log_info "O BleachBit é instalado via flatpak..."

# --------------------------------------------------------------------
# 3. DRIVERS EPSON (instalar diretamente do cache)
# --------------------------------------------------------------------
log_info "Verificando drivers Epson no cache..."

# Impressoras
if ls /tmp/cache/epson-inkjet-printer-escpr_*.deb /tmp/cache/epson-printer-utility_*.deb 1>/dev/null 2>&1; then
    wait_for_apt_unlock
    dpkg -i /tmp/cache/epson-inkjet-printer-escpr_*.deb /tmp/cache/epson-printer-utility_*.deb 2>/dev/null || apt-get --fix-broken install -y -qq
    log_info "✅ Drivers Epson de impressora instalados diretamente do cache."
else
    log_info "ℹ️ Drivers de impressora Epson não encontrados no cache."
fi

# Scanner
if [ -f /tmp/cache/epsonscan2-bundle.tar.gz ]; then
    log_info "Processando scanner Epson a partir do cache..."
    mkdir -p /tmp/epson_scan 2>/dev/null
    tar -xzf /tmp/cache/epsonscan2-bundle.tar.gz -C /tmp/epson_scan/
    pastae=$(ls -d /tmp/epson_scan/epsonscan2-bundle* 2>/dev/null | head -1)
    if [ -n "$pastae" ] && [ -d "$pastae" ]; then
        cd "$pastae"
        if sh ./install.sh; then
            log_info "✅ Scanner Epson instalado com sucesso"
        else
            log_warning "⚠️ Falha na instalação do scanner Epson"
        fi
        cd - >/dev/null
    fi
    rm -rf /tmp/epson_scan
else
    log_info "ℹ️ Scanner Epson não encontrado no cache."
fi

# --------------------------------------------------------------------
# 4. DICIONÁRIOS PARA LIBREOFFICE (download padronizado via cache)
# --------------------------------------------------------------------
log_info "Baixando dicionários especializados para LibreOffice..."
DICTS="Quimica Militar Musica DicEconomia Botanica Microbiologia DicJuridico DicEletro DicInfo_0"

for dic in $DICTS; do
    ZIP_FILE="/tmp/${dic}.zip"

    case "$dic" in
        Militar)       URL="https://wiki.documentfoundation.org/images/3/3a/Militar.zip" ;;
        Quimica)       URL="https://wiki.documentfoundation.org/images/d/db/Quimica.zip" ;;
        Musica)        URL="https://wiki.documentfoundation.org/images/1/17/Musica.zip" ;;
        DicEconomia)   URL="https://wiki.documentfoundation.org/images/9/9a/DicEconomia.zip" ;;
        Botanica)      URL="https://wiki.documentfoundation.org/images/6/6d/Botanica.zip" ;;
        Microbiologia) URL="https://wiki.documentfoundation.org/images/f/f1/Microbiologia.zip" ;;
        DicJuridico)   URL="https://wiki.documentfoundation.org/images/6/65/DicJuridico.zip" ;;
        DicEletro)     URL="https://wiki.documentfoundation.org/images/a/a2/DicEletro.zip" ;;
        DicInfo_0)     URL="https://wiki.documentfoundation.org/images/8/80/DicInfo_0.zip" ;;
        *) continue ;;
    esac

    if download_with_cache "$URL" "$ZIP_FILE"; then
        if unzip -o -q "$ZIP_FILE" -d /usr/lib/libreoffice/share/wordbook/ 2>/dev/null; then
            log_info "✅ Dicionário $dic instalado"
        else
            log_warning "⚠️ Falha ao descompactar o arquivo corrompido: $dic"
        fi
        rm -f "$ZIP_FILE"
    else
        log_warning "⚠️ Falha no download de $dic"
    fi
done

# --------------------------------------------------------------------
# 5. CANCELAMENTO DE RUÍDO (PipeWire ou PulseAudio)
# --------------------------------------------------------------------
log_info "Configurando cancelamento de ruído de áudio..."
if command -v pactl >/dev/null 2>&1 && pactl info 2>/dev/null | grep -qi "PipeWire"; then
    config_dir="/etc/pipewire/pipewire.conf.d"
    mkdir -p "$config_dir"
    cat > "${config_dir}/99-echo-cancel.conf" << 'EOF'
context.modules = [
    {
        name = libpipewire-module-echo-cancel
        args = {
            capture.props = { node.name = "Echo Cancellation Capture" }
            source.props = { node.name = "Echo Cancellation Source" }
            sink.props = { node.name = "Echo Cancellation Sink" }
            playback.props = { node.name = "Echo Cancellation Playback" }
        }
    }
]
EOF
    log_info "✅ PipeWire: Módulo echo-cancel configurado."
elif [ -f /etc/pulse/default.pa ]; then
    if ! grep -q "module-echo-cancel" /etc/pulse/default.pa; then
        sed -i '/load-module module-filter-apply/a load-module module-echo-cancel aec_args="analog_gain_control=0 digital_gain_control=0" source_name=noiseless' /etc/pulse/default.pa
        sed -i '/#set-default-source input/a set-default-source noiseless' /etc/pulse/default.pa
        log_info "✅ PulseAudio: Módulo echo-cancel configurado."
    fi
fi

# --------------------------------------------------------------------
# 6. CUPS E ÍCONES
# --------------------------------------------------------------------
if [ -f /etc/cups/cups-browsed.conf ]; then
    sed -i 's/BrowseLocalProtocols dnssd/BrowseLocalProtocols none/g' /etc/cups/cups-browsed.conf 2>/dev/null || echo "BrowseLocalProtocols none" >> /etc/cups/cups-browsed.conf
fi
if [ -f /etc/cups/cupsd.conf ]; then
    sed -i 's/Browsing On/Browsing Off/g' /etc/cups/cupsd.conf 2>/dev/null || echo "Browsing Off" >> /etc/cups/cupsd.conf
fi

ORIG_DIR="$SCRIPT_DIR/../original_scripts"
if [ -d "$ORIG_DIR" ] && ls "$ORIG_DIR"/*.png 1>/dev/null 2>&1; then
    cp -f "$ORIG_DIR"/*.png /usr/share/icons/ 2>/dev/null
    log_info "✅ Ícones personalizados instalados."
fi

mkdir -p /etc/skel/.config/autostart/

# --------------------------------------------------------------------
# 7. ATALHOS .DESKTOP
# --------------------------------------------------------------------
log_info "Criando atalhos no menu de aplicações..."

cat > /usr/share/applications/assinador-serpro.desktop << 'EOF2'
[Desktop Entry]
Name=Instala Assinador Serpro
Comment=Instala ou atualiza o Assinador Digital do Serpro
Exec=sudo /bin/bash /etc/serproass.sh
Type=Application
Terminal=true
Icon=Computer
Categories=System;
EOF2

cat > /usr/share/applications/instalador-certillion.desktop << 'EOF2'
[Desktop Entry]
Name=Instala Assinador Certillion para usuários
Exec=/bin/bash /etc/certillion.sh
Type=Application
Categories=System;
Icon=applications-system
Terminal=false
EOF2

cat > /usr/share/applications/instalador-bonita.desktop << 'EOF2'
[Desktop Entry]
Name=Instala Bonita Studio para usuários
Exec=/bin/bash /etc/bscautostart.sh
Type=Application
Categories=System;
Icon=applications-system
Terminal=false
EOF2

chmod 755 /usr/share/applications/*.desktop
log_info "✅ Todos os atalhos .desktop foram criados e verificados."

# --------------------------------------------------------------------
# 8. TOKEN DXSAFE (wrapper) – herdado do antigo 13‑extra‑packages
# --------------------------------------------------------------------
log_info "Configurando Token DXSafe..."
if [ -f /etc/customization/scripts/setup-dxsafe-wrapper.sh ]; then
    bash /etc/customization/scripts/setup-dxsafe-wrapper.sh
    log_info "✅ Token DXSafe wrapper executado."
else
    log_warning "⚠️ Script setup-dxsafe-wrapper.sh não encontrado."
fi

# --------------------------------------------------------------------
# CONCLUSÃO
# --------------------------------------------------------------------
log_info "========================================="
log_info "✅ Configurações de desktop e atalhos concluídas!"
log_info "========================================="
log_module_end "12‑desktop‑config"
