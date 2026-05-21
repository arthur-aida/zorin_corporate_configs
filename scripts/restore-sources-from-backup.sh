#!/bin/bash
# =============================================================================
# restore-sources-from-backup.sh
#   - Restaura backup original
#   - Preserva repositórios adicionados posteriormente, removendo o proxy
#   - CORRIGIDO: só exibe "Proxy detectado" se PROXY_HOST_PORT foi exportado
# =============================================================================
set -uo pipefail

log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }

BACKUP_DIR="/etc/apt/sources.list.d/backup_conversion"
BACKUP_TAR="${BACKUP_DIR}/sources_backup_ORIGINAL.tar.gz"
MAIN_SOURCES="/etc/apt/sources.list"
SOURCES_DIR="/etc/apt/sources.list.d"

# Somente define PROXY_HOST_PORT se ele já tiver sido exportado (ex.: pelo main.sh)
# Nenhum fallback automático, para não induzir a existência de proxy inexistente.
if [ -n "${PROXY_HOST_PORT:-}" ]; then
    HAS_PROXY=true
    log_info "🔍 Removendo referências de proxy: $PROXY_HOST_PORT"
else
    HAS_PROXY=false
    log_info "ℹ️ Nenhum proxy configurado. Mantendo URLs originais."
fi

# -----------------------------------------------------------------------------
# 1. Validações iniciais
# -----------------------------------------------------------------------------
[ -f "${BACKUP_DIR}/.backup_original_feito" ] || { echo "[ERRO] Backup original não encontrado."; exit 1; }
[ -s "$BACKUP_TAR" ] || { echo "[ERRO] Arquivo tar de backup vazio."; exit 1; }

# -----------------------------------------------------------------------------
# 2. Listar arquivos do backup original (apenas nomes)
# -----------------------------------------------------------------------------
ORIGINAL_FILES=$(tar -tzf "$BACKUP_TAR" 2>/dev/null | grep -E '\.(list|sources)$' | sed 's|.*/||' | sort -u)

# -----------------------------------------------------------------------------
# 3. Identificar arquivos NOVOS (presentes agora, mas não no backup original)
# -----------------------------------------------------------------------------
CURRENT_FILES=$(cd "$SOURCES_DIR" && ls *.list *.sources 2>/dev/null)
NEW_FILES=()
for f in $CURRENT_FILES; do
    if ! echo "$ORIGINAL_FILES" | grep -qw "$f"; then
        NEW_FILES+=("$f")
    fi
done

log_info "📂 Arquivos adicionados após backup original: ${NEW_FILES[*]:-nenhum}"

# -----------------------------------------------------------------------------
# 4. Para cada arquivo novo, criar uma cópia limpa (removendo proxy, se houver)
# -----------------------------------------------------------------------------
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

for f in "${NEW_FILES[@]}"; do
    src="${SOURCES_DIR}/${f}"
    dst="${TEMP_DIR}/${f}"

    if [ "$HAS_PROXY" = true ]; then
        # Reversão em dois passos (exatamente o inverso da conversão):
        # a) http://PROXY/HTTPS///  → https://
        # b) http://PROXY/          → http://
        sed -e "s|http://${PROXY_HOST_PORT}/HTTPS///|https://|g" \
            -e "s|http://${PROXY_HOST_PORT}/|http://|g" \
            "$src" > "$dst"
        log_info "   ✅ $f revertido para URLs reais"
    else
        # Sem proxy: apenas copia o arquivo sem modificações
        cp "$src" "$dst"
        log_info "   ✅ $f preservado sem alterações (sem proxy)"
    fi

    # Garante permissões
    chmod 644 "$dst"
done

# -----------------------------------------------------------------------------
# 5. Limpeza e restauração do backup original (como antes)
# -----------------------------------------------------------------------------
log_info "🧹 Removendo fontes atuais..."
for f in "$SOURCES_DIR"/*.list "$SOURCES_DIR"/*.sources; do
    [ -f "$f" ] && rm -f "$f"
done

log_info "📦 Extraindo backup original..."
tar -xzf "$BACKUP_TAR" -C /etc/apt sources.list 2>/dev/null || true
tar -xzf "$BACKUP_TAR" -C "$SOURCES_DIR" --exclude='sources.list' 2>/dev/null || true
chmod 644 /etc/apt/sources.list "$SOURCES_DIR"/*.list "$SOURCES_DIR"/*.sources 2>/dev/null

# Remove sources.list duplicado se existir dentro de sources.list.d
rm -f "${SOURCES_DIR}/sources.list"

# -----------------------------------------------------------------------------
# 6. Devolver os arquivos novos (já limpos) ao diretório
# -----------------------------------------------------------------------------
if [ ${#NEW_FILES[@]} -gt 0 ]; then
    cp -a "${TEMP_DIR}"/* "$SOURCES_DIR/"
    log_info "✅ ${#NEW_FILES[@]} repositórios adicionais preservados."
fi

# -----------------------------------------------------------------------------
# 7. Validação final (apt-get update)
# -----------------------------------------------------------------------------
log_info "Limpando cache e validando..."
rm -rf /var/lib/apt/lists/*
if apt-get update -qq 2>&1; then
    log_info "✅ Todas as fontes funcionando corretamente."
else
    log_info "⚠️ apt-get update reportou erros – verifique conectividade externa."
fi

log_info "🏁 Restauração concluída. Backup original preservado em $BACKUP_TAR"
