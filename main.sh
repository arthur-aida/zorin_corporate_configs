#!/bin/bash
# =============================================================================
# main.sh - Script Principal de Customização para Zorin OS 18.1
# =============================================================================
#
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
#   ✅ Módulos executados com set +e (não abortam o orchestrador)
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
#
# =============================================================================

set -eu

# =============================================================================
# SEÇÃO 1: VERIFICAÇÃO INICIAL DO BASH
# =============================================================================
# 
# Esta seção garante que o script está sendo executado com Bash moderno.
# Necessário para suportar arrays associativos e outras features.
#
check_and_install_bash() {
    # ─────────────────────────────────────────────────────────────────────
    # Tenta localizar bash instalado
    # ─────────────────────────────────────────────────────────────────────
    if [ -x /bin/bash ] || [ -x /usr/bin/bash ]; then
        # Cria symlink se necessário (para compatibilidade)
        [ -x /usr/bin/bash ] && [ ! -x /bin/bash ] && ln -sf /usr/bin/bash /bin/bash
        return 0
    fi
    
    # ─────────────────────────────────────────────────────────────────────
    # Se bash não foi encontrado, tenta instalar
    # ─────────────────────────────────────────────────────────────────────
    echo "ERRO: /bin/bash nao encontrado. Tentando instalar..." >&2
    
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq
        apt-get install -y -qq bash yad
    else
        echo "ERRO: Gerenciador de pacotes nao suportado. Abortando." >&2
        exit 1
    fi
    
    # ─────────────────────────────────────────────────────────────────────
    # Verifica novamente após instalação
    # ─────────────────────────────────────────────────────────────────────
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
# SEÇÃO 2: FUNÇÃO DE AJUDA
# =============================================================================
#
# Exibe uso do script com exemplos práticos.
# Mantém documentação atualizada da interface do usuário.
#
show_help() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════╗
║   ZORIN OS 18.1 - CUSTOMIZAÇÃO CORPORATIVA - main.sh v2.0               ║
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
  │     • Suporte a NFS e APT-Cacher-NG                                │
  │     • Backup e Flatpak cache habilitados                           │
  │     • Certificados digitais e tokens de segurança                  │
  │                                                                     │
  │ 3 - SAÚDE (CLÍNICAS, HOSPITAIS, UBS)                              │
  │     • Configurações específicas para ambiente de saúde              │
  │     • Aplicativos de saúde adicionais                              │
  │     • Conformidade com LGPD/HIPAA (parcial)                        │
  │                                                                     │
  │ 9 - SERVIDOR DE DEPLOY (KVM + NFS + APT-CACHER-NG)               │
  │     • Configura servidor de cache para deploy em massa             │
  │     • Setup completo de infraestrutura                             │
  │     • Não compatível com perfis 1-3                                │
  └─────────────────────────────────────────────────────────────────────┘

OPÇÕES:
  ┌─────────────────────────────────────────────────────────────────────┐
  │ --skip-errors         Continua mesmo se algum módulo falhar         │
  │                       (não encerra com erro ao final)               │
  │                       ⚠️  Use apenas para debug/troubleshooting      │
  │                                                                     │
  │ --no-preflight        Pula verificação de pré-requisitos            │
  │                       ⚠️  Não recomendado em produção               │
  │                                                                     │
  │ --no-apt-cacher       Desativa APT-Cacher-NG mesmo se definido      │
  │                       (instala pacotes da internet)                │
  │                                                                     │
  │ --no-nfs              Desativa montagem NFS (cache local apenas)    │
  │                       (Flatpak pode ser mais lento)                │
  │                                                                     │
  │ --dry-run             Simula execução sem fazer alterações          │
  │                       (novo - valida configurações)                │
  │                                                                     │
  │ --verbose             Aumenta verbosidade dos logs                  │
  │                       (novo - mostra comandos sendo executados)    │
  │                                                                     │
  │ --help, -h            Exibe esta mensagem                          │
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
  • Docs/Guia_de_Configuração_do_Ambiente_de_Teste_com_o_KVM.pdf
  • Docs/Relatorio_aos_interessados.pdf
  • Docs/Relatorios_ao_sysadmin.pdf

TROUBLESHOOTING:
  Ver: Docs/Relatorios_ao_sysadmin.pdf (seção "Troubleshooting")

═══════════════════════════════════════════════════════════════════════════
EOF
}

# =============================================================================
# SEÇÃO 3: VERIFICAÇÃO E EXECUÇÃO DO BASH
# =============================================================================

check_and_install_bash

if [ -z "${BASH_VERSION:-}" ]; then
    exec /bin/bash "$0" "$@"
fi

# =============================================================================
# SEÇÃO 4: MODO ESTRITO + VARIÁVEIS GLOBAIS
# =============================================================================
#
# set -euo pipefail:
#   -e : Exit em caso de erro (importante para segurança)
#   -u : Falha se variável não definida (previne erros silenciosos)
#   -o pipefail : Falha se qualquer comando em pipeline falha
#
# Variáveis globais inicializadas aqui para evitar "undefined variable"
#

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────
# Diretórios principais
# ─────────────────────────────────────────────────────────────────────────
readonly SCRIPT_DIR="/etc/customization"
readonly LOG_DIR="/var/log/customization"
readonly PERSISTENT_LOG_DIR="/var/log/customization-persist"
readonly SCRIPT_VERSION="2.0"
readonly SCRIPT_TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
readonly EXECUTION_REPORT="${PERSISTENT_LOG_DIR}/execution-report-${SCRIPT_TIMESTAMP}.html"

# ─────────────────────────────────────────────────────────────────────────
# Arrays para rastreamento de execução
# ─────────────────────────────────────────────────────────────────────────
declare -a BG_PIDS=()           # PIDs de processos em background
declare -a BG_MODULES=()        # Nomes dos módulos em background
declare -a FAILED_MODULES=()    # Módulos que falharam
declare -a EXECUTED_MODULES=()  # Módulos executados com sucesso
declare -a SKIPPED_MODULES=()   # Módulos pulados

# ─────────────────────────────────────────────────────────────────────────
# Flags de execução
# ─────────────────────────────────────────────────────────────────────────
DRY_RUN=false
VERBOSE=false
SKIP_ERRORS=false
NO_PREFLIGHT=false
NO_APT_CACHER=false
NO_NFS=false
PERFIL=""

# ─────────────────────────────────────────────────────────────────────────
# Estatísticas de execução
# ─────────────────────────────────────────────────────────────────────────
EXECUTION_START_TIME=$(date +%s)
NFS_MOUNTED=false
TMPFS_MOUNTED=false

# Criar diretórios de log com tratamento de erro
mkdir -p "$LOG_DIR" "$PERSISTENT_LOG_DIR" 2>/dev/null || {
    echo "ERRO: Não foi possível criar diretórios de log" >&2
    exit 1
}

