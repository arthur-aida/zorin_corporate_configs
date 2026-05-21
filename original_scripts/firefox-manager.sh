#!/bin/bash
# firefox-manager.sh - Gerencia instalação/atualização do Firefox (stable ou ESR)
# Uso: firefox-manager.sh [stable|esr]

set -euo pipefail

# Carrega funções comuns (inclui download_with_cache e log_*)
source /etc/customization/utils/common.sh || {
    echo "ERRO: Não foi possível carregar /etc/customization/utils/common.sh" >&2
    exit 1
}

# Verifica se é root
if [[ $EUID -ne 0 ]]; then
    log_error "Este script deve ser executado como root"
    exit 1
fi

# Ajuda
usage() {
    cat <<EOF
Uso: $(basename "$0") [stable|esr]

  stable   - Instala/atualiza a versão estável do Firefox (canal latest)
  esr      - Instala/atualiza a versão ESR (Extended Support Release)

Exemplo:
  $0 stable
  $0 esr
EOF
    exit 0
}

# Parâmetro obrigatório
if [[ $# -ne 1 ]]; then
    usage
fi

case "$1" in
    stable)
        MODE="stable"
        FFCHANNEL="latest"
        INSTALL_DIR="/OPT/firefox"        # Atenção: maiúsculo /OPT
        BINARY_LINK="/usr/bin/firefox"
        DESKTOP_FILE="/usr/share/applications/firefox.desktop"
        DESKTOP_NAME="Navegador Firefox"
        DESKTOP_EXEC="/usr/bin/firefox %u"
        ICON_PATH="/OPT/firefox/browser/chrome/icons/default/default48.png"
        TARBALL_TEMP="/tmp/firefox.tar.xz"
        ;;
    esr)
        MODE="esr"
        FFCHANNEL="esr-latest"
        INSTALL_DIR="/opt/firefox"        # minúsculo /opt
        BINARY_LINK="/usr/bin/firefox-esr"
        DESKTOP_FILE="/usr/share/applications/firefox-esr.desktop"
        DESKTOP_NAME="Mozilla-ESR HOD"
        DESKTOP_EXEC="/usr/bin/firefox-esr https://hod.serpro.gov.br"
        ICON_PATH="/OPT/firefox/icons/updater.png"   # Nota: mantido conforme original, mas pode não existir
        TARBALL_TEMP="/tmp/firefox-esr.tar.xz"
        ;;
    *)
        echo "Opção inválida: $1"
        usage
        ;;
esac

log_info "Iniciando gerenciamento do Firefox ($MODE)..."

# Remove versões antigas de snap, flatpak e apt (se existirem)
log_info "Removendo pacotes conflitantes..."
if command -v snap &>/dev/null; then
    snap remove --purge firefox 2>/dev/null || true
fi
if command -v flatpak &>/dev/null; then
    flatpak uninstall org.mozilla.firefox -y 2>/dev/null || true
fi
if dpkg --get-selections 2>/dev/null | grep -q "^firefox[[:space:]]"; then
    apt purge firefox -y 2>/dev/null || true
fi

# Cria diretório de instalação se não existir
mkdir -p "$INSTALL_DIR"

# Detecta arquitetura e define suffix para URL
ARCH=${ARCH:-$(uname -m)}
if [[ "$ARCH" = x86_64 ]]; then
    LIBDIRSUFFIX="64"
elif [[ "$ARCH" = i?86 ]]; then
    ARCH="i686"
    LIBDIRSUFFIX=""
else
    log_error "Arquitetura $ARCH não suportada"
    exit 1
fi

# Define idioma padrão
FFLANG=${FFLANG:-pt-BR}

# Obtém a versão mais recente via redirecionamento
# Obtém a versão mais recente via redirecionamento
log_info "Obtendo número da versão mais recente do canal $FFCHANNEL..."
VERSION_URL="https://download.mozilla.org/?product=firefox-${FFCHANNEL}&os=linux${LIBDIRSUFFIX}&lang=${FFLANG}"

