#!/bin/bash
# acngonoff.sh - Versão Multi-Perfil com prioridade para APTCACHER e CACHEPORT do perfil

set -euo pipefail

# Funções de log locais
log_info()  { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_warning(){ echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

# =============================================================================
# CARREGAMENTO DO PERFIL ATIVO (independente do main.sh)
# =============================================================================
if [ -z "${MAIN_ACTIVE:-}" ] && [ -f /etc/customization/active-profile.env ]; then
    set -a
    . /etc/customization/active-profile.env
    set +a
fi

# 1. Se APTCACHER e CACHEPORT estiverem definidos, tenta usá-los
if [ -n "${APTCACHER:-}" ] && [ -n "${CACHEPORT:-}" ]; then
    PROXY_IP="$APTCACHER"
    PROXY_PORT="$CACHEPORT"
    log_info "Usando proxy definido no perfil: $PROXY_IP:$PROXY_PORT"
else
    # Fallback: gateway padrão
    GW_DETECTED=$(ip route show default 2>/dev/null | awk '{print $3}' || true)
    PROXY_IP="${GW_DETECTED:-192.168.122.1}"
    PROXY_PORT="3142"
    log_info "Usando gateway detectado: $PROXY_IP:$PROXY_PORT"
fi

rm -f /etc/apt/apt.conf.d/00aptproxy 2>/dev/null

ENV_FILE="/tmp/acng_env"
TIMEOUT=5

# 1. Teste de conexão (usando timeout do shell para maior compatibilidade)
if timeout "$TIMEOUT" bash -c "</dev/tcp/$PROXY_IP/$PROXY_PORT" 2>/dev/null; then
    export PROXY_URL="http://${PROXY_IP}:${PROXY_PORT}"

    # 2. Escrita atômica e segura
    if echo "export PROXY_URL=\"$PROXY_URL\"" > "$ENV_FILE"; then
        log_info "Proxy APT-Cacher-NG acessível em $PROXY_URL"
        exit 0
    else
        log_error " Erro ao salvar arquivo de ambiente."
        exit 1
    fi

else
    # 3. Falha e Limpeza
    log_warning " Servidor proxy inacessível."
    [[ -f "$ENV_FILE" ]] && rm -f "$ENV_FILE"
    exit 1
fi
