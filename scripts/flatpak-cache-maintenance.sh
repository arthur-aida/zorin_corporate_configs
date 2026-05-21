#!/bin/bash
# flatpak-cache-maintenance.sh - Limpa versões antigas do repositório Flatpak no NFS
# Executa 1 vez ao dia (chamado por 11-flatpak-cache.sh)

REPO_PATH="/mnt/.ostree/repo"          # ← repositório montado via NFS
LOG_FILE="/var/log/flatpak-cache-maintenance.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

if [ ! -d "$REPO_PATH" ]; then
    log "ERRO: Repositório $REPO_PATH não encontrado. Abortando."
    exit 1
fi

log "Iniciando manutenção do cache Flatpak em $REPO_PATH"

# Opção 1: manter apenas a versão mais recente de cada aplicativo (--depth=1)
# Isso remove versões antigas que não sejam referenciadas por nenhum branch.
if command -v flatpak >/dev/null 2>&1; then
    flatpak repo prune --repo="$REPO_PATH" --depth=4 --force >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        log "✅ Prune executado: versões antigas removidas (depth=1)"
    else
        log "⚠️ Falha no prune com flatpak. Tentando ostree..."
    fi
else
    log "ℹ️ flatpak não encontrado, usando ostree prune..."
    ostree prune --repo="$REPO_PATH" --depth=1 --refs-only >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        log "✅ ostree prune concluído"
    else
        log "❌ Falha no ostree prune"
    fi
fi

# Verificação de integridade do repositório (leve)
ostree fsck --repo="$REPO_PATH" --quiet 2>/dev/null

log "Manutenção concluída."
