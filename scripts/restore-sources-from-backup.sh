#!/bin/bash
# =============================================================================
# restore-sources-from-backup.sh
#   - Restaura o backup ORIGINAL (sem proxy)
#   - Preserva repositórios adicionados posteriormente, removendo QUALQUER proxy
#   - Reversão genérica (não depende de variáveis externas)
# =============================================================================
set -uo pipefail

log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }

BACKUP_DIR="/etc/apt/sources.list.d/backup_conversion"
BACKUP_ORIGINAL="${BACKUP_DIR}/sources_backup_ORIGINAL.tar.gz"
MAIN_SOURCES="/etc/apt/sources.list"
SOURCES_DIR="/etc/apt/sources.list.d"

# -----------------------------------------------------------------------------
# 1. Validações iniciais
# -----------------------------------------------------------------------------
if [ ! -f "${BACKUP_DIR}/.backup_original_feito" ]; then
    echo "[ERRO] Backup original não encontrado (arquivo .backup_original_feito ausente)." >&2
    exit 1
fi

if [ ! -s "$BACKUP_ORIGINAL" ]; then
    echo "[ERRO] Arquivo de backup original vazio ou inexistente: $BACKUP_ORIGINAL" >&2
    exit 1
fi

log_info "📦 Usando backup original: $BACKUP_ORIGINAL"

# -----------------------------------------------------------------------------
# 2. Listar arquivos do backup original (apenas nomes)
# -----------------------------------------------------------------------------
ORIGINAL_FILES=$(tar -tzf "$BACKUP_ORIGINAL" 2>/dev/null | grep -E '\.(list|sources)$' | sed 's|.*/||' | sort -u)

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
# 4. Para cada arquivo novo, criar uma cópia limpa (removendo proxy de forma genérica)
#    - Remove QUALQUER padrão http://IP:PORTA/HTTPS///  → https://
#    - Remove QUALQUER padrão http://IP:PORTA/          → http://
# -----------------------------------------------------------------------------
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

for f in "${NEW_FILES[@]}"; do
    src="${SOURCES_DIR}/${f}"
    dst="${TEMP_DIR}/${f}"

    # Reversão genérica (não depende de IP:porta específico)
    sed -e 's|http://[^/]*/HTTPS///|https://|g' \
        -e 's|http://[^/]*/|http://|g' \
        "$src" > "$dst"

    log_info "   ✅ $f revertido (proxy removido)"
    chmod 644 "$dst"
done

# -----------------------------------------------------------------------------
# 5. Limpeza e restauração do backup original
# -----------------------------------------------------------------------------
log_info "🧹 Removendo fontes atuais..."
for f in "$SOURCES_DIR"/*.list "$SOURCES_DIR"/*.sources; do
    [ -f "$f" ] && rm -f "$f"
done

log_info "📦 Extraindo backup original..."
tar -xzf "$BACKUP_ORIGINAL" -C /etc/apt sources.list 2>/dev/null || true
tar -xzf "$BACKUP_ORIGINAL" -C "$SOURCES_DIR" --exclude='sources.list' 2>/dev/null || true
chmod 644 /etc/apt/sources.list "$SOURCES_DIR"/*.list "$SOURCES_DIR"/*.sources 2>/dev/null

# Remove sources.list duplicado se existir dentro de sources.list.d
rm -f "${SOURCES_DIR}/sources.list"

# -----------------------------------------------------------------------------
# 6. Devolver os arquivos novos (já limpos) ao diretório
# -----------------------------------------------------------------------------
if [ ${#NEW_FILES[@]} -gt 0 ]; then
    cp -a "${TEMP_DIR}"/* "$SOURCES_DIR/"
    log_info "✅ ${#NEW_FILES[@]} repositórios adicionais preservados (sem proxy)."
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

log_info "🏁 Restauração concluída. Backup original preservado em $BACKUP_ORIGINAL"
