#!/bin/bash
# deploy.sh - Instalação rápida a partir do GitHub
# Uso: sudo bash deploy.sh
# Pre KVM-linux:
# mkdir vm; qemu-img create -f qcow2 vm/vm`date +%s`.qcow2 74G; qemu-img convert -f raw -O qcow2 -o preallocation=metadata /caminho/vm.raw /caminho/vm.qcow2

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# URL do repositório (SUBSTITUIR PELO SEU)
REPO_URL="https://github.com/SEU_USUARIO/SEU_REPOSITORIO/archive/refs/heads/main.zip"
DEST_DIR="/etc/customization"
TEMP_DIR="/tmp/customization_$$"
LOG_FILE="/var/log/deploy-customization.log"

log_info()   { echo -e "${GREEN}[INFO]${NC} $*" | tee -a "$LOG_FILE"; }
log_warn()   { echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"; }
log_error()  { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"; exit 1; }

# Verifica se é root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Execute com sudo: sudo bash $0"
    fi
}

# Instala dependências, se necessário
check_deps() {
    local deps=("wget" "unzip")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            log_warn "$dep não encontrado. Instalando..."
            apt-get update -qq && apt-get install -y -qq "$dep"
        fi
    done
}

# Pergunta o perfil numericamente
ask_profile() {
    echo ""
    echo "========================================="
    echo "Selecione o perfil de customização:"
    echo "  1 - Doméstico / Escritório móvel"
    echo "  2 - Corporativo"
    echo "  3 - Saúde"
    echo "========================================="
    read -p "Digite o número do perfil (1-3): " PROFILE_NUM
    case "$PROFILE_NUM" in
        1|2|3) echo "$PROFILE_NUM" ;;
        *) echo "1" ;;
    esac
}

# Download e extração
download_and_extract() {
    log_info "Baixando repositório de $REPO_URL"
    wget -q --show-progress -O "$TEMP_DIR/repo.zip" "$REPO_URL" || log_error "Falha no download"

    log_info "Extraindo para $DEST_DIR"
    unzip -q "$TEMP_DIR/repo.zip" -d "$TEMP_DIR"

    EXTRACTED_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "*-main" | head -1)
    if [ -z "$EXTRACTED_DIR" ]; then
        EXTRACTED_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d ! -path "$TEMP_DIR" | head -1)
    fi
    [ -n "$EXTRACTED_DIR" ] || log_error "Pasta extraída não encontrada"

    # Backup da versão anterior
    if [ -d "$DEST_DIR" ]; then
        BACKUP_DIR="${DEST_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backup: $DEST_DIR -> $BACKUP_DIR"
        mv "$DEST_DIR" "$BACKUP_DIR"
    fi

    mv "$EXTRACTED_DIR" "$DEST_DIR"
    log_info "Scripts copiados para $DEST_DIR"
}

set_permissions() {
    chmod +x "$DEST_DIR/main.sh"
    chmod +x "$DEST_DIR"/modules/*.sh 2>/dev/null || true
    chmod +x "$DEST_DIR"/utils/*.sh 2>/dev/null || true
    chmod +x "$DEST_DIR"/scripts/*.sh 2>/dev/null || true
    chmod +x "$DEST_DIR"/original_scripts/*.sh 2>/dev/null || true
}

run_deploy() {
    local profile="$1"
    log_info "Executando customização com perfil $profile"
    cd "$DEST_DIR"
    bash "$DEST_DIR/main.sh" "$profile"
}

cleanup() {
    rm -rf "$TEMP_DIR"
}

# MAIN
check_root
check_deps
mkdir -p "$TEMP_DIR"

PROFILE=$(ask_profile)

download_and_extract
set_permissions
run_deploy "$PROFILE"
cleanup

log_info "Deploy concluído! Recomenda-se reiniciar o sistema."
# bash main.sh 3 2>&1 | tee /tmp/TXT.txt; mv /tmp/TXT.txt /var/log/customization-persist/TXT.txt; scp /var/log/customization-persist/* administrador@192.168.122.1:/home/administrador/Downloads/Zorin4Business/
