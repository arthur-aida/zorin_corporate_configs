#!/bin/bash
# script executado no espaço do usuário (sem acesso root)
# ==============================================================================
# Script: import-icp-brasil.sh
# ==============================================================================
set -uo pipefail

# Habilita nullglob para evitar iteração sobre glob literal
shopt -s nullglob

# Caminhos fundamentais (resolver links simbólicos)
ROOT_CERTS_DIR_LINK="/etc/ssl/certs/icp-brasil"
SYS_VERSION="/etc/ssl/certs/icp-version.txt"

USER_FLAG="$HOME/.local/share/ca-certificates/.processado"
LOG_FILE="$HOME/.local/share/icp-certs/import.log"

# Garantir diretório do flag e log
mkdir -p "$(dirname "$USER_FLAG")" "$(dirname "$LOG_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }
warn() { log "AVISO: $*"; echo "$*" >&2; }

# ------------------------------------------------------------------------------
# 0. Verificações iniciais de ambiente
# ------------------------------------------------------------------------------
log "Iniciando sincronização de certificados ICP-Brasil..."

# 0.a Checar gatilho de versão do sistema
if [ ! -f "$SYS_VERSION" ]; then
    warn "Arquivo $SYS_VERSION não encontrado. Nada a fazer (gatilho ausente)."
    exit 0
fi

# 0.b Checar se já foi processado com a mesma versão
if [ -f "$USER_FLAG" ] && [ "$(cat "$USER_FLAG")" == "$(cat "$SYS_VERSION")" ]; then
    log "Certificados já estão atualizados para a versão $(cat "$SYS_VERSION")."
    exit 0
fi

# 0.c Resolver diretório real dos certificados (tratar links)
if [ ! -e "$ROOT_CERTS_DIR_LINK" ]; then
    warn "Diretório $ROOT_CERTS_DIR_LINK não existe. Abortando."
    exit 0
fi

# Obter caminho real, tratando caso seja link simbólico ou diretório comum
ROOT_CERTS_DIR=$(readlink -f "$ROOT_CERTS_DIR_LINK" 2>/dev/null || echo "$ROOT_CERTS_DIR_LINK")
if [ ! -d "$ROOT_CERTS_DIR" ]; then
    warn "Caminho real dos certificados ($ROOT_CERTS_DIR) não é um diretório acessível. Abortando."
    exit 0
fi

# Verificar se há pelo menos um certificado
CERTS=( "$ROOT_CERTS_DIR"/*.crt )
if [ ${#CERTS[@]} -eq 0 ]; then
    warn "Nenhum arquivo .crt encontrado em $ROOT_CERTS_DIR. Abortando."
    exit 0
fi
log "Encontrados ${#CERTS[@]} certificados em $ROOT_CERTS_DIR."

# 0.d Verificar se ferramentas necessárias estão disponíveis
HAS_TRUST=false
HAS_CERTUTIL=false
command -v trust    >/dev/null 2>&1 && HAS_TRUST=true    || warn "Ferramenta 'trust' (p11-kit) não instalada."
command -v certutil >/dev/null 2>&1 && HAS_CERTUTIL=true || warn "Ferramenta 'certutil' não instalada."
command -v pkill    >/dev/null 2>&1 || warn "'pkill' não encontrado, browsers podem não ser encerrados."

# ------------------------------------------------------------------------------
# 1. Garantir que existam bancos NSS (cert9.db) do usuário
# ------------------------------------------------------------------------------
SEARCH_PATHS=("$HOME/.mozilla" "$HOME/.pki" "$HOME/.var")
FOUND_DBS=$(find "${SEARCH_PATHS[@]}" -name "cert9.db" 2>/dev/null)

if [ -z "$FOUND_DBS" ]; then
    log "Nenhum banco NSS (cert9.db) encontrado. Solicitando interação do usuário."
    if command -v zenity >/dev/null 2>&1; then
        zenity --warning --text="
NÃO FECHE ESTA JANELA. NÃO PRESSIONE OK AINDA.\n\n
Abra os navegadores (Firefox, Chrome, Brave, Edge) que deseja configurar." --timeout=600 2>/dev/null || true
    else
        echo ">>> Abra e feche os navegadores (Firefox, Chrome, etc.) e depois pressione [ENTER]." >&2
        read -r _
    fi
    # Pequena pausa para garantir que os bancos foram escritos em disco
    sleep 3
    FOUND_DBS=$(find "${SEARCH_PATHS[@]}" -name "cert9.db" 2>/dev/null)
    if [ -z "$FOUND_DBS" ]; then
        warn "Ainda não foi encontrado nenhum cert9.db. A importação nos navegadores via certutil será omitida."
    fi
fi

# ------------------------------------------------------------------------------
# 2. Encerrar navegadores para evitar locks nos bancos
# ------------------------------------------------------------------------------
log "Encerrando navegadores..."
pkill -f firefox 2>/dev/null || true
pkill -f chrome  2>/dev/null || true
pkill -f brave   2>/dev/null || true
pkill -f edge    2>/dev/null || true
sleep 1

# ------------------------------------------------------------------------------
# 3. Importação via p11-kit (trust)
# ------------------------------------------------------------------------------
if $HAS_TRUST; then
    log "Importando certificados com trust (p11-kit)..."
    mkdir -p "$HOME/.p11-kit/trust"
    cp "${CERTS[@]}" "$HOME/.p11-kit/trust/" 2>/dev/null || true
    for cert in "${CERTS[@]}"; do
        trust anchor --store "$cert" >/dev/null 2>&1 || true
        log "  trust: $cert"
    done
else
    log "Pulando etapa trust (p11-kit indisponível)."
fi

# ------------------------------------------------------------------------------
# 4. Injeção via certutil nos bancos NSS
# ------------------------------------------------------------------------------
if $HAS_CERTUTIL && [ -n "$FOUND_DBS" ]; then
    log "Injetando certificados nos bancos NSS com certutil..."
    while IFS= read -r db_path; do
        db_dir=$(dirname "$db_path")
        log "  Processando banco: $db_path"
        for cert_file in "${CERTS[@]}"; do
            cert_name=$(basename "$cert_file" .crt)
            if certutil -A -n "ICP-$cert_name" -t "TCu,Cu,Tu" -i "$cert_file" -d "sql:$db_dir" >> "$LOG_FILE" 2>&1; then
                log "    OK: $cert_file"
            else
                warn "    FALHA: $cert_file em $db_dir (detalhes em $LOG_FILE)"
            fi
        done
    done <<< "$FOUND_DBS"
else
    log "certutil indisponível ou nenhum banco NSS encontrado. Etapa certutil omitida."
fi

# ------------------------------------------------------------------------------
# 5. Finalização e registro
# ------------------------------------------------------------------------------
echo "$(cat "$SYS_VERSION")" > "$USER_FLAG"
log "Sincronização concluída com sucesso."
echo "IMPORTAÇÃO DE CERTIFICADOS FINALIZADA."