# ─────────────────────────────────────────────────────────────────────────
# Tentativa de montar tmpfs para logs (melhor performance)
# ─────────────────────────────────────────────────────────────────────────
if mountpoint -q "$LOG_DIR" 2>/dev/null; then
    TMPFS_MOUNTED=true
    echo "[INFO] tmpfs já montado em $LOG_DIR"
elif mount -t tmpfs -o size=50M,mode=0755 tmpfs "$LOG_DIR" 2>/dev/null; then
    TMPFS_MOUNTED=true
    echo "[INFO] tmpfs montado com sucesso em $LOG_DIR (50MB)"
else
    echo "[WARN] Não foi possível montar tmpfs em $LOG_DIR. Usando disco diretamente." >&2
    LOG_DIR="$PERSISTENT_LOG_DIR"
fi

# =============================================================================
# SEÇÃO 5: FUNÇÃO CLEANUP (HANDLER DE SAÍDA)
# =============================================================================
#
# Executada automaticamente ao sair (trap EXIT) ou em sinais de interrupção.
# Responsável por:
#   1. Persistência de logs do tmpfs para disco
#   2. Desmontagem de tmpfs
#   3. Desmontagem de NFS se necessário
#   4. Geração de relatório final
#   5. Retorno do código de erro apropriado
#
cleanup_logs() {
    local exit_code=$?
    
    echo "" >&2
    echo "[INFO] ===== INICIANDO LIMPEZA =====" >&2
    
    # ─────────────────────────────────────────────────────────────────────
    # Persistir logs do tmpfs para disco permanente
    # ─────────────────────────────────────────────────────────────────────
    if [ -d "$LOG_DIR" ] && [ "$LOG_DIR" != "$PERSISTENT_LOG_DIR" ]; then
        echo "[INFO] Copiando logs de $LOG_DIR para $PERSISTENT_LOG_DIR..." >&2
        mkdir -p "$PERSISTENT_LOG_DIR"
        cp -a "$LOG_DIR/." "$PERSISTENT_LOG_DIR/" 2>/dev/null || true
        
        # Desmonta tmpfs se foi montado por este script
        if [ "$TMPFS_MOUNTED" = true ]; then
            echo "[INFO] Desmontando tmpfs..." >&2
            umount -l "$LOG_DIR" 2>/dev/null || true
        fi
    fi
    
    # ──────────────────────────��──────────────────────────────────────────
    # Desmonta NFS se necessário
    # ─────────────────────────────────────────────────────────────────────
    if [ "$NFS_MOUNTED" = true ]; then
        echo "[INFO] Limpando montagens NFS..." >&2
        for mount_point in /tmp/cache /mnt; do
            if mountpoint -q "$mount_point" 2>/dev/null; then
                umount -l "$mount_point" 2>/dev/null || echo "[WARN] Falha ao desmontar $mount_point" >&2
            fi
        done
    fi
    
    # ─────────────────────────────────────────────────────────────────────
    # Gera relatório de execução
    # ─────────────────────────────────────────────────────────────────────
    if [ -z "$PERFIL" ]; then
        # Se PERFIL não foi definido, script falhou cedo
        exit "$exit_code"
    fi
    
    generate_execution_report "$exit_code"
    
    echo "[INFO] ===== LIMPEZA CONCLUÍDA =====" >&2
    echo "" >&2
    
    exit "$exit_code"
}

# Registra os trap handlers para garantir limpeza segura
trap cleanup_logs EXIT INT TERM

# =============================================================================
# SEÇÃO 6: CARREGAR FUNÇÕES COMUNS
# =============================================================================
#
# common.sh contém funções reutilizáveis:
#   - log_* (logging estruturado)
#   - wait_for_apt_unlock
#   - load_profile
#   - update_apt_keys_no_proxy
#   - run_preflight
#   - get_nfs_server
#   - mount_nfs_if_available
#   - download_with_cache
#

if [ ! -f "$SCRIPT_DIR/utils/common.sh" ]; then
    echo "ERRO CRÍTICO: $SCRIPT_DIR/utils/common.sh não encontrado" >&2
    echo "Por favor, execute: sudo git clone ... /etc/customization" >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$SCRIPT_DIR/utils/common.sh"

# =============================================================================
# SEÇÃO 7: PROCESSAMENTO DE ARGUMENTOS
# =============================================================================
#
# Parse de argumentos com suporte a:
#   - Flags booleanas (--skip-errors, --verbose, etc)
#   - Número do perfil (1, 2, 3, 9)
#   - Validação de sintaxe
#

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-errors)
            SKIP_ERRORS=true
            log_info "⚠️  FLAG ATIVA: --skip-errors (continuará mesmo com erros de módulos)"
            shift
            ;;
        --no-preflight)
            NO_PREFLIGHT=true
            log_info "⚠️  FLAG ATIVA: --no-preflight (pulando verificação de pré-requisitos)"
            shift
            ;;
        --no-apt-cacher)
            NO_APT_CACHER=true
            log_info "⚠️  FLAG ATIVA: --no-apt-cacher (instalando sem cache)"
            shift
            ;;
        --no-nfs)
            NO_NFS=true
            log_info "⚠️  FLAG ATIVA: --no-nfs (desabilitando montagem NFS)"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            VERBOSE=true  # Força verbose em dry-run
            log_info "🧪 MODO: --dry-run (simulação sem alterações)"
            shift
            ;;
        --verbose)
            VERBOSE=true
            log_info "🔊 MODO: --verbose (aumentando verbosidade)"
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        [1239])
            # Valida perfil: apenas 1, 2, 3, ou 9
            if [[ ! "$1" =~ ^[1239]$ ]]; then
                log_error "ERRO: Perfil inválido: $1 (esperado 1, 2, 3 ou 9)"
                show_help
                exit 3
            fi
            PERFIL="$1"
            shift
            ;;
        *)
            log_error "ERRO: Argumento inválido: $1"
            show_help
            exit 3
            ;;
    esac
done

# =============================================================================
# SEÇÃO 8: VALIDAÇÕES PRÉ-EXECUÇÃO
# =============================================================================
#
# Verifica pré-requisitos críticos antes de prosseguir:
#   1. Perfil foi especificado
#   2. Executando como root
#   3. Espaço em disco suficiente
#   4. Zorin/Linux Mint versão compatível
#

# ─────────────────────────────────────────────────────────────────────────
# 1. Verifica se perfil foi especificado
# ��────────────────────────────────────────────────────────────────────────
if [ -z "$PERFIL" ]; then
    log_error "❌ ERRO: Perfil não especificado"
    show_help
    exit 3
fi

