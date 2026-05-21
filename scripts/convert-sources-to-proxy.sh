#!/bin/bash
# =============================================================================
# convert-sources-to-proxy.sh
# =============================================================================
# Suporte total a .list e .sources (DEB822)
# Injeta dinamicamente o IP do proxy detectado via Roaming (acngonoff.sh)
#
# PROPOSTAS INTEGRADAS:
#   - Backup/Restauração com TAR (preserva permissões, evita duplicação)
#   - Cache HTTPS funcional (prefixo HTTPS/// no APT-Cacher-NG)
#   - Permissões 644 garantidas após cada conversão
#   - Filtro de sources.list em sources.list.d (evita duplicação)
#   - Respeita Enabled: no em arquivos .sources
# =============================================================================

set -uo pipefail

# -----------------------------------------------------------------------------
# FUNÇÃO DE LOG (definida antes de qualquer uso)
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }

# =============================================================================
# 1. DETECÇÃO DO PROXY (ROAMING)
# =============================================================================
if [ -f /tmp/acng_env ]; then
    source /tmp/acng_env
    CLEAN_PROXY=$(echo "$PROXY_URL" | sed 's|http://||')
else
    CLEAN_PROXY="192.168.122.1:3142"
fi

# =============================================================================
# 2. CONFIGURAÇÕES E BACKUP
# =============================================================================
SOURCES_DIR="/etc/apt/sources.list.d"
MAIN_SOURCES="/etc/apt/sources.list"
BACKUP_DIR="${SOURCES_DIR}/backup_conversion"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_TAR="${BACKUP_DIR}/sources_backup_ORIGINAL.tar.gz"

mkdir -p "$BACKUP_DIR"

log_info "--- Iniciando Conversão para Mapeamento Direto ($CLEAN_PROXY) ---"

# =============================================================================
# 2.1 BACKUP ORIGINAL COM TAR (SÓ NA PRIMEIRA VEZ)
#     Se o backup original NÃO existe, cria AGORA com fontes limpas
#     Se já existe, NÃO sobrescreve (preserva os domínios reais)
# =============================================================================
if [ ! -f "${BACKUP_DIR}/.backup_original_feito" ]; then
    log_info "🔒 Criando BACKUP ORIGINAL com tar (preserva permissões e estrutura)..."

    # Cria um tar contendo:
    # - /etc/apt/sources.list
    # - Todos os .list e .sources em /etc/apt/sources.list.d/
    # Usa caminhos RELATIVOS a partir de /etc/apt
    tar -czf "$BACKUP_TAR" \
        -C /etc/apt \
        sources.list \
        -C /etc/apt/sources.list.d \
        $(cd "$SOURCES_DIR" 2>/dev/null && ls *.list *.sources 2>/dev/null) \
        2>/dev/null

    # Verifica se o tar foi criado com sucesso
    if [ -f "$BACKUP_TAR" ] && [ -s "$BACKUP_TAR" ]; then
        log_info "   ✅ Backup original criado: $BACKUP_TAR"
        log_info "   📦 Conteúdo do backup:"
        tar -tzf "$BACKUP_TAR" 2>/dev/null | while read -r file; do
            log_info "      - $file"
        done
    else
        log_info "   ❌ ERRO ao criar backup com tar!"
        exit 1
    fi

    # Marca que o backup original foi feito
    touch "${BACKUP_DIR}/.backup_original_feito"
    log_info "🔒 Backup ORIGINAL concluído e protegido contra sobrescrita."

else
    log_info "ℹ️ Backup ORIGINAL já existe. Não será sobrescrito."

    # Cria backup timestamped com tar para auditoria
    BACKUP_AUDIT_TAR="${BACKUP_DIR}/sources_backup_${TIMESTAMP}.tar.gz"
    tar -czf "$BACKUP_AUDIT_TAR" \
        -C /etc/apt \
        sources.list \
        -C /etc/apt/sources.list.d \
        $(cd "$SOURCES_DIR" 2>/dev/null && ls *.list *.sources 2>/dev/null) \
        2>/dev/null
    log_info "📁 Backup timestamped criado para auditoria: $BACKUP_AUDIT_TAR"
fi

# =============================================================================
# 3. CONVERSÃO DE ARQUIVOS .list (TRADICIONAIS)
#    REGRA 1 (ANTES): https://host  → http://PROXY/HTTPS///host  (cache HTTPS!)
#    REGRA 2 (DEPOIS): http://host  → http://PROXY/host
#    A ordem é CRÍTICA: HTTPS primeiro, depois HTTP
# =============================================================================
log_info "Processando arquivos .list..."

# Processa sources.list principal (se existir)
if [ -f "$MAIN_SOURCES" ]; then
    # 1º: Converte HTTPS → HTTP/HTTPS/// (cache HTTPS funcional)
    sed -i "s|https://\([^$CLEAN_PROXY]\)|http://$CLEAN_PROXY/HTTPS///\1|g" "$MAIN_SOURCES" 2>/dev/null || true
    # 2º: Converte HTTP → HTTP/PROXY (cache normal)
    sed -i "s|http://\([^$CLEAN_PROXY]\)|http://$CLEAN_PROXY/\1|g" "$MAIN_SOURCES" 2>/dev/null || true
    chmod 644 "$MAIN_SOURCES" 2>/dev/null || true
    log_info "   ✅ sources.list convertido (HTTP + HTTPS)"
