#!/bin/bash
# Script: proxmoxbackupclient.sh (módulo 10-backup)
# Descrição: Instala o cliente Proxmox Backup (proxmox-backup-client) com suporte a cache NFS e conversão de fontes para proxy.
# Compatível com Ubuntu 20.04 (Focal), 22.04 (Jammy), 24.04 (Noble) e derivados (Linux Mint, Zorin OS, etc.)

source /etc/customization/utils/common.sh
set -e

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

# -------------------------------------------------------------------
# Carregar configurações do perfil (om.ips)
# -------------------------------------------------------------------
if [ -f /etc/om.ips ]; then
    source /etc/om.ips
    log_info "Arquivo /etc/om.ips carregado"
else
    log_info "AVISO: /etc/om.ips não encontrado, usando valores padrão."
fi

NFSSERVER="${NFSSERVERER:-192.168.122.1}"
CACHE_PATH="/tmp/cache"
REPO_LIST="/etc/apt/sources.list.d/pbs-client.list"

# -------------------------------------------------------------------
# Montar cache NFS se necessário
# -------------------------------------------------------------------
if [ ! -d "$CACHE_PATH" ]; then
    log_info "Cache NFS não montado em $CACHE_PATH. Tentando montar..."
    mkdir -p "$CACHE_PATH"
    if mount -t nfs -o vers=4.2 "${NFSSERVER}:/partimag/cache" "$CACHE_PATH" 2>/dev/null; then
        log_info "Cache NFS montado com sucesso."
    else
        log_info "AVISO: Falha ao montar cache NFS. Continuando sem cache."
    fi
fi

# -------------------------------------------------------------------
# Detectar distribuição e versão base (Ubuntu ou derivado)
# -------------------------------------------------------------------
detect_os() {
    if [ ! -f /etc/os-release ]; then
        log_error "/etc/os-release não encontrado"
        exit 1
    fi
    . /etc/os-release

    # Para derivados do Ubuntu, usamos a variável UBUNTU_CODENAME se existir,
    # senão tentamos VERSION_CODENAME.
    UBUNTU_CODENAME=""
    if [ -n "$UBUNTU_CODENAME" ]; then
        # Já definida no os-release (ex: Zorin define UBUNTU_CODENAME=noble)
        log_info "UBUNTU_CODENAME encontrado: $UBUNTU_CODENAME"
    elif [ -n "$VERSION_CODENAME" ]; then
        # Fallback: usar VERSION_CODENAME (Ubuntu puro ou Mint)
        UBUNTU_CODENAME="$VERSION_CODENAME"
        log_info "Usando VERSION_CODENAME como base: $UBUNTU_CODENAME"
    else
        log_error "Não foi possível determinar o codinome da base Ubuntu."
        exit 1
    fi

    # Verificar se a distribuição é compatível (Ubuntu ou derivado)
    if [ "$ID" = "ubuntu" ] || [[ "$ID_LIKE" == *"ubuntu"* ]]; then
        log_info "Distribuição $ID (base Ubuntu) detectada. Codinome Ubuntu: $UBUNTU_CODENAME"
    else
        log_error "Distribuição $ID não parece ser derivada do Ubuntu (ID_LIKE=$ID_LIKE). Abortando."
        exit 1
    fi

    # Mapear versões do Linux Mint para o codinome Ubuntu correspondente
    if [ "$ID" = "linuxmint" ]; then
        case "$VERSION_ID" in
            20*) UBUNTU_CODENAME="focal" ;;
            21*) UBUNTU_CODENAME="jammy" ;;
            22*) UBUNTU_CODENAME="noble" ;;
            *)   log_error "Linux Mint versão $VERSION_ID não suportada."; exit 1 ;;
        esac
        log_info "Linux Mint $VERSION_ID mapeado para Ubuntu $UBUNTU_CODENAME"
    fi

    # Validar codinome suportado
    case "$UBUNTU_CODENAME" in
        focal|jammy|noble)
            log_info "Codinome Ubuntu válido: $UBUNTU_CODENAME"
            ;;
        *)
            log_error "Codinome Ubuntu '$UBUNTU_CODENAME' não suportado. Esperado: focal, jammy ou noble."
            exit 1
            ;;
    esac
}

