#!/bin/bash
# =============================================================================
# convert-sources-to-proxy.sh (Roaming-ready)
#   - Converte fontes APT para uso de proxy (APT-Cacher-NG)
#   - Suporte total a .list e .sources (DEB822)
#   - Detecta mudança de proxy e atualiza as URLs automaticamente
#   - Opções: --force, --dry-run, --proxy=IP:PORT
# =============================================================================
set -uo pipefail

# -----------------------------------------------------------------------------
# FUNÇÕES DE LOG
# -----------------------------------------------------------------------------
log_info()  { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

# -----------------------------------------------------------------------------
# PARÂMETROS E OPÇÕES
# -----------------------------------------------------------------------------
FORCE_BACKUP=false
DRY_RUN=false
PROXY_URL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force) FORCE_BACKUP=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --proxy=*) PROXY_URL="${1#*=}"; shift ;;
        --proxy) PROXY_URL="$2"; shift 2 ;;
        *) log_error "Opção desconhecida: $1"; exit 1 ;;
    esac
done

# -----------------------------------------------------------------------------
# DETECÇÃO DO PROXY (via arquivo /tmp/acng_env ou argumento)
# -----------------------------------------------------------------------------
if [ -z "$PROXY_URL" ]; then
    if [ -f /tmp/acng_env ]; then
        source /tmp/acng_env
        PROXY_URL="${PROXY_URL:-}"
    fi
fi

if [ -z "$PROXY_URL" ]; then
    log_error "Proxy não definido. Forneça com --proxy=IP:PORT ou exporte PROXY_URL."
    exit 1
fi

CLEAN_PROXY=$(echo "$PROXY_URL" | sed 's|^http://||')
log_info "🔗 Usando proxy: $CLEAN_PROXY"

# -----------------------------------------------------------------------------
# CONFIGURAÇÕES
# -----------------------------------------------------------------------------
SOURCES_DIR="/etc/apt/sources.list.d"
MAIN_SOURCES="/etc/apt/sources.list"
BACKUP_DIR="${SOURCES_DIR}/backup_conversion"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_TAR="${BACKUP_DIR}/sources_backup_ORIGINAL.tar.gz"
MARKER_COMMENT="# CONVERTED_TO_PROXY_BY_SCRIPT"

mkdir -p "$BACKUP_DIR"

# -----------------------------------------------------------------------------
# FUNÇÕES AUXILIARES
# -----------------------------------------------------------------------------
# Verifica se o arquivo já possui o marcador
has_marker() {
    grep -q "^$MARKER_COMMENT" "$1" 2>/dev/null
}

# Adiciona o marcador no início do arquivo
add_marker() {
    if ! has_marker "$1"; then
        sed -i "1i$MARKER_COMMENT" "$1"
    fi
}

# Remove QUALQUER proxy de forma genérica (reversão)
strip_proxy() {
    local file="$1"
    # 1) http://IP:PORT/HTTPS///  → https://
    # 2) http://IP:PORT/          → http://
    sed -i -E \
        -e 's|http://[^/]*/HTTPS///|https://|g' \
        -e 's|http://[^/]*/|http://|g' \
        "$file"
}

# Aplica o proxy atual a um arquivo .list
apply_proxy_list() {
    local file="$1"
    sed -i \
        -e "s|https://\([^$CLEAN_PROXY]\)|http://$CLEAN_PROXY/HTTPS///\1|g" \
        -e "s|http://\([^$CLEAN_PROXY]\)|http://$CLEAN_PROXY/\1|g" \
        "$file"
}

# Aplica o proxy atual a um arquivo .sources (DEB822)
apply_proxy_sources() {
    local file="$1"
    sed -i -E \
        -e "s|(URIs:.*)https://([^ ]*)|\1 http://$CLEAN_PROXY/HTTPS///\2|g" \
        -e "s|(URIs:.*)http://([^ ]*)|\1 http://$CLEAN_PROXY/\2|g" \
        "$file"
}