fi

# Processa arquivos .list no sources.list.d
for listfile in "$SOURCES_DIR"/*.list; do
    [ -f "$listfile" ] || continue

    # Pula o sources.list duplicado se existir em sources.list.d (BUG CORRIGIDO)
    if [ "$(basename "$listfile")" = "sources.list" ]; then
        log_info "   ⏭️ sources.list em sources.list.d: ignorado. Pertence a /etc/apt/"
        continue
    fi

    # Pula arquivos que contêm apenas repositórios de cache/proxy local
    if grep -q "$CLEAN_PROXY" "$listfile" 2>/dev/null && \
       ! grep -qv "$CLEAN_PROXY" "$listfile" 2>/dev/null; then
        log_info "   ⏭️ $(basename "$listfile"): já convertido. Pulando."
        continue
    fi

    # APLICA AS DUAS REGRAS NA ORDEM CORRETA
    # 1º HTTPS → HTTP/HTTPS/// (cache HTTPS funcional)
    sed -i "s|https://\([^$CLEAN_PROXY]\)|http://$CLEAN_PROXY/HTTPS///\1|g" "$listfile"
    # 2º HTTP → HTTP/PROXY (cache normal)
    sed -i "s|http://\([^$CLEAN_PROXY]\)|http://$CLEAN_PROXY/\1|g" "$listfile"

    chmod 644 "$listfile" 2>/dev/null || true
    log_info "   ✅ $(basename "$listfile"): convertido"
done

# =============================================================================
# 4. CONVERSÃO DE ARQUIVOS .sources (DEB822)
#    Mesma lógica: HTTPS primeiro (HTTPS///), depois HTTP
#    Respeita Enabled: no (não converte repositórios desabilitados)
# =============================================================================
log_info "Processando arquivos .sources (DEB822)..."

for srcfile in "$SOURCES_DIR"/*.sources; do
    [ -f "$srcfile" ] || continue
    basename=$(basename "$srcfile")

    # Pula arquivos que estão DESABILITADOS (Enabled: no)
    if grep -q "^Enabled: no" "$srcfile" 2>/dev/null; then
        log_info "   ⏭️ $basename: repositório DESABILITADO (Enabled: no). Pulando."
        continue
    fi

    # Verifica se o arquivo já foi convertido (contém o IP do proxy)
    if grep "^URIs:" "$srcfile" | grep -q "$CLEAN_PROXY" 2>/dev/null; then
        log_info "   ⏭️ $basename: já convertido. Pulando."
        continue
    fi

    # APLICA AS DUAS REGRAS NA ORDEM CORRETA
    # 1º: Converte URIs HTTPS → HTTP/HTTPS///
    sed -i "s|^URIs: https://\(.*\)|URIs: http://$CLEAN_PROXY/HTTPS///\1|g" "$srcfile"
    # 2º: Converte URIs HTTP → HTTP/PROXY (que não sejam já do proxy)
    sed -i "s|^URIs: http://\([^$CLEAN_PROXY]\)|URIs: http://$CLEAN_PROXY/\1|g" "$srcfile"

    chmod 644 "$srcfile" 2>/dev/null || true
    log_info "   ✅ $basename: convertido"
done

# =============================================================================
# 5. GARANTIR PERMISSÕES CORRETAS (644) EM TODAS AS FONTES
# =============================================================================
log_info "Garantindo permissões corretas (644) em todas as fontes..."
chmod 644 "$MAIN_SOURCES" 2>/dev/null || true
chmod 644 "$SOURCES_DIR"/*.list "$SOURCES_DIR"/*.sources 2>/dev/null || true
log_info "   ✅ Permissões verificadas e corrigidas"

# =============================================================================
# 6. VALIDAÇÃO
# =============================================================================
log_info "Limpando metadados antigos e validando via proxy..."
rm -rf /var/lib/apt/lists/*

if apt-get update -qq -o Acquire::http::Timeout=10 \
                  -o Acquire::https::Timeout=10 \
                  -o Acquire::ftp::Timeout=10 2>&1; then
    log_info "   ✅ Conversão concluída com sucesso em todos os formatos."
else
    # Verifica se o erro é apenas nos PPAs desabilitados (já esperado)
    if apt-get update 2>&1 | grep -q "Hash Sum incorreto"; then
        echo "[ERRO] Hash Sum incorreto detectado. Limpe o cache do APT-Cacher-NG."
        echo "[ERRO] Execute no servidor: rm -rf /var/cache/apt-cacher-ng/*"
    else
        echo "[ERRO] Falha ao sincronizar via proxy. Verifique o gateway $CLEAN_PROXY."
    fi
    echo "[ERRO] Os backups originais estão em: $BACKUP_DIR"
    exit 1
fi