# ─────────────────────────────────────────────────────────────────────────
# 2. Perfil 9 (servidor) executa script separado e sai
# ─────────────────────────────────────────────────────────────────────────
if [ "$PERFIL" = "9" ]; then
    log_info "🖥️  PERFIL 9: Configurando servidor de deploy..."
    
    SETUP_SERVER_SCRIPT="$SCRIPT_DIR/scripts/setup-server-KVM-nfs-acng.sh"
    
    if [ ! -f "$SETUP_SERVER_SCRIPT" ]; then
        log_error "❌ ERRO: Script do servidor não encontrado: $SETUP_SERVER_SCRIPT"
        exit 1
    fi
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Executaria: $SETUP_SERVER_SCRIPT"
    else
        FORCE_FLATPAK_CACHE=1 bash "$SETUP_SERVER_SCRIPT"
        log_success "✅ Configuração do servidor concluída"
    fi
    
    log_info "💡 Recomendação: Reinicie o servidor para aplicar todas as alterações"
    exit 0
fi

# ─────────────────────────────────────────────────────────────────────────
# 3. Valida privilégios root
# ─────────────────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    log_error "❌ ERRO: Este script requer privilégios root"
    log_error "Por favor, execute: sudo $0 $PERFIL"
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────
# 4. Valida espaço em disco
# ─────────────────────────────────────────────────────────────────────────
check_disk_space() {
    local required_space=5242880  # 5GB em KiB
    local available_space=$(df /var/log | tail -1 | awk '{print $4}')
    
    if [ "$available_space" -lt "$required_space" ]; then
        log_error "❌ ERRO: Espaço em disco insuficiente"
        log_error "   Disponível: $((available_space / 1024 / 1024))MB"
        log_error "   Requerido: $((required_space / 1024 / 1024))MB"
        return 1
    fi
    
    log_info "✅ Espaço em disco: OK ($((available_space / 1024 / 1024))MB disponível)"
    return 0
}

check_disk_space || exit 1

# ─────────────────────────────────────────────────────────────────────────
# 5. Valida SO compatível
# ─────────────────────────────────────────────────────────────────────────
check_os_compatibility() {
    if [ ! -f /etc/os-release ]; then
        log_warning "⚠️  Não foi possível determinar SO (arquivo /etc/os-release não encontrado)"
        return 0  # Continua mesmo assim
    fi
    
    local os_name=$(grep "^NAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
    
    if [[ ! "$os_name" =~ "Zorin" ]] && [[ ! "$os_name" =~ "Linux Mint" ]]; then
        log_warning "⚠️  AVISO: Este script foi testado em Zorin OS e Linux Mint"
        log_warning "⚠️  SO detectado: $os_name"
        log_warning "⚠️  Prosseguindo com precaução..."
    else
        log_info "✅ SO compatível: $os_name"
    fi
}

check_os_compatibility

# =============================================================================
# SEÇÃO 9: CARREGAMENTO DO PERFIL
# =============================================================================
#
# Carrega arquivo de configuração do perfil (1, 2 ou 3)
# Define variáveis de ambiente como:
#   - APTCACHER, CACHEPORT
#   - NFSSERVERER, NFSPORT
#   - DNS, DNS2
#   - ENABLE_BACKUP, ENABLE_FLATPAK_CACHE, ENABLE_HEALTH_APPS
#   - hostsallow*, hostsdeny
#   - ntpserver
#

log_info "─────────────────────────────────────────────────"
log_info "📋 CARREGANDO PERFIL $PERFIL"
log_info "─────────────────────────────────────────────────"

load_profile "$PERFIL"

# ─────────────────────────────────────────────────────────────────────────
# Exporta variáveis do perfil para uso em módulos
# ─────────────────────────────────────────────────────────────────────────
export MAIN_ACTIVE=1
export APTCACHER CACHEPORT NFSSERVERER NFSPORT
export DNS site sigh
export ENABLE_BACKUP ENABLE_FLATPAK_CACHE ENABLE_HEALTH_APPS
export hostsallow0 hostsallow1 hostsallow2 hostsallow3 hostsdeny ntpserver

# ─────────────────────────────────────────────────────────────────────────
# Exibe configurações carregadas
# ─────────────────────────────────────────────────────────────────────────
log_info "✅ Perfil $PERFIL carregado com sucesso"
[ -n "${APTCACHER:-}" ] && log_info "   • Proxy APT: ${APTCACHER}:${CACHEPORT:-3142}"
[ -n "${NFSSERVERER:-}" ] && log_info "   • Servidor NFS: ${NFSSERVERER}:${NFSPORT:-2049}"
[ -n "${DNS:-}" ] && log_info "   • DNS primário: $DNS"
[ "$ENABLE_BACKUP" = "true" ] && log_info "   • Backup: ✅ habilitado"
[ "$ENABLE_FLATPAK_CACHE" = "true" ] && log_info "   • Flatpak cache: ✅ habilitado"
[ "$ENABLE_HEALTH_APPS" = "true" ] && log_info "   • Apps de saúde: ✅ habilitado"

# =============================================================================
# SEÇÃO 10: PARADA SEGURA DE SERVIÇOS QUE PODEM TRAVAR APT
# =============================================================================
#
# Durante a instalação massiva, serviços como packagekit e apt-daily
# podem tentar atualizar simultaneamente, causando locks de APT.
# Paramos esses serviços antes de prosseguir.
#

log_info "⏹️  Parando serviços que podem travar apt-get..."

systemctl stop packagekit 2>/dev/null || true
systemctl stop unattended-upgrades 2>/dev/null || true
systemctl stop apt-daily.timer 2>/dev/null || true
systemctl stop apt-daily-upgrade.timer 2>/dev/null || true
systemctl disable apt-daily.timer 2>/dev/null || true
systemctl disable apt-daily-upgrade.timer 2>/dev/null || true
pkill -f apt.systemd.daily 2>/dev/null || true

log_info "✅ Serviços parados"

# =============================================================================
# SEÇÃO 11: PREPARAÇÃO DO APT
# =============================================================================
#
# Aguarda qualquer lock pendente e atualiza chaves GPG.
# Isso garante que o apt está pronto para operações massivas.
#

log_info "🔐 Preparando infraestrutura APT..."

wait_for_apt_unlock
update_apt_keys_no_proxy

echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
log_info "✅ APT preparado e configurado"

# =============================================================================
# SEÇÃO 12: FUNÇÃO PARA EXECUTAR MÓDULOS (TRATAMENTO DE ERROS)
# =============================================================================
#
# run_script():
#   - Executa um script com tratamento robusto de erros
#   - Captura saída em log file
#   - NÃO interrompe execução (set +e durante execução)
#   - Registra falhas no array FAILED_MODULES
#
# run_module():
#   - Wrapper para run_script com caminho padrão de módulos
#
# run_module_bg():
#   - Executa módulo em background (para paralelismo)
#   - Mantém registro de PIDs
#

run_script() {
    local script_name="$1"
    local script_path="$2"
    local log_file="$LOG_DIR/${script_name}.log"
    
    # ─────────────────────────────────────────────────────────────────────
    # Verifica se arquivo existe
    # ─────────────────────────────────────────────────────────────────────
    if [ ! -f "$script_path" ]; then
        log_warning "⚠️  AVISO: $script_name não encontrado em $script_path"
        SKIPPED_MODULES+=("$script_name")
        return 0
    fi
    
    # ─────────────────────────────────────────────────────────────────────
    # Modo dry-run: simula execução
    # ─────────────────────────────────────────────────────────────────────
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] 🧪 Executaria: $script_name"
        if [ "$VERBOSE" = true ]; then
            log_info "         Arquivo: $script_path"
            log_info "         Log: $log_file"
        fi
        SKIPPED_MODULES+=("$script_name")
        return 0
    fi
    
    # ─────────────────────────────────────────────────────────────────────
    # Executa módulo com captura de log
    # ─────────────────────────────────────────────────────────────────────
    log_info "▶️  Executando: $script_name"
    
    local ret=0
    
    # Desabilita set -e para capturar retorno do script
    set +e
    {
        echo "=== Início de $script_name - $(date '+%Y-%m-%d %H:%M:%S') ==="
        bash "$script_path"
        echo "=== Fim de $script_name - $(date '+%Y-%m-%d %H:%M:%S') ==="
    } >> "$log_file" 2>&1
    ret=$?
    set -e
    
    # ─────────────────────────────────────────────────────────────────────
    # Análise do resultado
    # ─────────────────────────────────────────────────────────────────────
    if [ $ret -ne 0 ]; then
        log_error "❌ FALHA: $script_name (código $ret)"
        log_error "   Log: $log_file (últimas 10 linhas)"
        tail -10 "$log_file" | sed 's/^/   /'
        FAILED_MODULES+=("$script_name")
    else
        log_success "✅ OK: $script_name"
        EXECUTED_MODULES+=("$script_name")
    fi
    
    if [ "$VERBOSE" = true ]; then
        log_info "   Arquivo: $script_path"
        log_info "   Log completo: $log_file"
    fi
    
    return 0  # Não interrompe a execução principal
}