# -----------------------------------------------------------------------------
# 1. BACKUP ORIGINAL (se necessário)
# -----------------------------------------------------------------------------
if [ "$FORCE_BACKUP" = true ] || [ ! -f "${BACKUP_DIR}/.backup_original_feito" ]; then
    if [ "$DRY_RUN" = true ]; then
        log_info "🔍 [DRY-RUN] Criaria backup original em $BACKUP_TAR"
    else
        log_info "🔒 Criando BACKUP ORIGINAL com tar..."
        tar -czf "$BACKUP_TAR" \
            -C /etc/apt sources.list \
            -C /etc/apt/sources.list.d \
            $(cd "$SOURCES_DIR" 2>/dev/null && ls *.list *.sources 2>/dev/null) \
            2>/dev/null

        if [ -s "$BACKUP_TAR" ]; then
            # Validação: o backup não deve conter o proxy
            if tar -xzf "$BACKUP_TAR" -O 2>/dev/null | grep -q "$CLEAN_PROXY"; then
                log_error "⚠️ O backup original parece já conter o proxy. Verifique as fontes antes de converter."
                exit 1
            fi
            touch "${BACKUP_DIR}/.backup_original_feito"
            log_info "✅ Backup original criado e validado."
        else
            log_error "❌ Falha ao criar backup original."
            exit 1
        fi
    fi
else
    log_info "ℹ️ Backup original já existe. Use --force para recriá-lo."
fi

# Cria backup timestamped (auditoria) sempre que não estiver em dry-run
if [ "$DRY_RUN" = false ]; then
    BACKUP_AUDIT_TAR="${BACKUP_DIR}/sources_backup_${TIMESTAMP}.tar.gz"
    tar -czf "$BACKUP_AUDIT_TAR" \
        -C /etc/apt sources.list \
        -C /etc/apt/sources.list.d \
        $(cd "$SOURCES_DIR" 2>/dev/null && ls *.list *.sources 2>/dev/null) \
        2>/dev/null
    log_info "📁 Backup timestamped: $BACKUP_AUDIT_TAR"
fi

# -----------------------------------------------------------------------------
# 2. CONVERSÃO DE ARQUIVOS .list (COM ROAMING)
# -----------------------------------------------------------------------------
log_info "🔄 Processando arquivos .list..."

convert_list_file() {
    local file="$1"
    local basename=$(basename "$file")

    # Ignora sources.list duplicado
    [ "$basename" = "sources.list" ] && return 0

    # Se NÃO tem marcador, é a primeira conversão
    if ! has_marker "$file"; then
        if [ "$DRY_RUN" = true ]; then
            log_info "   🔍 [DRY-RUN] Converteria $basename (novo)"
            return 0
        fi
        apply_proxy_list "$file"
        add_marker "$file"
        chmod 644 "$file"
        log_info "   ✅ $basename convertido pela primeira vez"
        return 0
    fi

    # --- Se TEM marcador, verifica se o proxy atual já está presente ---
    if grep -q "$CLEAN_PROXY" "$file" 2>/dev/null; then
        log_info "   ⏭️ $basename já está configurado com o proxy atual. Pulando."
        return 0
    fi

    # --- Proxy diferente detectado (ROAMING!) ---
    if [ "$DRY_RUN" = true ]; then
        log_info "   🔍 [DRY-RUN] Atualizaria proxy em $basename para $CLEAN_PROXY"
        return 0
    fi

    log_info "   🔄 $basename: proxy alterado detectado. Removendo proxy antigo..."
    strip_proxy "$file"
    log_info "   ➕ Aplicando novo proxy $CLEAN_PROXY..."
    apply_proxy_list "$file"
    # O marcador já existe, não precisa readicionar
    chmod 644 "$file"
    log_info "   ✅ $basename atualizado para o novo proxy"
}