detect_os

# -------------------------------------------------------------------
# Definir o codinome Debian compatível para o Proxmox Backup Client
# Ubuntu 20.04 (focal) -> Debian Bullseye
# Ubuntu 22.04 (jammy) e 24.04 (noble) -> Debian Bookworm
# -------------------------------------------------------------------
DEBIAN_CODENAME=""
case "$UBUNTU_CODENAME" in
    focal)
        DEBIAN_CODENAME="bullseye"
        ;;
    jammy|noble)
        DEBIAN_CODENAME="bookworm"
        ;;
esac
log_info "Usando repositório Debian: $DEBIAN_CODENAME"

# -------------------------------------------------------------------
# Baixar e instalar a chave GPG do Proxmox (com cache)
# -------------------------------------------------------------------
KEY_NAME="proxmox-release-${DEBIAN_CODENAME}.gpg"
KEY_PATH="/usr/share/keyrings/${KEY_NAME}"
TMP_KEY="/tmp/${KEY_NAME}"

# URL da chave (mesma para bullseye e bookworm)
GPG_URL="https://enterprise.proxmox.com/debian/proxmox-release-${DEBIAN_CODENAME}.gpg"
download_with_cache "$GPG_URL" "$TMP_KEY"

# Converter para formato binary .gpg (dearmor) se necessário
if file "$TMP_KEY" | grep -q "ASCII text"; then
    log_info "Convertendo chave ASCII para formato binary .gpg"
    gpg --dearmor -o "$KEY_PATH" "$TMP_KEY"
else
    mv "$TMP_KEY" "$KEY_PATH"
fi
chmod 644 "$KEY_PATH"
log_info "Chave GPG instalada em $KEY_PATH"

# -------------------------------------------------------------------
# Adicionar repositório do cliente Proxmox Backup (pbs-no-subscription)
# -------------------------------------------------------------------
log_info "Configurando repositório para proxmox-backup-client..."
cat > "$REPO_LIST" <<EOF
deb [arch=amd64 signed-by=${KEY_PATH}] http://download.proxmox.com/debian/pbs ${DEBIAN_CODENAME} pbs-no-subscription
EOF
chmod 644 "$REPO_LIST"
log_info "Repositório criado em $REPO_LIST"

# -------------------------------------------------------------------
# Opcional: remover repositório PVE antigo (se existir, para não conflitar)
# -------------------------------------------------------------------
PVE_LIST="/etc/apt/sources.list.d/pvenosub.list"
if [ -f "$PVE_LIST" ]; then
    log_info "Removendo repositório PVE antigo (não necessário)"
    rm -f "$PVE_LIST"
fi

# -------------------------------------------------------------------
# Chamar script de conversão para proxy (Mapeamento Direto)
# -------------------------------------------------------------------
CONVERT_SCRIPT="/etc/customization/scripts/convert-sources-to-proxy.sh"
if [ -x "$CONVERT_SCRIPT" ]; then
    log_info "🔄 Convertendo repositórios recém-criados para Mapeamento Direto (proxy)..."
    if bash "$CONVERT_SCRIPT"; then
        log_info "✅ Conversão local concluída."
    else
        log_info "⚠️ AVISO: Falha na conversão. As URLs originais serão mantidas."
    fi
else
    log_info "⚠️ Script de conversão não encontrado. Continuando sem proxy."
fi

# -------------------------------------------------------------------
# Atualizar listas de pacotes e instalar o cliente
# -------------------------------------------------------------------
log_info "Atualizando listas de pacotes..."
apt-get update -qq

log_info "Instalando proxmox-backup-client e qrencode..."
apt-get install -y qrencode proxmox-backup-client

log_info "✅ Cliente Proxmox Backup instalado com sucesso."