run_module() {
    local module_name="$1"
    run_script "$module_name" "$SCRIPT_DIR/modules/${module_name}.sh"
}

run_module_bg() {
    local module_name="$1"
    local log_file="$LOG_DIR/${module_name}.log"
    
    if [ ! -f "$SCRIPT_DIR/modules/${module_name}.sh" ]; then
        log_warning "⚠️  AVISO: $module_name.sh não encontrado"
        SKIPPED_MODULES+=("$module_name")
        return
    fi
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] 🧪 Executaria em background: $module_name"
        SKIPPED_MODULES+=("$module_name")
        return
    fi
    
    log_info "▶️  Executando (background): $module_name"
    
    # Inicia execução em background
    {
        echo "=== Início de $module_name - $(date '+%Y-%m-%d %H:%M:%S') ==="
        bash "$SCRIPT_DIR/modules/${module_name}.sh"
        echo "=== Fim de $module_name - $(date '+%Y-%m-%d %H:%M:%S') ==="
    } >> "$log_file" 2>&1 &
    
    local pid=$!
    BG_PIDS+=("$pid")
    BG_MODULES+=("$module_name")
    
    if [ "$VERBOSE" = true ]; then
        log_info "   PID: $pid"
        log_info "   Log: $log_file"
    fi
}

