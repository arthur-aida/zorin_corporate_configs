#!/bin/bash
# =============================================================================
# setup-server-KVM-nfs-acng.sh - Configuração do Servidor de Cache e KVM
# =============================================================================
#        (ESTE SCRIPT FOI IDEALIZADO PARA OTIMIZAR O AMBIENTE DO DEPLOY)
# (CONFIGURE NOS ARQUIVOS DOS PROFILES AS VARIAVEIS DO AMBIENTE PARA O DEPLOY )
# APTCACHER="192.168.122.1", - 192.168.0.1 OU O IP DO APT-CACHER-NG
# CACHEPORT="3142", ALTERE PARA A PORTA INDICADA PELO  PROVEDOR DE ACESSO
# NFSSERVERER="192.168.122.1", - 192.168.3.3 OU O IP DO SERVIDOR NFS
# NFSPORT="2049"
# =============================================================================
# (POSTERIORMENTE PREPARADO PARA INSTALAR E PROVER CACHES PARA UMA REDE LOCAL)
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# FUNÇÕES DE LOG
# -----------------------------------------------------------------------------
log_info()    { echo "[INFO]    $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_warning() { echo "[WARN]    $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }
log_error()   { echo "[ERROR]   $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }
log_success() { echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_step()    { echo ""; echo "========================================="; echo "[STEP] $(date '+%Y-%m-%d %H:%M:%S') - $*"; echo "========================================="; }

# -----------------------------------------------------------------------------
# CONSTANTES
# -----------------------------------------------------------------------------
STORAGE_BASE="/partimag"
CACHE_DIR="${STORAGE_BASE}/cache"
FLATPAK_CACHE_DIR="${STORAGE_BASE}/flatpakcache"
ACNG_CACHE_DIR="/var/cache/apt-cacher-ng"
ACNG_CONF="/etc/apt-cacher-ng/acng.conf"
BACKUP_DIR="/etc/apt-cacher-ng/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# -----------------------------------------------------------------------------
# PERSONALIZAÇÃO DO CACHE FLATPAK
# -----------------------------------------------------------------------------
# Obtém a lista de branches disponíveis, extrai os números de versão e encontra o mais alto
V_freedesktop=$(flatpak remote-ls flathub --arch=x86_64 --columns=ref | grep 'org.freedesktop.Platform/x86_64/' | cut -d'/' -f4 | sort -V | tail -n1)
V_gnome=$(flatpak remote-ls flathub --arch=x86_64 --columns=ref | grep 'runtime/org.gnome.Platform/x86_64/' | cut -d'/' -f4 | sort -V | tail -n1)

#FLATPAK_REFS="${FLATPAK_REFS:-runtime/org.freedesktop.Platform/x86_64/$V_freedesktop runtime/org.gnome.Platform/x86_64/$V_gnome org.keepassxc.KeePassXC com.obsproject.Studio org.jitsi.jitsi-meet io.github.nroduit.Weasis br.app.pw3270.terminal }"
FLATPAK_REFS="${FLATPAK_REFS:-runtime/org.freedesktop.Platform/x86_64/$V_freedesktop runtime/org.gnome.Platform/x86_64/$V_gnome }"
FORCE_FLATPAK_CACHE="${FORCE_FLATPAK_CACHE:-0}"

# -----------------------------------------------------------------------------
# FUNÇÃO: Verifica se está rodando como root
# -----------------------------------------------------------------------------
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script deve ser executado como root (sudo)."
        exit 1
    fi
    log_info "Executando como root."
}

# -----------------------------------------------------------------------------
# FUNÇÃO: Verifica se a virtualização é suportada
# -----------------------------------------------------------------------------
check_virtualization_support() {
    log_step "VERIFICANDO SUPORTE À VIRTUALIZAÇÃO"
    
    if [ $(egrep -c '(vmx|svm)' /proc/cpuinfo) -eq 0 ]; then
        log_warning "Virtualização desativada ou não suportada pela CPU."
        log_warning "O KVM não funcionará, mas os demais serviços serão configurados."
        log_info "Continuando sem suporte KVM..."
        return 1
    else
        log_success "Virtualização suportada pela CPU."
        return 0
    fi
}

# -----------------------------------------------------------------------------
# FUNÇÃO: Instala dependências
# -----------------------------------------------------------------------------
install_dependencies() {
    log_step "INSTALANDO DEPENDÊNCIAS"

    local APPS=("apt-cacher-ng" "nfs-kernel-server" "nfs-common" "flatpak" 
                "qemu-kvm" "libvirt-daemon-system" "libvirt-clients" 
                "bridge-utils" "virt-manager" "virtinst" "sshfs" "acl" "net-tools"
                "ufw" "openssh-server" "socat")
    
    log_info "Atualizando listas de pacotes..."
    if ! apt update 2>&1; then
        log_warning "apt update reportou erros (pode ser falta de conectividade)."
        log_warning "Tentando continuar mesmo assim..."
    fi
    apt upgrade -y 2>/dev/null || true

    log_info "Instalando pacotes necessários..."
    if apt install -y "${APPS[@]}" 2>&1; then
        log_success "Pacotes instalados com sucesso."
    else
        log_error "Falha na instalação de alguns pacotes."
        log_warning "Isso pode ser devido à falta de conectividade com a internet."
        log_warning "Verifique sua conexão e tente novamente."
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# FUNÇÃO: Detecta e configura storage externo
# -----------------------------------------------------------------------------
setup_storage() {
    log_step "CONFIGURANDO STORAGE"
    
    mkdir -p "$CACHE_DIR" "$FLATPAK_CACHE_DIR"
    
    local STORAGE_EXTERNAL=$(find /media -maxdepth 3 -type d -name "partimag" 2>/dev/null | head -1)
    
    if [ -n "$STORAGE_EXTERNAL" ]; then
        log_info "Storage externo detectado em: $STORAGE_EXTERNAL"
        log_info "Copiando caches existentes (modo update, sem sobrescrever)..."
        
        [ -d "$STORAGE_EXTERNAL/cache" ] && \
            cp -ru "$STORAGE_EXTERNAL/cache/." "$CACHE_DIR/" 2>/dev/null && \
            log_info "Cache APT copiado do storage externo."
        
        [ -d "$STORAGE_EXTERNAL/flatpakcache" ] && \
            cp -ru "$STORAGE_EXTERNAL/flatpakcache/." "$FLATPAK_CACHE_DIR/" 2>/dev/null && \
            log_info "Cache Flatpak copiado do storage externo."
        
        [ -d "$STORAGE_EXTERNAL/apt-cacher-ng" ] && \
            cp -ru "$STORAGE_EXTERNAL/apt-cacher-ng/." "$ACNG_CACHE_DIR/" 2>/dev/null && \
            log_info "Cache APT-Cacher-NG copiado do storage externo."
    else
        log_info "Nenhum storage externo detectado em /media."
        log_info "Os caches serão criados localmente em $STORAGE_BASE."
        log_info "Certifique-se de ter pelo menos 20GB disponíveis nesta partição."
    fi
}

# -----------------------------------------------------------------------------
# FUNÇÃO: Configurar / recriar cache Flatpak (CORRIGIDA)
# -----------------------------------------------------------------------------
setup_flatpak_cache() {
    local force="${FORCE_FLATPAK_CACHE:-0}"
    [ "${1:-}" = "--force" ] && force=1

    log_step "CONFIGURANDO CACHE FLATPAK (LOCAL)"

    if ! command -v flatpak >/dev/null 2>&1; then
        log_error "Flatpak não está instalado. Execute 'install_dependencies' primeiro."
        return 1
    fi

    local CACHE_DIR="$FLATPAK_CACHE_DIR"
    local OSTREE_REPO="$CACHE_DIR/.ostree/repo"

    if [ "$force" -eq 1 ]; then
        log_warning "FORCE_FLATPAK_CACHE=1 – removendo cache antigo..."
        rm -rf "$CACHE_DIR"
    fi

    # Se o repositório ostree já existe e contém objetos, não recria
    if [ -d "$OSTREE_REPO" ] && [ "$(ls -A "$OSTREE_REPO/objects" 2>/dev/null)" ]; then
        log_info "Cache Flatpak já populado em $OSTREE_REPO. Use --rebuild-flatpak para recriar."
        return 0
    fi

    if ! ping -c 1 -W 2 flathub.org >/dev/null 2>&1; then
        log_warning "Sem conectividade com a Internet. O cache Flatpak NÃO será recriado."
        return 0
    fi

    # Cria uma instalação temporária para baixar os pacotes
    local TEMP_NAME="temp-cache-builder"
    local TEMP_DIR="/tmp/flatpak-cache-build-$$"
    local TEMP_CONF="/etc/flatpak/installations.d/${TEMP_NAME}.conf"

    mkdir -p "$TEMP_DIR" "$(dirname "$TEMP_CONF")"
    cat <<EOF > "$TEMP_CONF"
[Installation "$TEMP_NAME"]
Path=$TEMP_DIR
DisplayName=Temporary cache builder
StorageType=harddisk
EOF

    log_info "Instalação temporária criada em $TEMP_DIR"

    flatpak --installation="$TEMP_NAME" remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    log_success "Remoto flathub adicionado à instalação temporária."

    flatpak --installation="$TEMP_NAME" remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak --installation="$TEMP_NAME" remote-modify --collection-id=org.flathub.Stable flathub
    log_success "Remoto flathub configurado com collection-id."

    log_info "Baixando runtimes/aplicações básicos..."
    for ref in $FLATPAK_REFS; do
        log_info "  → Instalando $ref ..."
        if flatpak install --installation="$TEMP_NAME" -y --noninteractive flathub "$ref" 2>&1; then
            log_success "    $ref instalado com sucesso."
        else
            log_warning "    Falha ao instalar $ref (pode não existir ou erro de rede)."
        fi
    done

    # Prepara diretório de destino
    mkdir -p "$CACHE_DIR"

    # Exporta os refs para o formato USB (repo ostree puro) – estrutura .ostree/repo
    log_info "Exportando cache para $CACHE_DIR (.ostree/repo)..."
    if flatpak create-usb --installation="$TEMP_NAME" "$CACHE_DIR" $FLATPAK_REFS 2>&1; then
        log_success "Cache Flatpak exportado com sucesso para $OSTREE_REPO"
    else
        log_error "Falha ao exportar cache Flatpak."
        rm -f "$TEMP_CONF"
        rm -rf "$TEMP_DIR"
        return 1
    fi

    # Ajusta permissões para acesso via NFS (nobody:nogroup)
    chown -R nobody:nogroup "$CACHE_DIR/.ostree" 2>/dev/null || true
    chmod -R 755 "$CACHE_DIR/.ostree" 2>/dev/null || true

    # Remove instalação temporária
    rm -f "$TEMP_CONF"
    rm -rf "$TEMP_DIR"
    log_info "Instalação temporária removida."

    log_success "Cache Flatpak recriado em $CACHE_DIR (.ostree/repo)"
}

# -----------------------------------------------------------------------------
# FUNÇÃO: Configura rede (NFS) – com opção 'insecure' e cálculo correto
# -----------------------------------------------------------------------------
setup_network() {
    log_step "CONFIGURANDO REDE (NFS) – KVM + LAN"

    local I_P=$(ip addr show virbr0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    
    if [ -z "$I_P" ]; then
        log_warning "Interface virbr0 não encontrada."
        log_warning "Tentando iniciar libvirtd..."
        systemctl start libvirtd 2>/dev/null || true
        sleep 2
        I_P=$(ip addr show virbr0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
        if [ -z "$I_P" ]; then
            log_warning "Ainda não foi possível detectar virbr0."
            I_P="192.168.122.1"
        fi
    fi
    log_info "IP da interface KVM (virbr0): $I_P"
    local KVM_SUBNET="${I_P%.*}.0/24"

    local LAN_SUBNET=""
    local LAN_IFACE=""
    local LAN_IP_CIDR=""
    local IFACE_DEFAULT=$(ip route show default 2>/dev/null | awk '{print $5}' | head -1)
    if [ -n "$IFACE_DEFAULT" ] && [ "$IFACE_DEFAULT" != "virbr0" ]; then
        LAN_IFACE="$IFACE_DEFAULT"
        LAN_IP_CIDR=$(ip -o -4 addr show "$LAN_IFACE" | awk '{print $4}' | head -1)
        if [ -n "$LAN_IP_CIDR" ]; then
            local ip="${LAN_IP_CIDR%/*}"
            local mask="${LAN_IP_CIDR#*/}"
            local octets=()
            IFS='.' read -r -a octets <<< "$ip"
            local mask_int=$(( (0xffffffff << (32 - mask)) & 0xffffffff ))
            local o0=$(( octets[0] & (mask_int >> 24) ))
            local o1=$(( octets[1] & (mask_int >> 16 & 0xff) ))
            local o2=$(( octets[2] & (mask_int >> 8  & 0xff) ))
            local o3=$(( octets[3] & (mask_int       & 0xff) ))
            local subnet_ip="${o0}.${o1}.${o2}.${o3}"
            LAN_SUBNET="${subnet_ip}/${mask}"
            log_info "Interface LAN detectada: $LAN_IFACE ($LAN_IP_CIDR), sub‑rede $LAN_SUBNET"
        else
            log_warning "Interface $LAN_IFACE sem IP (ignorada)."
        fi
    else
        log_info "Nenhuma interface LAN adicional encontrada (apenas KVM?)."
    fi

    echo "# Exports gerados automaticamente por setup-server-KVM-nfs-acng.sh" > /etc/exports
    echo "# Data: $(date)" >> /etc/exports

    echo "/partimag $KVM_SUBNET(rw,sync,no_subtree_check,insecure,anonuid=65534,anongid=65534,all_squash)" >> /etc/exports
    log_info "Exportação adicionada: KVM $KVM_SUBNET"

    if [ -n "$LAN_SUBNET" ]; then
        echo "/partimag $LAN_SUBNET(rw,sync,no_subtree_check,insecure,anonuid=65534,anongid=65534,all_squash)" >> /etc/exports
        log_info "Exportação adicionada: LAN $LAN_SUBNET"
    fi

    log_success "Arquivo /etc/exports configurado para KVM e LAN."
}

# -----------------------------------------------------------------------------
# FUNÇÃO: Configura firewall UFW
# -----------------------------------------------------------------------------
setup_firewall() {
    log_step "CONFIGURANDO FIREWALL (UFW) PARA NFS"

    if ! command -v ufw >/dev/null 2>&1; then
        log_warning "UFW não está instalado. Pulando configuração de firewall."
        return 0
    fi

    ufw --force enable 2>/dev/null || true

    if [ -n "${LAN_IFACE:-}" ]; then
        ufw allow in on "$LAN_IFACE" to any port 22 2>/dev/null || true
        ufw allow in on "$LAN_IFACE" to any port nfs 2>/dev/null || true
        ufw allow in on "$LAN_IFACE" to any port 111 2>/dev/null || true
        ufw allow in on "$LAN_IFACE" to any port 2049 2>/dev/null || true
        ufw allow in on "$LAN_IFACE" to any port 3142 2>/dev/null || true
        ufw allow in on "$LAN_IFACE" to any port 9876 proto tcp 2>/dev/null || true
        log_info "Firewall configurado para SSH/NFS/ACNG na interface $LAN_IFACE."
    else
        ufw allow 22 2>/dev/null || true
        ufw allow nfs 2>/dev/null || true
        ufw allow 111 2>/dev/null || true
        ufw allow 2049 2>/dev/null || true
        ufw allow 3142 2>/dev/null || true
        ufw allow 9876 2>/dev/null || true
        log_info "Firewall configurado globalmente."
    fi

    ufw reload 2>/dev/null || true
    log_success "Firewall atualizado."
}

# -----------------------------------------------------------------------------
# FUNÇÃO: Configura permissões e serviços
# -----------------------------------------------------------------------------
setup_permissions_and_services() {
    log_step "CONFIGURANDO PERMISSÕES E SERVIÇOS"
    
    log_info "Ajustando permissões do APT-Cacher-NG..."
    chown -R apt-cacher-ng:apt-cacher-ng "$ACNG_CACHE_DIR" 2>/dev/null || \
        log_warning "Não foi possível ajustar permissões do ACNG."
    
    log_info "Ajustando permissões do storage compartilhado..."
    chown -R nobody:nogroup "$STORAGE_BASE" 2>/dev/null || \
        log_warning "Não foi possível ajustar owner do storage."
    chmod -R 775 "$STORAGE_BASE" 2>/dev/null || \
        log_warning "Não foi possível ajustar permissões do storage."
    
    if command -v setfacl >/dev/null 2>&1; then
        setfacl -R -m d:u:nobody:rwx,d:g:nogroup:rwx,d:o::rx "$STORAGE_BASE/" 2>/dev/null || \
            log_warning "Não foi possível configurar ACLs."
    fi
    
    log_info "Exportando compartilhamentos NFS..."
    exportfs -ra 2>&1 && log_success "Compartilhamentos NFS exportados." || \
        log_warning "Falha ao exportar NFS (pode não ser crítico)."
    
    log_info "Habilitando e iniciando serviços..."
    
    systemctl enable --now apt-cacher-ng 2>&1 && \
        log_success "APT-Cacher-NG habilitado." || \
        log_warning "Falha ao habilitar APT-Cacher-NG."
    
    systemctl enable --now nfs-kernel-server 2>&1 && \
        log_success "NFS Server habilitado." || \
        log_warning "Falha ao habilitar NFS Server."
    
    systemctl enable --now libvirtd 2>&1 && \
        log_success "libvirtd habilitado." || \
        log_warning "Falha ao habilitar libvirtd."
}

# -----------------------------------------------------------------------------
# FUNÇÃO: Configura o APT-Cacher-NG
# -----------------------------------------------------------------------------
setup_apt_cacher_ng() {
    log_step "CONFIGURANDO APT-CACHER-NG"
    
    mkdir -p "$BACKUP_DIR"
    
    if [ -f "$ACNG_CONF" ]; then
        cp "$ACNG_CONF" "$BACKUP_DIR/acng.conf.bak_$TIMESTAMP"
        log_info "Backup da configuração anterior: $BACKUP_DIR/acng.conf.bak_$TIMESTAMP"
    fi
    
    log_info "Aplicando configuração otimizada..."
    
    cat <<EOF | tee "$ACNG_CONF" > /dev/null
CacheDir: /var/cache/apt-cacher-ng
LogDir: /var/log/apt-cacher-ng
SupportDir: /usr/lib/apt-cacher-ng
Port: 3142
ReportPage: acng-report.html
ExThreshold: 2

AllowUserPorts: 80 443

VfilePatternEx: (^/\?[^/]*\.(deb|udeb|dsc|tar\.(gz|xz|bz2|zst)|diff\.(gz|bz2))$|^/\?index\.[^/]*$|^/\?$|^/HTTPS///.*$|^/(__sinfo|bugs|changelogs|patches|acng-report\.html|favicon\.ico)/.*$|^/InRelease$|^/Release(\.gpg)?$|^/Packages(\.(gz|bz2|xz|lzma|lz4|zst))?$|^/Sources(\.(gz|bz2|xz|lzma|lz4|zst))?$|^/Translation-[^/]*\.(gz|bz2|xz|lzma|lz4|zst)?$|^/Components-[^/]*\.yml(\.(gz|bz2|xz|lzma|lz4|zst))?$|^/icons-[^/]*\.tar(\.(gz|bz2|xz|lzma|lz4|zst))?$|^/Contents-[^/]*\.(gz|bz2|xz|lzma|lz4|zst)?$|^/cnf/Commands-[^/]*\.(gz|bz2|xz|lzma|lz4|zst)?$)

Remap-ubuntu: /ubuntu ; http://archive.ubuntu.com/ubuntu
Remap-ubusec: /ubuntu-security ; http://security.ubuntu.com/ubuntu

Remap-zorin-stable: /packages.zorinos.com/stable ; https://packages.zorinos.com/stable
Remap-zorin-patches: /packages.zorinos.com/patches ; https://packages.zorinos.com/patches
Remap-zorin-apps: /packages.zorinos.com/apps ; https://packages.zorinos.com/apps
Remap-zorin-drivers: /packages.zorinos.com/drivers ; https://packages.zorinos.com/drivers
Remap-zorin: /packages.zorinos.com ; https://packages.zorinos.com

Remap-brave: /brave-browser-apt-release.s3.brave.com ; https://brave-browser-apt-release.s3.brave.com

Remap-ppa: /ppa.launchpadcontent.net ; https://ppa.launchpadcontent.net

Remap-canonical: /partner ; http://archive.canonical.com
EOF
    
    log_success "Configuração do APT-Cacher-NG aplicada."
    
    log_info "Reiniciando APT-Cacher-NG..."
    if systemctl restart apt-cacher-ng 2>&1; then
        log_success "APT-Cacher-NG reiniciado com sucesso."
    else
        log_error "Falha ao reiniciar APT-Cacher-NG."
        return 1
    fi
    
    log_info "Verificando se o APT-Cacher-NG está respondendo..."
    if curl -s -o /dev/null -w "%{http_code}" --max-time 3 "http://localhost:3142/" 2>/dev/null | grep -q "406\|200"; then
        log_success "APT-Cacher-NG respondendo na porta 3142."
    else
        log_warning "APT-Cacher-NG pode não estar respondendo."
    fi
}

# -----------------------------------------------------------------------------
# FUNÇÃO: Configura socket TCP para rebuild remoto do cache Flatpak
# -----------------------------------------------------------------------------
setup_flatpak_rebuild_listener() {
    log_step "CONFIGURANDO LISTENER PARA REBUILD DO FLATPAK"

    local SERVICE_NAME="flatpak-rebuild"
    local SOCKET_FILE="/etc/systemd/system/${SERVICE_NAME}.socket"
    local SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}@.service"
    local TRIGGER_SCRIPT="/usr/local/bin/flatpak-rebuild-trigger.sh"
    local PORT=9876

    # Obtém o IP da virbr0 de forma independente
    local BIND_IP=$(ip addr show virbr0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    BIND_IP="${BIND_IP:-192.168.122.1}"

    # Script executado quando alguém conecta ao socket
    cat <<'EOF' > "$TRIGGER_SCRIPT"
#!/bin/bash
# Recebe a conexão e executa o rebuild imediatamente
/usr/local/bin/setup-server-KVM-nfs-acng.sh --rebuild-flatpak
EOF
    chmod +x "$TRIGGER_SCRIPT"

    # Arquivo de socket
    cat <<EOF > "$SOCKET_FILE"
[Unit]
Description=Socket for Flatpak cache rebuild trigger

[Socket]
ListenStream=${BIND_IP}:${PORT}
Accept=yes
# Restringe a apenas uma conexão pendente por vez
MaxConnections=1

[Install]
WantedBy=sockets.target
EOF

    # Arquivo de serviço associado
    cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Flatpak cache rebuild service
After=network.target

[Service]
Type=oneshot
ExecStart=-/usr/local/bin/flatpak-rebuild-trigger.sh
StandardInput=socket
EOF

    # Recarrega systemd e ativa o socket
    systemctl daemon-reload
    systemctl enable --now "${SERVICE_NAME}.socket" 2>&1 && \
        log_success "Listener de rebuild Flatpak ativo em ${BIND_IP}:${PORT}" || \
        log_warning "Falha ao ativar socket de rebuild."
}

# -----------------------------------------------------------------------------
# FUNÇÃO: Exibe resumo final
# -----------------------------------------------------------------------------
show_summary() {
    log_step "RESUMO DA CONFIGURAÇÃO"
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║     AMBIENTE DE DESENVOLVIMENTO CONFIGURADO COM SUCESSO      ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║                                                              ║"
    echo "║  Serviços configurados:                                      ║"
    echo "║    - APT-Cacher-NG (cache de pacotes .deb)                   ║"
    echo "║    - NFS Server (compartilhamento de cache)                  ║"
    echo "║    - libvirtd (gerenciamento de VMs KVM)                     ║"
    echo "║    - Flatpak (cache local em $FLATPAK_CACHE_DIR/.ostree/repo) ║"
    echo "║                                                              ║"
    echo "║  Porta APT-Cacher-NG: 3142                                   ║"
    echo "║                                                              ║"
    if [ -n "${LAN_SUBNET:-}" ]; then
    echo "║  Compartilhamento NFS para LAN:                              ║"
    echo "║    - Interface: ${LAN_IFACE:-N/D}                                ║"
    echo "║    - Sub‑rede: ${LAN_SUBNET:-N/D}                                 ║"
    echo "║                                                              ║"
    fi
    echo "║  PRÓXIMOS PASSOS:                                            ║"
    echo "║    1. REINICIE o sistema para carregar o KVM                 ║"
    echo "║       sudo reboot                                            ║"
    echo "║    2. Execute os comandos abaixo para ajuda:                 ║"
    echo "║       cd /etc/customization/                                 ║"
    echo "║       bash main.sh                                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""

    log_success "Configuração do servidor concluída."
    log_info "APT-Cacher-NG: http://localhost:3142"
    log_info "APT-Cacher-NG: http://$LAN_SUBNET:3142"
    log_info "Storage NFS: $STORAGE_BASE (compartilhado na rede KVM e LAN)"
    log_info "Reinicie para carregar os módulos do KVM."
}

# =============================================================================
# EXECUÇÃO PRINCIPAL
# =============================================================================
main() {
    log_step "INICIANDO CONFIGURAÇÃO DO SERVIDOR"
    log_info "Data: $(date)"
    log_info "Hostname: $(hostname)"
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  CONFIGURAÇÃO DO SERVIDOR DE CACHE E KVM     (DEPLOY E LAN)  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    check_root
    check_virtualization_support
    install_dependencies
    setup_storage
    setup_network
    setup_firewall
    setup_flatpak_cache
    setup_flatpak_rebuild_listener
    setup_permissions_and_services
    setup_apt_cacher_ng
    show_summary
    
    # Define entrada no cron a ser adicionada
    CRON_ENTRIES=(
    "@reboot root find /partimag/cache/ -type f -atime +90 -delete"
    )
    # Verifica e adiciona a entrada se não existir
    for entry in "${CRON_ENTRIES[@]}"; do
     if ! grep -Fxq "$entry" /etc/crontab 2>/dev/null; then
        echo "$entry" >> /etc/crontab
        log_info "✅ Tarefa cron adicionada: $entry"
     else
        log_info "Tarefa cron já existente: $entry"
     fi
    done
}

# -----------------------------------------------------------------------------
# SUPORTE A ARGUMENTO --rebuild-flatpak (recriação isolada)
# -----------------------------------------------------------------------------
if [ "${1:-}" = "--rebuild-flatpak" ]; then
    check_root
    install_dependencies
    setup_flatpak_cache --force
    log_success "Cache Flatpak recriado com sucesso."
    exit 0
fi

main "$@"
