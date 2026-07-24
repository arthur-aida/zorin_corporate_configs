#!/bin/bash
# main.sh - Script principal de customização
# =============================================================================
# PROPÓSITO:
#   Orquestrador central para deploy de perfis corporativos em Zorin OS.
#   Coordena execução de 15 módulos de configuração com suporte a:
#     - Execução paralela e sequencial conforme necessário
#     - Sistema de cache inteligente (APT-Cacher-NG + NFS)
#     - Tratamento robusto de erros com recuperação granular
#     - Validação de pré-requisitos (preflight checks)
#     - Logging estruturado e auditoria completa
#
# CARACTERÍSTICAS DE ROBUSTEZ:
#   ✅ Proteção contra interrupção abrupta (trap handlers)
#   ✅ Módulos executados com set +e
#   ✅ Falhas capturadas em array FAILED_MODULES para relatório final
#   ✅ Lógica de --skip-errors para debug granular
#   ✅ Persistência de perfil ativo para ferramentas independentes
#   ✅ Timeout inteligente e testes de conectividade
#   ✅ Verificação de espaço em disco e lock de APT
#   ✅ Suporte a execução idempotente (pode ser re-executado)
#
# AUTORES E HISTÓRICO:
#   Original: arthur-aida (2026-05-21)
#   Versão: 2.0 - Melhorias de robustez e documentação
#   Versão: 2.1 - Precarregamento de repositorios e chaves
# =============================================================================
set -eu

# -----------------------------------------------------------------------------
# FUNÇÃO: VERIFICA E INSTALA BASH SE NECESSÁRIO
# -----------------------------------------------------------------------------
check_and_install_bash() {
    if [ -x /bin/bash ] || [ -x /usr/bin/bash ]; then
        [ -x /usr/bin/bash ] && [ ! -x /bin/bash ] && ln -sf /usr/bin/bash /bin/bash
        return 0
    fi
    echo "ERRO: /bin/bash nao encontrado. Tentando instalar..." >&2
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq
        apt-get install -y -qq bash yad
    else
        echo "ERRO: Gerenciador de pacotes nao suportado. Abortando." >&2
        exit 1
    fi
    if [ -x /bin/bash ] || [ -x /usr/bin/bash ]; then
        [ -x /usr/bin/bash ] && [ ! -x /bin/bash ] && ln -sf /usr/bin/bash /bin/bash
        echo "Bash instalado com sucesso. Reiniciando o script..." >&2
        return 0
    else
        echo "ERRO: Falha na instalacao do bash." >&2
        exit 1
    fi
}