for listfile in "$SOURCES_DIR"/*.list; do
    [ -f "$listfile" ] || continue
    convert_list_file "$listfile"
done

# -----------------------------------------------------------------------------
# 3. CONVERSÃO DE ARQUIVOS .sources (DEB822) COM ROAMING
# -----------------------------------------------------------------------------
log_info "🔄 Processando arquivos .sources (DEB822)..."

convert_sources_file() {
    local file="$1"
    local basename=$(basename "$file")

    # Pula se estiver desabilitado
    if grep -q "^Enabled: no" "$file" 2>/dev/null; then
        log_info "   ⏭️ $basename desabilitado (Enabled: no). Pulando."
        return 0
    fi

    # Se NÃO tem marcador, é a primeira conversão
    if ! has_marker "$file"; then
        if [ "$DRY_RUN" = true ]; then
            log_info "   🔍 [DRY-RUN] Converteria $basename (novo)"
            return 0
        fi
        apply_proxy_sources "$file"
        add_marker "$file"
        chmod 644 "$file"
        log_info "   ✅ $basename convertido pela primeira vez"
        return 0
    fi

    # --- Se TEM marcador, verifica se o proxy atual já está presente ---
    if grep -q "$CLEAN_PROXY" "$file" 2>/dev/null; then
        log_info "   ⏭️ $basename já está configurado com o proxy atual. Pulando."
        return 0
    fi

    # --- Proxy diferente detectado (ROAMING!) ---
    if [ "$DRY_RUN" = true ]; then
        log_info "   🔍 [DRY-RUN] Atualizaria proxy em $basename para $CLEAN_PROXY"
        return 0
    fi

    log_info "   🔄 $basename: proxy alterado detectado. Removendo proxy antigo..."
    strip_proxy "$file"
    log_info "   ➕ Aplicando novo proxy $CLEAN_PROXY..."
    apply_proxy_sources "$file"
    chmod 644 "$file"
    log_info "   ✅ $basename atualizado para o novo proxy"
}

for srcfile in "$SOURCES_DIR"/*.sources; do
    [ -f "$srcfile" ] || continue
    convert_sources_file "$srcfile"
done

# -----------------------------------------------------------------------------
# 4. CONVERSÃO DO sources.list PRINCIPAL (COM ROAMING)
# -----------------------------------------------------------------------------
if [ -f "$MAIN_SOURCES" ]; then
    if ! has_marker "$MAIN_SOURCES"; then
        if [ "$DRY_RUN" = true ]; then
            log_info "🔍 [DRY-RUN] Converteria $MAIN_SOURCES (novo)"
        else
            apply_proxy_list "$MAIN_SOURCES"
            add_marker "$MAIN_SOURCES"
            chmod 644 "$MAIN_SOURCES"
            log_info "   ✅ sources.list convertido pela primeira vez"
        fi
    else
        # Com marcador, verifica se o proxy atual já está presente
        if grep -q "$CLEAN_PROXY" "$MAIN_SOURCES" 2>/dev/null; then
            log_info "⏭️ sources.list já está configurado com o proxy atual."
        else
            if [ "$DRY_RUN" = true ]; then
                log_info "🔍 [DRY-RUN] Atualizaria proxy em sources.list para $CLEAN_PROXY"
            else
                log_info "🔄 sources.list: proxy alterado detectado. Removendo proxy antigo..."
                strip_proxy "$MAIN_SOURCES"
                log_info "   ➕ Aplicando novo proxy $CLEAN_PROXY..."
                apply_proxy_list "$MAIN_SOURCES"
                chmod 644 "$MAIN_SOURCES"
                log_info "   ✅ sources.list atualizado para o novo proxy"
            fi
        fi
    fi
fi

# -----------------------------------------------------------------------------
# 5. GARANTIR PERMISSÕES (mesmo em dry-run não altera)
# -----------------------------------------------------------------------------
if [ "$DRY_RUN" = false ]; then
    chmod 644 "$MAIN_SOURCES" 2>/dev/null || true
    chmod 644 "$SOURCES_DIR"/*.list "$SOURCES_DIR"/*.sources 2>/dev/null || true
    log_info "✅ Permissões 644 aplicadas."
fi

# -----------------------------------------------------------------------------
# 6. VALIDAÇÃO COM apt-get update
# -----------------------------------------------------------------------------
if [ "$DRY_RUN" = false ]; then
    log_info "🧹 Limpando cache e validando via proxy..."
    rm -rf /var/lib/apt/lists/*

    if apt-get update -qq -o Acquire::http::Timeout=10 \
                       -o Acquire::https::Timeout=10 \
                       -o Acquire::ftp::Timeout=10 2>&1; then
        log_info "✅ Conversão validada com sucesso."
    else
        # Verifica se o erro é hash sum mismatch (cache do proxy)
        if apt-get update 2>&1 | grep -q "Hash Sum incorreto"; then
            log_error "⚠️ Hash Sum incorreto detectado. Limpe o cache do APT-Cacher-NG:"
            log_error "   rm -rf /var/cache/apt-cacher-ng/*"
        else
            log_error "⚠️ Falha ao sincronizar via proxy. Verifique o gateway $CLEAN_PROXY."
        fi
        log_error "   Os backups originais estão em: $BACKUP_DIR"
        # Não abortamos, apenas alertamos, pois pode ser erro temporário
    fi
else
    log_info "🔍 [DRY-RUN] Simulação concluída. Nenhum arquivo foi alterado."
fi

log_info "🏁 Conversão finalizada."
