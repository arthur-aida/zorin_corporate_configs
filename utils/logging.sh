#!/bin/bash
# logging.sh - Funções de log simplificadas (sem criação de arquivos)
# Compatível com o novo main.sh que gerencia os logs por módulo.

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_warning() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

# Funções de início/fim de módulo (apenas para marcadores, sem redirecionamento)
log_module_start() {
    echo "=== Início do módulo $1: $(date) ==="
}

log_module_end() {
    echo "=== Fim do módulo $1: $(date) ==="
}

log_success() {
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}
