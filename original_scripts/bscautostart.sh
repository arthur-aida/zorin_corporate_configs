#!/bin/bash
# bscautostart.sh - Instala Bonita Studio Community e cria lançador Desktop
# Restrito a usuários comuns (não administradores)

# 1. PREVENÇÃO DE DUPLA EXECUÇÃO
LOCKFILE="/tmp/$(basename "$0").lock"
if [ -f "$LOCKFILE" ]; then
    exit 0
fi
touch "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

source /etc/customization/utils/common.sh 2>/dev/null || { download_with_cache() { wget -O "$2" "$1"; }; }

# 2. VALIDAÇÃO DE SEGURANÇA
if [ "$(id -u)" = "0" ] || groups | grep -qE '\b(sudo|admin)\b'; then
    zenity --warning --text="Bonita Studio não será instalado como root ou por usuários com privilégios de administrador." --timeout=15
    exit 1
fi

APP_DIR="$HOME/BonitaStudioCommunity"
EXEC_NAME="BonitaStudioCommunity"
LAUNCHER_PATH="$HOME/.local/share/applications/bonita-studio.desktop"

# 3. VERIFICAÇÃO DE INSTALAÇÃO EXISTENTE
if [ -d "$APP_DIR" ]; then
    EXEC_FILE=$(find "$APP_DIR" -maxdepth 2 -name "$EXEC_NAME" -type f | head -n 1)
    if [ -n "$EXEC_FILE" ]; then
        chmod +x "$EXEC_FILE"
        "$EXEC_FILE" &
        exit 0
    fi
fi

# 4. DOWNLOAD E EXTRAÇÃO
zenity --warning --text="Iniciando o download e a instalação. Aguarde a aplicação ser iniciada..." --timeout=30 &

TARBALL="/tmp/BonitaStudioCommunity-2024.3-u0-linux.tar.gz"
CACHE_TAR="/tmp/cache/BonitaStudioCommunity-2024.3-u0-linux.tar.gz"

if [ -f "$CACHE_TAR" ]; then
    # OTIMIZAÇÃO 1.2/1.3: verifica tamanho antes de copiar
    if [ -f "$TARBALL" ] && [ $(stat -c%s "$TARBALL" 2>/dev/null || echo 0) -eq $(stat -c%s "$CACHE_TAR" 2>/dev/null || echo -1) ]; then
        log_info "✅ Tarball do Bonita Studio já presente e idêntico ao cache."
    else
        cp "$CACHE_TAR" "$TARBALL"
        log_info "✅ Tarball copiado do cache NFS"
    fi
else
    download_with_cache "https://downloadcenter.bonitapps.com/BonitaStudioCommunity-2024.3-u0-linux.tar.gz" "$TARBALL"
fi

mkdir -p "$APP_DIR"
# Extração sem --strip-components=1 conforme analisado na árvore de arquivos
tar xzf "$TARBALL" -C "$APP_DIR" --warning=no-unknown-keyword

# 5. LOCALIZAÇÃO DO EXECUTÁVEL
EXEC_FILE=$(find "$APP_DIR" -maxdepth 2 -name "$EXEC_NAME" -type f | head -n 1)
ICON_FILE=$(find "$APP_DIR" -maxdepth 2 -name "*.png" | head -n 1)

if [ -z "$EXEC_FILE" ]; then
    zenity --error --text="Erro: Executável não encontrado após a extração."
    exit 1
fi

chmod +x "$EXEC_FILE"

# 6. CRIAÇÃO DO LANÇADOR (DESKTOP ENTRY)
mkdir -p "$HOME/.local/share/applications"

cat <<EOF > "$LAUNCHER_PATH"
[Desktop Entry]
Version=1.0
Type=Application
Name=Bonita Studio Community
Comment=Plataforma de automação de processos de negócio
Exec=$EXEC_FILE
Icon=${ICON_FILE:-system-run}
Terminal=false
Categories=Development;IDE;
Keywords=BPM;Business;Process;
EOF

chmod +x "$LAUNCHER_PATH"

# 7. EXECUÇÃO FINAL
zenity --info --text="Instalação concluída! O atalho foi criado no seu menu de aplicativos." --timeout=10
"$EXEC_FILE" &
