#!/bin/bash
# setup-dxsafe-wrapper.sh - Configura o wrapper do Token DXSafe
# Remove o link existente e cria um script que chama o original

# Evita execução múltipla (se o script já estiver rodando)
LOCKFILE="/tmp/"$(basename $0)".lock"
if [ -f "$LOCKFILE" ]; then
    exit 0
fi
touch "$LOCKFILE"

# Carrega ambiente comum (assumindo que o script está em /etc/customization/scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

log_module_start "setup-dxsafe-wrapper"

# -----------------------------------------------------------------------------
# 1. Baixar ou copiar o arquivo ZIP do instalador
# -----------------------------------------------------------------------------
ZIP_DEST="/etc/dxsafe_install.zip"
ZIP_URL="https://repositorio-acp.acdefesa.mil.br/Drivers_Token/Dexon/Ubuntu/Drive_Ubuntu_22_04_install.zip"
ZIP_BASENAME="$(basename "$ZIP_URL")"

if [ -f "/tmp/cache/$ZIP_BASENAME" ]; then
    # OTIMIZAÇÃO 1.2/1.3: verifica se o destino já existe e tem o mesmo tamanho
    if [ -f "$ZIP_DEST" ] && [ $(stat -c%s "$ZIP_DEST" 2>/dev/null || echo 0) -eq $(stat -c%s "/tmp/cache/$ZIP_BASENAME" 2>/dev/null || echo -1) ]; then
        log_info "✅ Instalador já presente e idêntico ao cache. Pulando cópia."
    else
        cp "/tmp/cache/$ZIP_BASENAME" "$ZIP_DEST"
        log_info "✅ Instalador copiado do cache NFS"
    fi
else
    log_info "Baixando instalador (--no-check-certificate)..."
    if wget --no-check-certificate --timeout=30 --tries=3 -O "$ZIP_DEST" "$ZIP_URL"; then
        log_info "✅ Download concluído"
        mkdir -p /tmp/cache
        cp "$ZIP_DEST" "/tmp/cache/$ZIP_BASENAME" 2>/dev/null || true
    else
        log_error "❌ Falha no download do instalador"
        exit 1
    fi
fi

# -----------------------------------------------------------------------------
# 2. Remover link existente (se for link simbólico)
# -----------------------------------------------------------------------------
if [ -L "/etc/TokenDXSafe.sh" ]; then
    rm -f "/etc/TokenDXSafe.sh"
    log_info "Link simbólico /etc/TokenDXSafe.sh removido"
elif [ -f "/etc/TokenDXSafe.sh" ]; then
    # Se for um arquivo comum, faz backup
    mv "/etc/TokenDXSafe.sh" "/etc/TokenDXSafe.sh.bak"
    log_warning "Arquivo existente movido para /etc/TokenDXSafe.sh.bak"
fi

# -----------------------------------------------------------------------------
# 3. Criar o script wrapper
# -----------------------------------------------------------------------------
cat > /etc/TokenDXSafe.sh << 'EOF'
#!/bin/bash
ORIG_SCRIPT="/etc/customization/original_scripts/TokenDXSafe.sh"
ZIP_FILE="/etc/dxsafe_install.zip"
TEMP_DIR="/tmp/dxsafe_manual_install"
source /etc/customization/utils/common.sh

# Desativar a Memória de video Compartilhada
export QT_X11_NO_MITSHM=1

if [ -f /etc/apt/apt.conf.d/00aptproxy ];then
	rm -f /etc/apt/apt.conf.d/00aptproxy
fi

[ ! -f "$ORIG_SCRIPT" ] && { zenity --error --text="Script original não encontrado."; exit 1; }
[ ! -f "$ZIP_FILE" ] && { zenity --error --text="Instalador não encontrado."; exit 1; }
zenity --warning --text="1 - Aguarde o instalador iniciar;\n \n2 - Na próxima janela, siga as instruções do instalador;\n \n3 - Esta janela se fecha em 30s." --width=650 --height=150 --timeout=30 &

# Prepara o diretório temporário mas não muda o working directory
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
cp "$ZIP_FILE" "$TEMP_DIR/Drive_Ubuntu_22_04_install.zip"

# Salva o diretório atual e executa o script original a partir do diretório onde common.sh funciona
CURRENT_DIR="$PWD"
cd /etc/customization/modules/ || cd /etc/customization/ || cd /
bash "$ORIG_SCRIPT"
EXIT_CODE=$?

# Volta ao diretório original e limpa se necessário
cd "$CURRENT_DIR"
if zenity --question --text="Instalação concluída.\nDeseja remover o diretório temporário?"; then
    rm -rf "$TEMP_DIR"
    zenity --info --text="Arquivos temporários removidos."
fi
exit $EXIT_CODE
EOF

chmod +x /etc/TokenDXSafe.sh
log_info "✅ Wrapper criado em /etc/TokenDXSafe.sh"

# -----------------------------------------------------------------------------
# 4. Criar atalho no menu (se ainda não existir)
# -----------------------------------------------------------------------------
DESKTOP_FILE="/usr/share/applications/instalar-dxsafe.desktop"
if [ ! -f "$DESKTOP_FILE" ]; then
    cat > "$DESKTOP_FILE" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Instalar Token DXSafe
Comment=Instala drivers do token Dexon DXSafe
Exec=sudo /etc/TokenDXSafe.sh
Icon=computer
Terminal=true
Categories=System;Settings;Hardware;
StartupNotify=true
EOF

    # Fallback se pkexec não existir
    if ! command -v pkexec >/dev/null 2>&1; then
        if command -v gksu >/dev/null 2>&1; then
            sed -i 's|pkexec|gksu|' "$DESKTOP_FILE"
        else
            sed -i 's|pkexec|sudo -i|' "$DESKTOP_FILE"
            sed -i 's|Terminal=false|Terminal=true|' "$DESKTOP_FILE"
        fi
    fi
    chmod +x "$DESKTOP_FILE"
    log_info "✅ Atalho criado em $DESKTOP_FILE"
else
    log_info "Atalho já existe em $DESKTOP_FILE"
fi
rm -f "$LOCKFILE"

log_module_end "setup-dxsafe-wrapper"
