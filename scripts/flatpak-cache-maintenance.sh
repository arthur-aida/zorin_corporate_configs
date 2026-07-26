#!/bin/bash
# flatpak-cache-maintenance.sh - Limpa versões antigas do repositório Flatpak no NFS
# Executa 1 vez ao dia (chamado por 11-flatpak-cache.sh OU via cron/shell)
# 
# USO:
#   flatpak-cache-maintenance.sh              # Execução normal
#   flatpak-cache-maintenance.sh --from-dispatcher  # Chamado pelo dispatcher
#   flatpak-cache-maintenance.sh --force      # Força execução mesmo se já feita hoje

source /etc/customization/utils/common.sh

# =============================================================================
# CONFIGURAÇÕES
# =============================================================================
UPDATE_FLAG=false
FORCE_EXECUTION=false

# =============================================================================
# PROCESSAMENTO DE ARGUMENTOS
# =============================================================================
while [[ $# -gt 0 ]]; do
    case $1 in
        --from-dispatcher) UPDATE_FLAG=true; shift ;;
        --force) FORCE_EXECUTION=true; shift ;;
        *) shift ;;
    esac
done

# =============================================================================
# FUNÇÃO DE LOG (usa a centralizada do common.sh)
# =============================================================================
maint_log() {
    flatpak_maint_log "$@"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    local exit_code=0

    # 1. Garante NFS montado
    if ! flatpak_maint_ensure_nfs; then
        maint_log "❌ NFS não disponível. Abortando."
        exit 1
    fi

    # 2. Verifica repositório
    if [ ! -d "$FLATPAK_MAINT_REPO_PATH" ]; then
        maint_log "❌ Repositório não encontrado: $FLATPAK_MAINT_REPO_PATH"
        exit 1
    fi

    # 3. Verifica flag diária (a menos que --force ou --from-dispatcher)
    if [ "$FORCE_EXECUTION" = false ] && [ "$UPDATE_FLAG" = false ]; then
        if ! flatpak_maint_is_due "$FLATPAK_MAINT_FLAG_FILE"; then
            maint_log "📅 Manutenção já executada hoje. Use --force para forçar."
            exit 0
        fi
    fi

    # 4. Adquire lock (ÚNICO PONTO DE LOCK)
    if ! flatpak_maint_acquire_lock "$FLATPAK_MAINT_LOCK_DIR"; then
        maint_log "❌ Não foi possível adquirir lock. Abortando."
        exit 1
    fi

    # 5. EXECUTA OSTREE PRUNE E FSCK (PONTO ÚNICO DE EXECUÇÃO)
    flatpak_maint_do_ostree "$FLATPAK_MAINT_REPO_PATH" || exit_code=$?

    # 6. Atualiza flag se bem-sucedido ou se --from-dispatcher
    if [ $exit_code -eq 0 ] || [ "$UPDATE_FLAG" = true ]; then
        flatpak_maint_update_flag "$FLATPAK_MAINT_FLAG_FILE"
    else
        maint_log "⚠️ Marcador NÃO atualizado devido a erros (código $exit_code)"
    fi

    # 7. Libera lock
    flatpak_maint_release_lock "$FLATPAK_MAINT_LOCK_DIR"

    exit $exit_code
}

# Executa apenas se não estiver sendo sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