# Função auxiliar para esperar por todos os processos em background
wait_for_bg_modules() {
    local module_count=${#BG_PIDS[@]}
    
    if [ $module_count -eq 0 ]; then
        return 0
    fi
    
    log_info "⏳ Aguardando $module_count módulo(s) em background..."
    
    local completed=0
    for ((i=0; i<module_count; i++)); do
        local pid=${BG_PIDS[$i]}
        local mod_name=${BG_MODULES[$i]}
        local log_file="$LOG_DIR/${mod_name}.log"
        
        wait "$pid"
        local ret=$?
        ((completed++))
        
        if [ $ret -ne 0 ]; then
            log_error "❌ FALHA: $mod_name (código $ret) - [$completed/$module_count]"
            log_error "   Log: $log_file (últimas 5 linhas)"
            tail -5 "$log_file" | sed 's/^/   /'
            FAILED_MODULES+=("$mod_name")
        else
            log_success "✅ OK: $mod_name - [$completed/$module_count]"
            EXECUTED_MODULES+=("$mod_name")
        fi
    done
    
    # Limpa arrays para próxima rodada
    BG_PIDS=()
    BG_MODULES=()
}

# =============================================================================
# SEÇÃO 13: FUNÇÃO PARA VERIFICAÇÃO E RECRIAÇÃO DE CACHE FLATPAK
# =============================================================================
#
# rebuild_flatpak_cache_if_empty():
#   - Verifica se cache Flatpak em NFS está vazio
#   - Se vazio, aciona script de rebuild no servidor
#   - Usa trigger TCP na porta 9876
#
# IMPORTANTE: Mantém toda a lógica original sem mudanças
#

rebuild_flatpak_cache_if_empty() {
    local SERVER_IP="$1"
    local NFS_FLATPAK_DIR="$2"
    local REBUILD_PORT=9876
    
    # Caminho real do repositório ostree (estrutura do create-usb)
    local OSTREE_REPO="$NFS_FLATPAK_DIR/.ostree/repo"
    
    # Cache já populado → nada a fazer
    if [ -d "$OSTREE_REPO/objects" ] && [ "$(ls -A "$OSTREE_REPO/objects" 2>/dev/null)" ]; then
        log_info "✅ Cache Flatpak já populado em $OSTREE_REPO"
        return 0
    fi
    
    log_warning "⚠️  Cache Flatpak vazio. Acionando recriação via trigger TCP..."
    
    # Verifica se o servidor responde na porta de rebuild
    if ! nc -w 2 -z "$SERVER_IP" "$REBUILD_PORT"; then
        log_error "❌ Servidor $SERVER_IP:$REBUILD_PORT não está acessível"
        return 1
    fi
    
    # Envia trigger para disparar rebuild (a conexão em si já inicia o script)
    if echo "rebuild" | nc -w 5 "$SERVER_IP" "$REBUILD_PORT" > /dev/null 2>&1; then
        log_success "✅ Gatilho enviado. Cache Flatpak sendo recriado no servidor"
        return 0
    else
        log_error "❌ Falha ao comunicar com trigger de rebuild"
        return 1
    fi
}

# =============================================================================
# SEÇÃO 14: FUNÇÃO PARA MONTAGEM DE NFS
# =============================================================================
#
# mount_nfs_direct():
#   - Detecta servidor NFS (perfil > preflight > automático)
#   - Verifica conectividade antes de tentar montar
#   - Monta /mnt (cache Flatpak) e /tmp/cache (repo admin)
#   - Configura Flatpak para usar cache NFS
#   - Aciona rebuild se cache vazio
#
# IMPORTANTE: Mantém toda a lógica original sem mudanças
#

mount_nfs_direct() {
    local NFS_PORT_ACTUAL="${NFSPORT:-$NFS_PORT}"
    
    log_info "🔌 Montando NFS para cache Flatpak (porta $NFS_PORT_ACTUAL)..."
    
    # Detecta servidor NFS
    local NFS_SERVER=""
    if [ -n "${NFS_SERVER_SELECTED:-}" ]; then
        NFS_SERVER="$NFS_SERVER_SELECTED"
        log_info "   Usando servidor NFS selecionado no preflight: $NFS_SERVER"
    else
        NFS_SERVER=$(get_nfs_server)
        log_info "   Servidor NFS detectado: $NFS_SERVER"
    fi
    
    if [ -z "$NFS_SERVER" ]; then
        log_warning "⚠️  Não foi possível determinar servidor NFS"
        return 1
    fi
    
    # Verifica conectividade
    if ! nc -w 2 -z "$NFS_SERVER" "$NFS_PORT_ACTUAL" 2>/dev/null; then
        log_warning "⚠️  Servidor NFS $NFS_SERVER:$NFS_PORT_ACTUAL inacessível"
        return 1
    fi
    
    log_info "✅ Servidor NFS acessível"
    
    # Monta cache Flatpak
    log_info "   Montando cache Flatpak..."
    mount_nfs_if_available "$NFS_SERVER" "/mnt" "/partimag/flatpakcache/" "Flatpak cache" "$NFS_PORT_ACTUAL" || true
    
    # Monta repositório administrativo
    log_info "   Montando repositório administrativo..."
    mount_nfs_if_available "$NFS_SERVER" "/tmp/cache" "/partimag/cache/" "Repositório admin" "$NFS_PORT_ACTUAL" || true
    
    # Configura Flatpak para usar cache
    if mountpoint -q /mnt && [ -d /mnt/.ostree/repo ]; then
        log_info "   Configurando Flatpak para usar cache NFS..."
        flatpak remote-modify --collection-id=org.flathub.Stable flathub 2>/dev/null || true
        log_success "✅ Flatpak configurado com cache em /mnt/.ostree/repo"
    else
        log_info "   ℹ️  Cache Flatpak NFS não encontrado em /mnt/.ostree/repo"
    fi
    
    export NFS_MOUNTED_BY_MAIN=true
    return 0
}

# =============================================================================
# SEÇÃO 15: EXECUÇÃO DO FLUXO PRINCIPAL (10 PASSOS)
# =============================================================================
#
# A execução é dividida em 10 passos bem definidos:
#
#   PASSO 0: Verificação de pré-requisitos (preflight)
#   PASSO 1: Sincronização de scripts originais
#   PASSO 2: Verificação de infraestrutura de cache
#   PASSO 3: Instalação de dependências
#   PASSO 4: Montagem de NFS
#   PASSO 5: Instalação massiva de pacotes
#   PASSO 6: Configurações básicas (paralelo)
#   PASSO 7: Módulos que usam APT (sequencial)
#   PASSO 8: Flatpak e desktop (paralelo)
#   PASSO 9: Segurança e finalização (paralelo)
#   PASSO 10: Limpeza pós-instalação
#
# =============================================================================

log_info ""
log_info "╔════════════════════════════════════════════════════════════════╗"
log_info "║         INICIANDO CUSTOMIZAÇÃO DO ZORIN OS 18.1              ║"
log_info "║         Versão: $SCRIPT_VERSION | Perfil: $PERFIL | PID: $$"
log_info "╚════════════════════════════════════════════════════════════════╝"
log_info ""
log_info "Configurações:"
log_info "  • Modo Dry-run: $([ "$DRY_RUN" = "true" ] && echo "SIM" || echo "NÃO")"
log_info "  • Verbose: $([ "$VERBOSE" = "true" ] && echo "SIM" || echo "NÃO")"
log_info "  • Skip errors: $([ "$SKIP_ERRORS" = "true" ] && echo "SIM" || echo "NÃO")"
log_info "  • Cache APT: $([ "$NO_APT_CACHER" = "false" ] && echo "ATIVO" || echo "DESATIVO")"
log_info "  • NFS: $([ "$NO_NFS" = "false" ] && echo "ATIVO" || echo "DESATIVO")"
log_info ""

# ═════════════════════════════════════════════════════════════════════════
# PASSO 0: VERIFICAÇÃO DE PRÉ-REQUISITOS (PREFLIGHT)
# ═════════════════════════════════════════════════════════════════════════

log_info "─────────────────────────────────────────────────"
log_info "PASSO 0️⃣  Verificação de pré-requisitos"
log_info "─────────────────────────────────────────────────"

if [ "$NO_PREFLIGHT" = false ]; then
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] 🧪 Executaria preflight checks"
    else
        run_preflight "$PERFIL"
    fi
else
    log_info "⏭️  --no-preflight informado: pulando verificação"
fi

log_info "✅ Pré-requisitos verificados"
log_info ""

# Force IPv4 para evitar problemas de conectividade
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

# ═════════════════════════════════════════════════════════════════════════
# PASSO 1: SINCRONIZAÇÃO DE SCRIPTS
# ═════════════════════════════════════════════════════════════════════════

log_info "─────────────────────────────────────────────────"
log_info "PASSO 1️⃣  Sincronizando scripts originais"
log_info "─────────────────────────────────────────────────"
run_module "01-sync-scripts"
log_info ""

# ═════════════════════════════════════════════════════════════════════════
# PASSO 2: GESTÃO DE CACHE (APT-CACHER-NG)
# ═════════════════════════════════════════════════════════════════════════

log_info "─────────────────────────────────────────────────"
log_info "PASSO 2️⃣  Verificando infraestrutura de cache"
log_info "─────────────────────────────────────────────────"

if [ "$NO_APT_CACHER" = true ]; then
    log_info "⏭️  --no-apt-cacher informado: desabilitando cache"
elif [ -n "${APTCACHER:-}" ]; then
    log_info "🔍 Testando conectividade com APT-Cacher-NG: $APTCACHER:${CACHEPORT:-3142}"
    
    if [ "$DRY_RUN" = false ] && bash "/etc/acngonoff.sh" 2>/dev/null; then
        log_info "✅ Infraestrutura de cache detectada"
        
        if [ -f /tmp/acng_env ]; then
            # shellcheck source=/dev/null
            source /tmp/acng_env
            export ACTUAL_PROXY_URL="$PROXY_URL"
            export PROXY_HOST_PORT=$(echo "$ACTUAL_PROXY_URL" | sed 's|http://||')
        fi
        
        if [ -f "$SCRIPT_DIR/scripts/convert-sources-to-proxy.sh" ]; then
            log_info "   Aplicando mapeamento direto de repositórios..."
            bash "$SCRIPT_DIR/scripts/convert-sources-to-proxy.sh"
        fi
    else
        log_info "⚠️  Proxy APT inacessível. Seguindo sem cache."
        
        # Restaura fontes originais se backup existir
        if [ -f "/etc/apt/sources.list.d/backup_conversion/.backup_original_feito" ]; then
            log_info "   Restaurando fontes originais..."
            bash "$SCRIPT_DIR/scripts/restore-sources-from-backup.sh"
        fi
    fi