# =============================================================================
# FUNÇÃO: VERIFICA E LIMPA VESTÍGIOS DE PROXY EM REPOSITÓRIOS
# =============================================================================
check_and_clean_proxy_remnants() {
    log_info "🔍 Verificando vestígios de proxy em repositórios..."
    
    local MAIN_SOURCES="/etc/apt/sources.list"
    local SOURCES_DIR="/etc/apt/sources.list.d"
    local FOUND_PROXY=false
    local SEARCH_PATTERN='http://[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+/'
    
    # Verifica sources.list principal
    if [ -f "$MAIN_SOURCES" ]; then
        if grep -qE "$SEARCH_PATTERN" "$MAIN_SOURCES" 2>/dev/null; then
            log_info "   ⚠️ Vestígio de proxy encontrado em $MAIN_SOURCES"
            FOUND_PROXY=true
        fi
    fi
    
    # Verifica todos os arquivos .list e .sources em sources.list.d
    for file in "$SOURCES_DIR"/*.list "$SOURCES_DIR"/*.sources; do
        [ -f "$file" ] || continue
        if grep -qE "$SEARCH_PATTERN" "$file" 2>/dev/null; then
            log_info "   ⚠️ Vestígio de proxy encontrado em $file"
            FOUND_PROXY=true
        fi
    done
    
    if [ "$FOUND_PROXY" = true ]; then
        log_info "🔄 Executando restore-sources-from-backup.sh para remover todos os vestígios..."
        bash "$SCRIPT_DIR/scripts/restore-sources-from-backup.sh"
        
        # Verifica novamente se o restore foi eficaz
        local STILL_PROXY=false
        for file in "$MAIN_SOURCES" "$SOURCES_DIR"/*.list "$SOURCES_DIR"/*.sources; do
            [ -f "$file" ] || continue
            if grep -qE "$SEARCH_PATTERN" "$file" 2>/dev/null; then
                log_error "   ❌ Ainda há vestígio de proxy em $file"
                STILL_PROXY=true
            fi
        done
        
        if [ "$STILL_PROXY" = false ]; then
            log_info "✅ Todos os vestígios de proxy foram removidos com sucesso."
        else
            log_error "⚠️ Alguns vestígios persistiram. Verifique manualmente."
        fi
    else
        log_info "✅ Nenhum vestígio de proxy encontrado nos repositórios."
    fi
}

# -----------------------------------------------------------------------------
# FUNÇÃO: MOSTRA AJUDA
# -----------------------------------------------------------------------------
show_help() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════╗
║   ZORIN OS 18.1 - CUSTOMIZAÇÃO CORPORATIVA - main.sh v2.0                 ║
╚═══════════════════════════════════════════════════════════════════════════╝

DESCRIÇÃO:
  Script orquestrador para deploy de perfis corporativos em Zorin OS 18.1.
  Configura sistema com cache APT, NFS, certificados ICP Brasil e segurança.

SINTAXE:
  main.sh <PERFIL> [OPÇÕES]

PERFIS DISPONÍVEIS:
  ┌─────────────────────────────────────────────────────────────────────┐
  │ 1 - HOME OFFICE / ESCRITÓRIO MÓVEL                                  │
  │     • Foco em mobilidade e segurança local                          │
  │     • Backup em Proxmox desabilitado                                │
  │     • Flatpak cache desabilitado                                    │
  │                                                                     │
  │ 2 - CORPORATIVO                                                     │
  │     • Ambiente corporativo com políticas de segurança               │
  │     • Suporte a NFS e APT-Cacher-NG                                 │
  │     • Backup e Flatpak cache habilitados                            │
  │     • Certificados digitais e tokens de segurança                   │
  │                                                                     │
  │ 3 - SAÚDE (CLÍNICAS, HOSPITAIS, UBS)                                │
  │     • Configurações específicas para ambiente de saúde              │
  │     • Aplicativos de saúde adicionais                               │
  │     • Conformidade com LGPD/HIPAA (parcial)                         │
  │                                                                     │
  │ 9 - SERVIDOR DE DEPLOY (KVM + NFS + APT-CACHER-NG)                  │
  │     • Configura servidor de cache para deploy em massa              │
  │     • Setup completo de infraestrutura                              │
  │     • Não compatível com perfis 1-3                                 │
  └─────────────────────────────────────────────────────────────────────┘

OPÇÕES:
  ┌─────────────────────────────────────────────────────────────────────┐
  │ --skip-errors         Continua mesmo se algum módulo falhar         │
  │                       (não encerra com erro ao final)               │
  │                       ⚠️  Use apenas para debug/troubleshooting     │
  │                                                                     │
  │ --no-preflight        Pula verificação de pré-requisitos            │
  │                       ⚠️  Não recomendado em produção               │
  │                                                                     │
  │ --no-apt-cacher       Desativa APT-Cacher-NG mesmo se definido      │
  │                       (instala pacotes da internet)                 │
  │                                                                     │
  │ --no-nfs              Desativa montagem NFS (cache local apenas)    │
  │                       (Flatpak pode ser mais lento)                 │
  │                                                                     │
  │ --help, -h            Exibe esta mensagem                           │
  └─────────────────────────────────────────────────────────────────────┘

ARQUITETURA DE REDE KVM SUPORTADA:
  • 192.168.122.0/24 (rede padrão libvirt)
  • 192.168.123.0/24 (rede secundária)
  • Servidor NFS sempre no IP .1 da rede ativa
  • Porta padrão NFS: 2049 (configurável por perfil)

EXEMPLOS DE USO:
  # Deploy perfil corporativo padrão
  $ sudo ./main.sh 2

  # Deploy perfil corporativo permitindo erros (debug)
  $ sudo ./main.sh 2 --skip-errors

  # Simular deploy sem fazer alterações
  $ sudo ./main.sh 2 --dry-run --verbose

  # Deploy perfil saúde sem NFS
  $ sudo ./main.sh 3 --no-nfs

  # Setup de servidor de deploy
  $ sudo ./main.sh 9

  # Home office sem cache APT (conexão lenta)
  $ sudo ./main.sh 1 --no-apt-cacher

ESTRUTURA DE LOGS:
  • /var/log/customization/           (tmpfs, 50MB, reinicia com SO)
  • /var/log/customization-persist/   (disco, permanente)
  • Cada módulo gera: <modulo>.log
  • Relatório final em: execution-report-YYYYMMDD_HHMMSS.html

SINAIS SUPORTADOS:
  • SIGINT (Ctrl+C)  → Cleanup seguro e exit
  • SIGTERM          → Cleanup seguro e exit
  • SIGHUP (hang-up) → Ignorado

CÓDIGOS DE SAÍDA:
  0 - Sucesso completo (todos os módulos OK ou --skip-errors)
  1 - Falha crítica (pré-requisitos, privilégios, espaço em disco)
  2 - Falha de módulo(s) (exit code retornado se --skip-errors não usado)
  3 - Argumento inválido

REQUISITOS MÍNIMOS:
  • Zorin OS 18.1 LTS (pode funcionar em Linux Mint 21+)
  • Privilégios root (sudo ou login root)
  • 2GB de espaço livre em /var/log/
  • 5GB de espaço livre total (menos com --no-apt-cacher)
  • Conexão internet ativa (para download inicial)

DOCUMENTAÇÃO ADICIONAL:
  • Docs/Arvore_de_recursos_ao_desenvolvedor.pdf
  • Docs/Guia_de_Configuração_do_Ambiente_de_Deploy_com_o _KVM_linux.pdf
  • Docs/Proposta_Otimizacao_KVM_VMM.pdf
  • Docs/Relatorio_Migracao_Linux.pdf
  • Docs/Relatorios_Tecnico_SysAdmin_Desenvolvedor.pdf

TROUBLESHOOTING:
  Ver: Docs/Relatorios_Tecnico_SysAdmin_Desenvolvedor.pdf (seção "Troubleshooting")

═══════════════════════════════════════════════════════════════════════════
EOF
}

# -----------------------------------------------------------------------------
# VERIFICAÇÃO INICIAL DO BASH
# -----------------------------------------------------------------------------
check_and_install_bash
if [ -z "${BASH_VERSION:-}" ]; then
    exec /bin/bash "$0" "$@"
fi

# =============================================================================
# CONFIGURAÇÕES BASH
# =============================================================================
set -euo pipefail
SCRIPT_DIR="/etc/customization"
SOURCES_DIR="/etc/apt/sources.list.d"
LOG_DIR="/var/log/customization"
PERSISTENT_LOG_DIR="/var/log/customization-persist"
BG_PIDS=()
BG_MODULES=()

mkdir -p "$LOG_DIR" "$PERSISTENT_LOG_DIR"

TMPFS_MOUNTED=false
if mountpoint -q "$LOG_DIR"; then
    TMPFS_MOUNTED=true
elif mount -t tmpfs -o size=50M,mode=0755 tmpfs "$LOG_DIR" 2>/dev/null; then
    TMPFS_MOUNTED=true
else
    echo "AVISO: Não foi possível montar tmpfs em $LOG_DIR. Usando disco diretamente." >&2
    LOG_DIR="$PERSISTENT_LOG_DIR"
fi

FAILED_MODULES=()  # array global para módulos que falharem

cleanup_logs() {
    local exit_code=$?
    local REAL_USER="${SUDO_USER:-}"
    if [ -z "$REAL_USER" ]; then
        REAL_USER=$(grep ":1000:" /etc/passwd | cut -d: -f1)
    fi

    # Copia logs para diretório persistente antes de desmontar tmpfs
    if [ -d "$LOG_DIR" ] && [ "$LOG_DIR" != "$PERSISTENT_LOG_DIR" ]; then
        mkdir -p "$PERSISTENT_LOG_DIR"
        cp -a "$LOG_DIR/." "$PERSISTENT_LOG_DIR/" 2>/dev/null || true
        umount -l "$LOG_DIR" 2>/dev/null || true
    fi
    
    exit $exit_code
}

# -----------------------------------------------------------------------------
# FUNÇÃO: CARREGA REPOSITORIOS E CHAVES
# -----------------------------------------------------------------------------
carrega_repos() {
	#====================================================================
	# Adiciona o repositorio do wine
	#====================================================================
	WINE_KEYRING="/usr/share/keyrings/winehq.gpg"
	WINE_SOURCE="/etc/apt/sources.list.d/winehq.list"

	if [ ! -f "$WINE_KEYRING" ]; then
	    log_info "Baixando chave GPG do WineHQ..."
	    mkdir -p "$(dirname "$WINE_KEYRING")"
	    TEMP_KEY="/tmp/winehq.key"
	    # O download_with_cache já utiliza a lógica de proxy se disponível no common.sh
	    if download_with_cache "https://dl.winehq.org/wine-builds/winehq.key" "$TEMP_KEY"; then
		gpg --dearmor -o "$WINE_KEYRING" < "$TEMP_KEY" 2>/dev/null
		log_info "✅ Chave GPG do WineHQ instalada"
	    fi
	fi

	# ─── Detecção do codinome do Ubuntu (inclusive para Linux Mint) ───
	if [ -f /etc/os-release ]; then
	    # Tenta obter a variável UBUNTU_CODENAME (presente no Mint e derivados)
	    UBUNTU_CODENAME=$(grep -oP '^UBUNTU_CODENAME=\K.*' /etc/os-release 2>/dev/null || true)
	fi
	# Se a variável não existir, usa lsb_release (Ubuntu/Debian padrão)
	if [ -z "$UBUNTU_CODENAME" ]; then
	    UBUNTU_CODENAME=$(lsb_release -sc 2>/dev/null || echo "noble")
	fi

	# Adiciona o repositório com o codinome correto (linuxmint x ubuntu)
	echo "deb [signed-by=$WINE_KEYRING] https://dl.winehq.org/wine-builds/ubuntu/ $UBUNTU_CODENAME main" | tee "$WINE_SOURCE" >/dev/null
	log_info "Repositório WineHQ adicionado com codinome UBUNTU BASE detectado: $UBUNTU_CODENAME"
	#====================================================================
}

trap cleanup_logs EXIT INT TERM

# Carrega funções comuns
if [ -f "$SCRIPT_DIR/utils/common.sh" ]; then
    source "$SCRIPT_DIR/utils/common.sh"
else
    echo "ERRO: $SCRIPT_DIR/utils/common.sh nao encontrado"
    exit 1
fi

# =============================================================================
# PROCESSAMENTO DE ARGUMENTOS
# =============================================================================
PERFIL=""
SKIP_ERRORS=false
NO_PREFLIGHT=false
NO_APT_CACHER=false
NO_NFS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-errors)    SKIP_ERRORS=true; shift ;;
        --no-preflight)   NO_PREFLIGHT=true; shift ;;
        --no-apt-cacher)  NO_APT_CACHER=true; shift ;;
        --no-nfs)         NO_NFS=true; shift ;;
        --help|-h)        show_help; exit 0 ;;
        [1239])           PERFIL="$1"; shift ;;
        *)                echo "ERRO: Argumento invalido: $1" >&2; show_help; exit 1 ;;
    esac
done

# =============================================================================
# PERFIL 9: EXECUTA O SCRIPT DO SERVIDOR E SAI
# =============================================================================
if [ "$PERFIL" = "9" ]; then
    SETUP_SERVER_SCRIPT="$SCRIPT_DIR/scripts/setup-server-KVM-nfs-acng.sh"
    if [ -f "$SETUP_SERVER_SCRIPT" ]; then
        log_info "Executando configuração do servidor de cache e KVM..."
        FORCE_FLATPAK_CACHE=1 bash "$SETUP_SERVER_SCRIPT"
        log_info "Configuração do servidor concluída. Reinicie se necessário."
    else
        echo "ERRO: Script de configuração do servidor não encontrado: $SETUP_SERVER_SCRIPT" >&2
        exit 1
    fi
    exit 0
fi

if [ -z "$PERFIL" ]; then
    echo "ERRO: Perfil nao especificado" >&2
    show_help
    exit 1
fi

# =============================================================================
# INÍCIO DA EXECUÇÃO (PERFIS 1, 2, 3)
# =============================================================================
load_profile "$PERFIL"

# <<< NOVO: Sinaliza que o ambiente foi carregado pelo main.sh (variáveis completas)
export MAIN_ACTIVE=1

export APTCACHER CACHEPORT NFSSERVERER NFSPORT
export DNS site sigh
export ENABLE_BACKUP ENABLE_FLATPAK_CACHE ENABLE_HEALTH_APPS
export hostsallow0 hostsallow1 hostsallow2 hostsallow3 hostsdeny ntpserver

systemctl stop packagekit unattended-upgrades 2>/dev/null || true
systemctl stop apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
systemctl disable apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
pkill -f apt.systemd.daily 2>/dev/null || true

carrega_repos
wait_for_apt_unlock
update_apt_keys_no_proxy
log_info "========================================="
log_info "Iniciando customizacao com perfil $PERFIL"
log_info "Skip errors: $SKIP_ERRORS"
log_info "Porta NFS: $NFS_PORT"
log_info "========================================="

# =============================================================================
# PASSO 0: PREFLIGHT
# =============================================================================
log_info ""
log_info "========================================="
log_info "PASSO 0: Verificacao de pre-requisitos"
log_info "========================================="

if [ "$NO_PREFLIGHT" = false ]; then
    run_preflight "$PERFIL"
else
    log_info "--no-preflight informado - pulando verificacao"
fi

echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

# =============================================================================
# FUNÇÕES DE EXECUÇÃO DE MÓDULOS (COM TRATAMENTO DE ERROS)
# =============================================================================
run_script() {
    local script_name="$1"
    local script_path="$2"
    local log_file="$LOG_DIR/${script_name}.log"

    if [ ! -f "$script_path" ]; then
        log_info "AVISO: $script_name nao encontrado em $script_path"
        return 0
    fi

    log_info "Executando: $script_name"

    # Desabilita set -e temporariamente para capturar o retorno sem interromper o main.sh
    set +e
    bash "$script_path" >> "$log_file" 2>&1
    local ret=$?
    set -e

    if [ $ret -ne 0 ]; then
        log_error "MÓDULO $script_name FALHOU (código $ret)"
        FAILED_MODULES+=("$script_name")
        # Se SKIP_ERRORS for false, o script principal NÃO será interrompido aqui;
        # o controle será feito no final com base no array FAILED_MODULES.
    fi

    log_info "$script_name concluido (código $ret)"
    return 0
}

run_module() {
    local module_name="$1"
    run_script "$module_name" "$SCRIPT_DIR/modules/${module_name}.sh"
}

BG_PIDS=()
run_module_bg() {
    local module_name="$1"
    local log_file="$LOG_DIR/${module_name}.log"
    if [ -f "$SCRIPT_DIR/modules/${module_name}.sh" ]; then
        log_info "Executando (bg): $module_name"
        bash "$SCRIPT_DIR/modules/${module_name}.sh" >> "$log_file" 2>&1 &
        local pid=$!
        BG_PIDS+=("$pid")
        BG_MODULES+=("$module_name")
    else
        log_info "AVISO: $module_name.sh nao encontrado"
    fi
}

# =============================================================================
# FUNÇÃO: VERIFICA CACHE FLATPAK E SOLICITA RECRIAÇÃO AO SERVIDOR
# =============================================================================
rebuild_flatpak_cache_if_empty() {
    local SERVER_IP="$1"
    local NFS_FLATPAK_DIR="$2"
    local REBUILD_PORT=9876

    # Caminho real do repositório ostree (estrutura do create-usb)
    local OSTREE_REPO="$NFS_FLATPAK_DIR/.ostree/repo"

    # Cache já populado → nada a fazer
    if [ -d "$OSTREE_REPO/objects" ] && [ "$(ls -A "$OSTREE_REPO/objects" 2>/dev/null)" ]; then
        log_info "Cache Flatpak já populado em $OSTREE_REPO"
        return 0
    fi

    log_warning "Cache Flatpak vazio. Acionando recriação via trigger TCP..."

    # Verifica se o servidor responde na porta de rebuild
    if ! nc -w 2 -z "$SERVER_IP" "$REBUILD_PORT"; then
        log_error "Servidor $SERVER_IP:$REBUILD_PORT não está acessível."
        return 1
    fi

    # Envia um byte qualquer para disparar o rebuild (a conexão em si já inicia o script)
    echo "rebuild" | nc -w 5 "$SERVER_IP" "$REBUILD_PORT" > /dev/null 2>&1
    local ret=$?

    if [ $ret -eq 0 ]; then
        log_success "Gatilho enviado. O cache Flatpak está sendo recriado no servidor."
    else
        log_error "Falha ao comunicar com o trigger de rebuild."
        return 1
    fi
}

# =============================================================================
# PASSO 1: SINCRONIZA SCRIPTS
# =============================================================================
log_info ""
log_info "========================================="
log_info "PASSO 1: Sincronizando scripts originais"
log_info "========================================="
run_module "01-sync-scripts"

# =============================================================================
# PASSO 2: GESTÃO DE CACHE (CORRIGIDO: só atua se APTCACHER definido)
# =============================================================================
log_info ""
log_info "========================================="
log_info "PASSO 2: Verificando infraestrutura de cache..."
log_info "========================================="

if [ -n "${APTCACHER:-}" ]; then
    # Perfil define explicitamente um proxy APT → tentar usar
    if bash "/etc/acngonoff.sh"; then
        log_info "Infraestrutura de cache detectada. Aplicando Mapeamento Direto..."
        [ -f /tmp/acng_env ] && source /tmp/acng_env
        export ACTUAL_PROXY_URL="$PROXY_URL"
        export PROXY_HOST_PORT=$(echo "$ACTUAL_PROXY_URL" | sed 's|http://||')
        bash "$SCRIPT_DIR/scripts/convert-sources-to-proxy.sh"
    else
        log_info "Proxy do perfil inacessível. Seguindo sem cache."
        if [ -f "/etc/apt/sources.list.d/backup_conversion/.backup_original_feito" ]; then
            log_info "Restaurando fontes originais..."
            bash "$SCRIPT_DIR/scripts/restore-sources-from-backup.sh"
        else
            log_info "Nenhum backup encontrado. Fontes APT mantidas sem alterações."
        fi
    fi
else
    log_info "Perfil não define APTCACHER – ambiente sem cache."
    # Se existir backup de uma conversão anterior, restaura os fontes originais
    if [ -f "/etc/apt/sources.list.d/backup_conversion/.backup_original_feito" ]; then
        log_info "Restaurando fontes originais..."
        bash "$SCRIPT_DIR/scripts/restore-sources-from-backup.sh"
    else
        log_info "Nenhum backup encontrado. Fontes APT mantidas sem alterações."
    fi
fi

# =============================================================================
# PASSO 3: DEPENDÊNCIAS MÍNIMAS
# =============================================================================
log_info ""
log_info "========================================="
log_info "PASSO 3: Instalando dependências NFS e Flatpak"
log_info "========================================="
run_module "00-dependencies"

# =============================================================================
# PASSO 4: MONTAGEM NFS (CORRIGIDO: só se NFSSERVERER estiver definido)
# =============================================================================
log_info ""
log_info "========================================="
log_info "PASSO 4: Montando NFS e verificando cache Flatpak"
log_info "========================================="

NFS_MOUNTED=false
if [ "$NO_NFS" = false ] && [ -n "${NFSSERVERER:-}" ]; then
    if mount_nfs_direct; then
        NFS_MOUNTED=true
        log_info "NFS montado com sucesso"

        # >>> INTEGRAÇÃO: Verifica e recria cache Flatpak se necessário
        rebuild_flatpak_cache_if_empty "$NFS_SERVER" "/mnt"
        # <<<

        log_info ""
        log_info "Verificando montagens:"
        if mountpoint -q /mnt; then
            log_info "   /mnt: $(df -h /mnt | tail -1)"
        else
            log_info "   /mnt: Nao montado"
        fi
        if mountpoint -q /tmp/cache; then
            log_info "   /tmp/cache: $(df -h /tmp/cache | tail -1)"
        else
            log_info "   /tmp/cache: Nao montado"
        fi
    else
        log_info "Falha na montagem NFS - continuando sem cache"
    fi
else
    if [ -z "${NFSSERVERER:-}" ]; then
        log_info "Perfil não define NFSSERVERER – pulando montagem NFS."
    else
        log_info "--no-nfs informado - pulando montagem"
    fi
fi

# =============================================================================
# PASSO 5: INSTALAÇÃO MASSIVA DE PACOTES APT
# =============================================================================
log_info ""
log_info "========================================="
log_info "PASSO 5: Instalacao massiva de pacotes APT"
log_info "========================================="
run_module "02-bulk-packages"

# =============================================================================
# PASSO 6: CONFIGURAÇÕES BÁSICAS (paralelo)
# =============================================================================
log_info ""
log_info "========================================="
log_info "PASSO 6: Configuracoes basicas (paralelo)"
log_info "========================================="

for module in 03-certificates 04-browsers 06-icp-user-certs 07-kaspersky; do
    if [ -f "$SCRIPT_DIR/modules/${module}.sh" ]; then
        run_module_bg "$module"
    fi
done
for ((i=0; i<${#BG_PIDS[@]}; i++)); do
    pid=${BG_PIDS[$i]}
    mod_name=${BG_MODULES[$i]}
    wait "$pid"
    ret=$?
    if [ $ret -ne 0 ]; then
        log_error "Módulo em background $mod_name falhou (código $ret)"
        FAILED_MODULES+=("$mod_name")
    fi
done
BG_PIDS=()
BG_MODULES=()

# =============================================================================
# PASSO 7: MÓDULOS APT (sequencial)
# =============================================================================
log_info ""
log_info "========================================="
log_info "PASSO 7: Modulos que usam APT (sequencial)"
log_info "========================================="
for module in 05-tokens 08-wine 09-signers 10-backup; do
    run_module "$module"
done

# Reaplica conversão para proxy **apenas se APTCACHER foi definido e o proxy está ativo**
if [ -n "${APTCACHER:-}" ] && [ -f "/etc/acngonoff.sh" ]; then
    if bash "/etc/acngonoff.sh"; then
        # Garante que a variável PROXY_URL esteja disponível para o conversor
        [ -f /tmp/acng_env ] && source /tmp/acng_env
        log_info "Reaplicando Mapeamento Direto a todas as fontes..."
        chmod +x /etc/customization/scripts/convert-sources-to-proxy.sh
        # Opcional: exportar explicitamente para subshell (já é feito pelo source, mas por segurança)
        export PROXY_URL="${PROXY_URL:-}"
        /etc/customization/scripts/convert-sources-to-proxy.sh
    fi
fi

# =============================================================================
# PASSO 8: FLATPAK E DESKTOP (paralelo)
# =============================================================================
log_info ""
log_info "========================================="
log_info "PASSO 8: Flatpak e configuracoes de desktop (paralelo)"
log_info "========================================="
for module in 11-flatpak-cache 12-desktop-config 13-desktop-config-user; do
    run_module_bg "$module"
done
for ((i=0; i<${#BG_PIDS[@]}; i++)); do
    pid=${BG_PIDS[$i]}
    mod_name=${BG_MODULES[$i]}
    wait "$pid"
    ret=$?
    if [ $ret -ne 0 ]; then
        log_error "Módulo em background $mod_name falhou (código $ret)"
        FAILED_MODULES+=("$mod_name")
    fi
done
BG_PIDS=()
BG_MODULES=()

# =============================================================================
# PASSO 9: SEGURANÇA E FINALIZAÇÃO (paralelo)
# =============================================================================
log_info ""
log_info "========================================="
log_info "PASSO 9: Seguranca e finalizacao (paralelo)"
log_info "========================================="
for module in 14-security 15-kvm-menu; do
    run_module_bg "$module"
done
for ((i=0; i<${#BG_PIDS[@]}; i++)); do
    pid=${BG_PIDS[$i]}
    mod_name=${BG_MODULES[$i]}
    wait "$pid"
    ret=$?
    if [ $ret -ne 0 ]; then
        log_error "Módulo em background $mod_name falhou (código $ret)"
        FAILED_MODULES+=("$mod_name")
    fi
done
BG_PIDS=()
BG_MODULES=()

# =============================================================================
# PASSO 10: ATUALIZAÇÃO FINAL E LIMPEZA
# =============================================================================
log_info ""
log_info "========================================="
log_info "PASSO 10: Updates e limpeza pos-instalacao"
log_info "========================================="

if [ -f /var/log/customization/.sources_converted_to_http ]; then
    rm -f /var/log/customization/.sources_converted_to_http
    log_info "Sentinela de conversão removido"
fi

log_info "Atualizando pacotes e removendo antigos..."
{
    wait_for_apt_unlock
    echo "=== Início da atualizacao de pacotes e remocao dos antigos - $(date) ==="
    apt full-upgrade -y  -qq 2>&1
    flatpak update -y --noninteractive  2>&1
    apt-get autoremove -y  -qq 2>&1
    apt-get clean  -qq 2>&1
    echo "=== Fim da limpeza - $(date) ==="
} > "${LOG_DIR}/cleanup.log" 2>&1
log_info "Remoção de pacotes antigos concluída."

log_info "Verificando necessidade de restauração de fontes..."
if [ -f "/etc/apt/sources.list.d/backup_conversion/.backup_original_feito" ]; then
    log_info "Restaurando fontes originais..."
    bash "$SCRIPT_DIR/scripts/restore-sources-from-backup.sh"
else
    log_info "Nenhum backup encontrado. Fontes mantidas."
fi

if [ -f /etc/apt/apt.conf.d/00aptproxy ]; then
    log_info "Removendo proxy APT..."
    rm -f /etc/apt/apt.conf.d/00aptproxy
    log_info "Proxy APT removido"
fi

# Restaura repositórios desabilitados
DISABLED_BACKUP_DIR="/etc/apt/sources.list.d/disabled_repos_backup"
if [ -d "$DISABLED_BACKUP_DIR" ] && [ "$(ls -A "$DISABLED_BACKUP_DIR" 2>/dev/null)" ]; then
    log_info "Restaurando repositórios temporariamente desabilitados..."
    mv "$DISABLED_BACKUP_DIR"/* "$SOURCES_DIR"/ 2>/dev/null || true
    rmdir "$DISABLED_BACKUP_DIR" 2>/dev/null || true
    log_info "Repositórios desabilitados restaurados."

    # Remove proxy (apenas IP:PORT) de todos os arquivos restaurados
    log_info "Removendo qualquer referência a proxy dos repositórios restaurados..."
    for f in "$SOURCES_DIR"/*.list "$SOURCES_DIR"/*.sources; do
        [ -f "$f" ] && sed -i -E \
            -e 's|http://[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+/HTTPS///|https://|g' \
            -e 's|http://[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+/|http://|g' "$f"
    done
    log_info "✅ Proxy removido de todos os arquivos de fontes."
fi
check_and_clean_proxy_remnants

if [ -f "$SCRIPT_DIR/utils/fix-sources-list.sh" ]; then
    run_script "fix-sources-list" "$SCRIPT_DIR/utils/fix-sources-list.sh"
fi
if [ "$(grep ^ID= /etc/os-release | cut -d= -f2)" = "linuxmint" ]; then
    chmod 644 /etc/apt/sources.list
    chown root:root /etc/apt/sources.list
fi

# =============================================================================
# RELATÓRIO FINAL DE FALHAS
# =============================================================================
if [ ${#FAILED_MODULES[@]} -gt 0 ]; then
    log_error "========================================="
    log_error "ATENÇÃO: Os seguintes módulos falharam:"
    for m in "${FAILED_MODULES[@]}"; do
        log_error "  - $m"
    done
    log_error "Consulte os logs em: $PERSISTENT_LOG_DIR/"
    log_error "========================================="
    if [ "$SKIP_ERRORS" = false ]; then
        log_error "Abortando com código de saída 1 devido às falhas."
        exit 1
    else
        log_info "Prosseguindo porque --skip-errors está ativo."
    fi
fi

# =============================================================================
# CONCLUSÃO
# =============================================================================
systemctl enable apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
systemctl start apt-daily.timer 2>/dev/null || true
systemctl start packagekit unattended-upgrades 2>/dev/null || true

log_info ""
log_info "========================================="
log_info "CUSTOMIZACAO CONCLUIDA"
log_info "========================================="
log_info "Resumo da execucao:"
log_info "  - Perfil: $PERFIL"
log_info "  - NFS montado: $([ "$NFS_MOUNTED" = true ] && echo "sim" || echo "nao")"
log_info "  - APT-Cacher-NG: $([ -f /etc/apt/apt.conf.d/00aptproxy ] && echo "ativo" || echo "inativo")"
log_info "  - Porta NFS utilizada: $NFS_PORT"
log_info "  - Módulos com falha: ${#FAILED_MODULES[@]}"
log_info ""
log_info "Logs em: $PERSISTENT_LOG_DIR/"
log_info ""
log_info "Recomendacoes:"
log_info "  1. Reinicie o sistema para aplicar todas as configuracoes"
log_info "  2. Verifique os logs em caso de erros"
log_info "========================================="

# ---------------------------------------------------------------------------
# LOGS PERMANENTES
# ---------------------------------------------------------------------------
if [ "$LOG_DIR" != "$PERSISTENT_LOG_DIR" ] && mountpoint -q "$LOG_DIR" 2>/dev/null; then
    mkdir -p "$PERSISTENT_LOG_DIR"
    cp -a "$LOG_DIR/." "$PERSISTENT_LOG_DIR/" 2>/dev/null || true
fi

# <<< NOVO: Persistência do perfil ativo para uso independente (cron)
cat > /etc/customization/active-profile.env <<EOF
export APTCACHER="${APTCACHER:-}"
export CACHEPORT="${CACHEPORT:-}"
export NFSSERVERER="${NFSSERVERER:-}"
export NFSPORT="${NFSPORT:-}"
export DNS="${DNS:-}"
export site="${site:-}"
export sigh="${sigh:-}"
export ENABLE_BACKUP="${ENABLE_BACKUP:-}"
export ENABLE_FLATPAK_CACHE="${ENABLE_FLATPAK_CACHE:-}"
export ENABLE_HEALTH_APPS="${ENABLE_HEALTH_APPS:-}"
export hostsallow0="${hostsallow0:-}"
export hostsallow1="${hostsallow1:-}"
export hostsallow2="${hostsallow2:-}"
export hostsallow3="${hostsallow3:-}"
export hostsdeny="${hostsdeny:-}"
export ntpserver="${ntpserver:-}"
EOF
chmod 644 /etc/customization/active-profile.env
umount -af
exit 0