# Executa o wget e captura a saída. O '|| true' garante que o código de erro 8 (ou qualquer outro)
# não interrompa o script, pois neste contexto a saída (stderr) ainda é processada.
# O pipe para 'sed' extrai a versão do cabeçalho 'Location'.
VERSION=$( { wget --spider -S --max-redirect 0 "$VERSION_URL" 2>&1 || true; } | sed -n '/Location: /{s|.*/firefox-\(.*\)\.tar.*|\1|p;q;}' )

# Verifica se a versão foi encontrada, independentemente do código de retorno do wget.
if [[ -z "$VERSION" ]]; then
    log_error "Não foi possível determinar a versão mais recente."
    log_error "URL tentada: $VERSION_URL"
    exit 1
fi
log_info "Versão detectada: $VERSION"

# Verifica se a versão já está instalada (usa arquivo application.ini)
if [[ -f "$INSTALL_DIR/application.ini" ]]; then
    INSTALLED_VER=$(grep "^Version=" "$INSTALL_DIR/application.ini" | cut -d= -f2 | tr -d ' ')
    if [[ "$INSTALLED_VER" == "$VERSION" ]]; then
        log_info "Firefox $MODE já está na versão $VERSION. Nada a fazer."
        exit 0
    else
        log_info "Atualizando de $INSTALLED_VER para $VERSION"
    fi
fi

# Constrói URL completa do pacote
FIREFOX_URL="https://download.mozilla.org/?product=firefox-${VERSION}&os=linux${LIBDIRSUFFIX}&lang=${FFLANG}"

# Baixa o tarball usando cache NFS (função do common.sh)
log_info "Baixando Firefox $MODE versão $VERSION..."
if download_with_cache "$FIREFOX_URL" "$TARBALL_TEMP"; then
    log_info "Download concluído com sucesso (cache utilizado se disponível)"
else
    log_error "Falha no download do Firefox"
    exit 1
fi

# Extrai para o diretório de instalação (sobrescreve arquivos existentes)
log_info "Extraindo para $INSTALL_DIR..."
tar -xf "$TARBALL_TEMP" --overwrite-dir -C "$(dirname "$INSTALL_DIR")"

# Remove o arquivo temporário
rm -f "$TARBALL_TEMP"

# Cria link simbólico do binário
ln -sf "$INSTALL_DIR/firefox" "$BINARY_LINK"

# Biblioteca de certificados: substitui pela do sistema (p11-kit)
NSS_LIB="$INSTALL_DIR/libnssckbi.so"
if [[ -f "$NSS_LIB" ]]; then
    if [[ $(stat -c%s "$NSS_LIB") -ne 0 ]]; then
        rm -f "$NSS_LIB"
        ln -sf /usr/lib/x86_64-linux-gnu/pkcs11/p11-kit-trust.so "$NSS_LIB"
        log_info "Link dinâmico de certificados configurado"
    fi
fi

# Recria/atualiza o arquivo .desktop
log_info "Criando/atualizando arquivo .desktop em $DESKTOP_FILE"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=$VERSION
Type=Application
Name=$DESKTOP_NAME
Comment=Navegador da internet
Exec=$DESKTOP_EXEC
Icon=$ICON_PATH
Terminal=false
Categories=Network
EOF
# Adiciona Keywords apenas para stable (ESR original não tinha)
if [[ "$MODE" == "stable" ]]; then
    echo "Keywords=Web;Browser;Navegador;Internet;Explorador;Entrar;Abrir;Explorar;Baixar;Surfar;" >> "$DESKTOP_FILE"
fi
chmod 644 "$DESKTOP_FILE"
chmod +x "$DESKTOP_FILE"

# Para ESR, ainda executa o hook do Java (original chamava /etc/hookjava1.8.sh)
if [[ "$MODE" == "esr" && -x /etc/hookjava1.8.sh ]]; then
    log_info "Executando hook Java para ESR..."
    /etc/hookjava1.8.sh
fi

log_info "Firefox $MODE versão $VERSION instalado/atualizado com sucesso."
exit 0