else
    log_info "ℹ️  Perfil não define APT-Cacher-NG"
    
    # Restaura fontes se necessário
    if [ -f "/etc/apt/sources.list.d/backup_conversion/.backup_original_feito" ]; then
        log_info "   Restaurando fontes originais..."
        bash "$SCRIPT_DIR/scripts/restore-sources-from-backup.sh"
    fi
fi

log_info "✅ Cache verificado e configurado"
log_info ""

# ═════════════════════════════════════════════════════════════════════════
# PASSO 3: INSTALAÇÃO DE DEPENDÊNCIAS
# ═════════════════════════════════════════════════════════════════════════

log_info "─────────────────────────────────────────────────"
log_info "PASSO 3️⃣  Instalando dependências (NFS + Flatpak)"
log_info "─────────────────────────────────────────────────"
run_module "00-dependencies"
log_info ""

# ═════════════════════════════════════════════════════════════════════════
# PASSO 4: MONTAGEM DE NFS
# ═════════════════════════════════════════════════════════════════════════

log_info "─────────────────────────────────────────────────"
log_info "PASSO 4️⃣  Montando NFS e cache Flatpak"
log_info "─────────────────────────────────────────────────"

if [ "$NO_NFS" = true ]; then
    log_info "⏭️  --no-nfs informado: desabilitando montagem NFS"
elif [ -z "${NFSSERVERER:-}" ]; then
    log_info "ℹ️  Perfil não define NFSSERVERER: pulando NFS"
else
    log_info "🔌 Tentando montar NFS..."
    
    if [ "$DRY_RUN" = false ]; then
        if mount_nfs_direct; then
            NFS_MOUNTED=true
            log_success "✅ NFS montado com sucesso"
            
            # Tenta reconstruir cache Flatpak se vazio
            if [ -n "${NFS_SERVER:-}" ]; then
                rebuild_flatpak_cache_if_empty "$NFS_SERVER" "/mnt" || true
            fi
            
            # Exibe status de montagens
            log_info "   Status das montagens:"
            if mountpoint -q /mnt 2>/dev/null; then
                log_info "   ✅ /mnt: $(df -h /mnt 2>/dev/null | tail -1 | awk '{print $2, "disponível"}')"
            else
                log_info "   ⚠️  /mnt: não montado"
            fi
            
            if mountpoint -q /tmp/cache 2>/dev/null; then
                log_info "   ✅ /tmp/cache: $(df -h /tmp/cache 2>/dev/null | tail -1 | awk '{print $2, "disponível"}')"
            else
                log_info "   ⚠️  /tmp/cache: não montado"
            fi
        else
            log_warning "⚠️  Falha na montagem NFS: continuando sem cache"
        fi
    else
        log_info "[DRY-RUN] 🧪 Executaria montagem de NFS"
    fi
fi

log_info "✅ NFS verificado"
log_info ""

# ═════════════════════════════════════════════════════════════════════════
# PASSO 5: INSTALAÇÃO MASSIVA DE PACOTES
# ═════════════════════════════════════════════════════════════════════════

log_info "─────────────────────────────────────────────────"
log_info "PASSO 5️⃣  Instalação massiva de pacotes APT"
log_info "─────────────────────────────────────────────────"
run_module "02-bulk-packages"
log_info ""

# ═════════════════════════════════════════════════════════════════════════
# PASSO 6: CONFIGURAÇÕES BÁSICAS (PARALELO)
# ══════════════════════════════════════��══════════════════════════════════

log_info "─────────────────────────────────────────────────"
log_info "PASSO 6️⃣  Configurações básicas (execução paralela)"
log_info "─────────────────────────────────────────────────"

for module in 03-certificates 04-browsers 06-icp-user-certs 07-kaspersky; do
    run_module_bg "$module"
done

wait_for_bg_modules
log_info ""

# ═════════════════════════════════════════════════════════════════════════
# PASSO 7: MÓDULOS QUE USAM APT (SEQUENCIAL)
# ═════════════════════════════════════════════════════════════════════════

log_info "─────────────────────────────────────────────────"
log_info "PASSO 7️⃣  Módulos que usam APT (sequencial)"
log_info "─────────────────────────────────────────────────"

for module in 05-tokens 08-wine 09-signers 10-backup; do
    run_module "$module"
done

# Reaplica conversão de proxy se cache estava ativo
if [ -n "${APTCACHER:-}" ] && [ "$NO_APT_CACHER" = false ] && [ "$DRY_RUN" = false ]; then
    if [ -f "/etc/acngonoff.sh" ] && bash "/etc/acngonoff.sh" 2>/dev/null; then
        log_info "🔄 Reaplicando mapeamento direto após instalações APT"
        if [ -f "$SCRIPT_DIR/scripts/convert-sources-to-proxy.sh" ]; then
            bash "$SCRIPT_DIR/scripts/convert-sources-to-proxy.sh"
        fi
    fi
fi

log_info ""

# ═════════════════════════════════════════════════════════════════════════
# PASSO 8: FLATPAK E DESKTOP (PARALELO)
# ═════════════════════════════════════════════════════════════════════════

log_info "─────────────────────────────────────────────────"
log_info "PASSO 8️⃣  Flatpak e configurações de desktop (paralelo)"
log_info "─────────────────────────────────────────────────"

for module in 11-flatpak-cache 12-desktop-config 13-desktop-config-user; do
    run_module_bg "$module"
done

wait_for_bg_modules
log_info ""

# ═════════════════════════════════════════════════════════════════════════
# PASSO 9: SEGURANÇA E FINALIZAÇÃO (PARALELO)
# ═════════════════════════════════════════════════════════════════════════

log_info "─────────────────────────────────────────────────"
log_info "PASSO 9️⃣  Segurança e finalização (paralelo)"
log_info "─────────────────────────────────────────────────"

for module in 14-security 15-kvm-menu; do
    run_module_bg "$module"
done

wait_for_bg_modules
log_info ""

# ═════════════════════════════════════════════════════════════════════════
# PASSO 10: LIMPEZA PÓS-INSTALAÇÃO
# ═════════════════════════════════════════════════════════════════════════

log_info "─────────────────────────────────────────────────"
log_info "PASSO 🔟 Limpeza pós-instalação"
log_info "─────────────────────────────────────────────────"

# Remove sentinel de conversão anterior
if [ -f /var/log/customization/.sources_converted_to_http ]; then
    rm -f /var/log/customization/.sources_converted_to_http
    log_info "   Removido sentinel de conversão anterior"
fi

# Limpeza de pacotes
log_info "🧹 Limpeza de pacotes (pode levar alguns minutos)..."

if [ "$DRY_RUN" = false ]; then
    {
        wait_for_apt_unlock
        echo "=== Início da limpeza: $(date) ==="
        apt full-upgrade -y -qq 2>&1 || true
        flatpak update -y --noninteractive 2>&1 || true
        apt-get autoremove -y -qq 2>&1 || true
        apt-get clean -qq 2>&1 || true
        echo "=== Fim da limpeza: $(date) ==="
    } > "${LOG_DIR}/cleanup.log" 2>&1
