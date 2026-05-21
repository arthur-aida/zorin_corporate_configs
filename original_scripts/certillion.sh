#!/bin/bash
# certillion.sh - Instala Certillion (usuário comum)

# Evita execução múltipla (se o script já estiver rodando)
LOCKFILE="/tmp/"$(basename $0)".lock"
if [ -f "$LOCKFILE" ]; then
    exit 0
fi
touch "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

# Carrega funções comuns (para download_with_cache)
if [ -f /etc/customization/utils/common.sh ]; then
    source /etc/customization/utils/common.sh
else
    download_with_cache() { wget --timeout=30 --tries=3 -O "$2" "$1"; }
fi

# Verifica se é administrador (pertence ao grupo sudo)
if groups "$USER" | grep -qE '\b(sudo|admin)\b'; then
    zenity --warning --text="O Certillion não será instalado no usuário administrador ou root.\n\nCrie um novo usuário convencional para instalar." --timeout=15
    exit 1
fi

if [ -d "$HOME/signer-certillion" ]; then
    zenity --info --text="Certillion já está instalado." --timeout=5
    exit 0
fi

zenity --warning --text="1 - Aguarde o instalador iniciar;\n \n2 - Na próxima janela, siga as instruções do instalador;\n \n3 - Esta janela se fecha em 30s." --width=650 --height=150 --timeout=30 &

INSTALLER="/tmp/Assinador-Certillion-1.7.3.run"
CACHE_FILE="/tmp/cache/Assinador-Certillion-1.7.3.run"

if [ -f "$CACHE_FILE" ]; then
    # OTIMIZAÇÃO 1.2/1.3: verifica tamanho antes de copiar
    if [ -f "$INSTALLER" ] && [ $(stat -c%s "$INSTALLER" 2>/dev/null || echo 0) -eq $(stat -c%s "$CACHE_FILE" 2>/dev/null || echo -1) ]; then
        log_info "✅ Instalador já presente e idêntico ao cache."
    else
        cp "$CACHE_FILE" "$INSTALLER"
        log_info "✅ Instalador copiado do cache NFS"
    fi
else
    download_with_cache "https://download.certillion.com/signer/installer/linux/Assinador-Certillion-1.7.3.run" "$INSTALLER"
fi

chmod +x "$INSTALLER"
mkdir -p "$HOME/signer-certillion"
"$INSTALLER"

# Cria atalho no desktop
if [ -f "$HOME/.local/share/applications/Certillion.desktop" ]; then
    ln -sf "$HOME/.local/share/applications/Certillion.desktop" "$XDG_DESKTOP_DIR/Certillion.desktop"
fi
zenity --info --text="Certillion instalado com sucesso." --timeout=5