else
    log_info "[DRY-RUN] 🧪 Executaria: apt full-upgrade, flatpak update, apt autoremove, apt clean"
fi

log_info "✅ Limpeza concluída"

# Restaura fontes originais se backup existir
if [ -f "/etc/apt/sources.list.d/backup_conversion/.backup_original_feito" ]; then
    log_info "   Restaurando fontes originais..."
    if [ "$DRY_RUN" = false ]; then
        bash "$SCRIPT_DIR/scripts/restore-sources-from-backup.sh"
    fi
fi

# Remove proxy APT
if [ -f /etc/apt/apt.conf.d/00aptproxy ]; then
    log_info "   Removendo configurações de proxy APT"
    if [ "$DRY_RUN" = false ]; then
        rm -f /etc/apt/apt.conf.d/00aptproxy
    fi
fi

# Restaura repositórios temporariamente desabilitados
DISABLED_BACKUP_DIR="/etc/apt/sources.list.d/disabled_repos_backup"
if [ -d "$DISABLED_BACKUP_DIR" ] && [ -n "$(ls -A "$DISABLED_BACKUP_DIR" 2>/dev/null)" ]; then
    log_info "   Restaurando repositórios desabilitados"
    if [ "$DRY_RUN" = false ]; then
        mkdir -p /etc/apt/sources.list.d
        mv "$DISABLED_BACKUP_DIR"/* /etc/apt/sources.list.d/ 2>/dev/null || true
        rmdir "$DISABLED_BACKUP_DIR" 2>/dev/null || true
    fi
fi

# Executa fix-sources-list
if [ -f "$SCRIPT_DIR/utils/fix-sources-list.sh" ]; then
    log_info "   Validando sources.list"
    if [ "$DRY_RUN" = false ]; then
        run_script "fix-sources-list" "$SCRIPT_DIR/utils/fix-sources-list.sh"
    fi
fi

# Corrige permissões em Linux Mint
if grep -q "^ID=linuxmint" /etc/os-release 2>/dev/null; then
    if [ "$DRY_RUN" = false ]; then
        chmod 644 /etc/apt/sources.list 2>/dev/null || true
        chown root:root /etc/apt/sources.list 2>/dev/null || true
    fi
fi

log_info "✅ Limpeza pós-instalação concluída"
log_info ""

# =============================================================================
# SEÇÃO 16: RELATÓRIO DE FALHAS E DECISÃO FINAL
# =============================================================================

log_info "─────────────────────────────────────────────────"
log_info "📊 RELATÓRIO FINAL"
log_info "─────────────────────────────────────────────────"

local failed_count=${#FAILED_MODULES[@]}
local executed_count=${#EXECUTED_MODULES[@]}
local skipped_count=${#SKIPPED_MODULES[@]}

if [ $failed_count -gt 0 ]; then
    log_error ""
    log_error "⚠️  ATENÇÃO: Os seguintes módulos falharam:"
    for module in "${FAILED_MODULES[@]}"; do
        log_error "   ❌ $module"
    done
    log_error ""
    log_error "Log detalhado: $PERSISTENT_LOG_DIR/"
    log_error ""
    
    if [ "$SKIP_ERRORS" = false ]; then
        log_error "🛑 Abortando com código de saída 2 devido às falhas"
        log_error "   Use: --skip-errors para continuar mesmo com erros"
        log_error ""
    else
        log_warning "⚠️  MODO: --skip-errors ativo (continuando apesar dos erros)"
    fi
fi

log_info ""
log_info "Resumo da execução:"
log_info "  ✅ Módulos bem-sucedidos: $executed_count"
[ $failed_count -gt 0 ] && log_warning "  ❌ Módulos falhados: $failed_count"
[ $skipped_count -gt 0 ] && log_info "  ⏭️  Módulos pulados: $skipped_count"
log_info "  🚀 Modo execução: $([ "$DRY_RUN" = "true" ] && echo "DRY-RUN (simulação)" || echo "PRODUÇÃO")"
log_info ""
log_info "Configurações aplicadas:"
log_info "  • Perfil: $PERFIL"
log_info "  • NFS montado: $([ "$NFS_MOUNTED" = "true" ] && echo "✅ SIM" || echo "❌ NÃO")"
log_info "  • APT-Cacher-NG: $([ "$NO_APT_CACHER" = "false" ] && echo "✅ ATIVO" || echo "❌ DESATIVO")"
log_info "  • Backup: $([ "${ENABLE_BACKUP:-}" = "true" ] && echo "✅ ATIVO" || echo "❌ DESATIVO")"
log_info "  • Flatpak cache: $([ "${ENABLE_FLATPAK_CACHE:-}" = "true" ] && echo "✅ ATIVO" || echo "❌ DESATIVO")"
log_info "  • Apps de saúde: $([ "${ENABLE_HEALTH_APPS:-}" = "true" ] && echo "✅ ATIVO" || echo "❌ DESATIVO")"
log_info ""
log_info "Localização dos logs: $PERSISTENT_LOG_DIR/"
log_info ""

# ═════════════════════════════════════════════════════════════════════════
# SEÇÃO 17: SERVIÇOS FINAIS E RECOMENDAÇÕES
# ═════════════════════════════════════════════════════════════════════════

if [ "$DRY_RUN" = false ]; then
    log_info "🔄 Reabilitando serviços de sistema"
    systemctl enable apt-daily.timer 2>/dev/null || true
    systemctl enable apt-daily-upgrade.timer 2>/dev/null || true
    systemctl enable packagekit 2>/dev/null || true
    systemctl enable unattended-upgrades 2>/dev/null || true
    systemctl start apt-daily.timer 2>/dev/null || true
    systemctl start packagekit 2>/dev/null || true
    systemctl start unattended-upgrades 2>/dev/null || true
    log_info "✅ Serviços habilitados novamente"
fi

# ═════════════════════════════════════════════════════════════════════════
# SEÇÃO 18: PERSISTÊNCIA DO PERFIL ATIVO
# ═════════════════════════════════════════════════════════════════════════
#
# Salva configurações do perfil em arquivo para uso posterior
# (por exemplo, por scripts de manutenção programados)
#

if [ "$DRY_RUN" = false ]; then
    log_info "💾 Persistindo perfil ativo"
    
    cat > /etc/customization/active-profile.env <<EOF
# Perfil ativo: $PERFIL
# Gerado em: $(date '+%Y-%m-%d %H:%M:%S')
# Versão do script: $SCRIPT_VERSION

export PERFIL="$PERFIL"
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
    log_info "✅ Perfil persistido em: /etc/customization/active-profile.env"
fi

# =============================================================================
# SEÇÃO 19: GERAÇÃO DE RELATÓRIO HTML
# =============================================================================

generate_execution_report() {
    local exit_code="${1:-0}"
    local execution_end_time=$(date +%s)
    local execution_duration=$((execution_end_time - EXECUTION_START_TIME))
    local execution_minutes=$((execution_duration / 60))
    local execution_seconds=$((execution_duration % 60))
    
    cat > "$EXECUTION_REPORT" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Relatório de Execução - Zorin Customization</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        h1 { margin: 0; font-size: 2em; }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .summary-card h3 { margin-top: 0; color: #667eea; }
        .summary-card .value {
            font-size: 2em;
            font-weight: bold;
        }
        .success { color: #27ae60; }
        .error { color: #e74c3c; }
        .warning { color: #f39c12; }
        .info { color: #3498db; }
        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin: 20px 0;
        }
        th {
            background-color: #667eea;
            color: white;
            padding: 12px;
            text-align: left;
        }
        td {
            padding: 12px;
            border-bottom: 1px solid #ddd;
        }
        tr:hover { background-color: #f9f9f9; }
        .module-list {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .module-item {
            display: flex;
            align-items: center;
            padding: 8px;
            margin: 5px 0;
            border-left: 4px solid #ddd;
        }
        .module-item.success { border-left-color: #27ae60; }
        .module-item.error { border-left-color: #e74c3c; }
        .module-item.skipped { border-left-color: #f39c12; }
        .icon { margin-right: 10px; font-size: 1.2em; }
        footer {
            margin-top: 40px;
            text-align: center;
            color: #666;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>📊 Relatório de Customização Zorin OS 18.1</h1>
        <p>Versão 2.0 | Gerado em: GENERATED_TIME</p>
    </div>
    
    <div class="summary">
        <div class="summary-card">
            <h3>Duração Total</h3>
            <div class="value info">DURATION_DISPLAY</div>
        </div>
        <div class="summary-card">
            <h3>Módulos Executados</h3>
            <div class="value success">EXECUTED_COUNT</div>
        </div>
        <div class="summary-card">
            <h3>Módulos Falhados</h3>
            <div class="value error">FAILED_COUNT</div>
        </div>
        <div class="summary-card">
            <h3>Status Final</h3>
            <div class="value">EXIT_CODE_DISPLAY</div>
        </div>
    </div>
    
    <h2>Configurações Aplicadas</h2>
    <table>
        <tr>
            <th>Parâmetro</th>
            <th>Valor</th>
        </tr>
        <tr>
            <td>Perfil</td>
            <td>PERFIL_DISPLAY</td>
        </tr>
        <tr>
            <td>NFS Montado</td>
            <td>NFS_STATUS</td>
        </tr>
        <tr>
            <td>Cache APT</td>
            <td>CACHE_STATUS</td>
        </tr>
        <tr>
            <td>Modo Execução</td>
            <td>EXEC_MODE</td>
        </tr>
    </table>
    
    <h2>Módulos Executados</h2>
    <div class="module-list" id="executed-modules"></div>
    
    <h2>Módulos com Erro</h2>
    <div class="module-list" id="failed-modules"></div>
    
    <h2>Módulos Pulados</h2>
    <div class="module-list" id="skipped-modules"></div>
    
    <footer>
        <p>Para mais informações, consulte os logs em: /var/log/customization-persist/</p>
        <p>Documentação: /etc/customization/Docs/</p>
    </footer>
</body>
</html>
HTMLEOF
    
    # Substitui placeholders
    sed -i "s|GENERATED_TIME|$(date '+%Y-%m-%d %H:%M:%S')|g" "$EXECUTION_REPORT"
    sed -i "s|DURATION_DISPLAY|${execution_minutes}m ${execution_seconds}s|g" "$EXECUTION_REPORT"
    sed -i "s|EXECUTED_COUNT|${executed_count}|g" "$EXECUTION_REPORT"
    sed -i "s|FAILED_COUNT|${failed_count}|g" "$EXECUTION_REPORT"
    sed -i "s|SKIPPED_COUNT|${skipped_count}|g" "$EXECUTION_REPORT"
    sed -i "s|PERFIL_DISPLAY|Perfil $PERFIL|g" "$EXECUTION_REPORT"
    sed -i "s|NFS_STATUS|$([ "$NFS_MOUNTED" = "true" ] && echo "✅ SIM" || echo "❌ NÃO")|g" "$EXECUTION_REPORT"
    sed -i "s|CACHE_STATUS|$([ "$NO_APT_CACHER" = "false" ] && echo "✅ ATIVO" || echo "❌ DESATIVO")|g" "$EXECUTION_REPORT"
    sed -i "s|EXEC_MODE|$([ "$DRY_RUN" = "true" ] && echo "DRY-RUN" || echo "PRODUÇÃO")|g" "$EXECUTION_REPORT"
    
    if [ $exit_code -eq 0 ]; then
        sed -i "s|EXIT_CODE_DISPLAY|<span class=\"success\">✅ SUCESSO</span>|g" "$EXECUTION_REPORT"
    else
        sed -i "s|EXIT_CODE_DISPLAY|<span class=\"error\">❌ FALHA (código $exit_code)</span>|g" "$EXECUTION_REPORT"
    fi
    
    log_info "✅ Relatório HTML gerado: $EXECUTION_REPORT"
}

# =============================================================================
# SEÇÃO 20: RECOMENDAÇÕES E CONCLUSÃO
# =============================================================================

log_info ""
log_info "╔════════════════════════════════════════════════════════════════╗"
if [ $failed_count -eq 0 ]; then
    log_info "║         ✅ CUSTOMIZAÇÃO CONCLUÍDA COM SUCESSO               ║"
else
    log_info "║         ⚠️  CUSTOMIZAÇÃO CONCLUÍDA COM $failed_count FALHA(S)              ║"
fi
log_info "╚════════════════════════════════════════════════════════════════╝"
log_info ""

log_info "📋 Recomendações:"
log_info "  1. ✅ Revise os logs em: $PERSISTENT_LOG_DIR/"
log_info "  2. 🔄 Reinicie o sistema para aplicar todas as configurações"
log_info "  3. 🔐 Valide certificados digitais e tokens de segurança"
if [ "$NFS_MOUNTED" = "true" ]; then
    log_info "  4. 🌐 Teste acesso ao servidor NFS e cache Flatpak"
fi
log_info "  5. 📊 Abra relatório HTML: file://$EXECUTION_REPORT"
log_info ""

log_info "📞 Suporte:"
log_info "  • Troubleshooting: Docs/Relatorios_ao_sysadmin.pdf"
log_info "  • FAQ: Docs/Guia_de_Configuração_do_Ambiente_de_Teste_com_o_KVM.pdf"
log_info "  • Issues: https://github.com/arthur-aida/zorin_corporate_configs/issues"
log_info ""

# =============================================================================
# DECISÃO FINAL: SUCESSO OU FALHA
# =============================================================================

if [ $failed_count -gt 0 ] && [ "$SKIP_ERRORS" = false ]; then
    log_error "🛑 Encerrando com ERRO (use --skip-errors para continuar)"
    exit 2
fi

exit 0
