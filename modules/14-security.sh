#!/bin/bash
# 14-security.sh - Configurações de segurança.
# script executado durante o deploy no ambiente root
set -euo pipefail
source /etc/customization/utils/logging.sh
log_module_start "14-security"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

check_root

log_info "========================================="
log_info "Iniciando configurações de segurança"
log_info "========================================="

ORIG_DIR="$SCRIPT_DIR/../original_scripts"

# =============================================================================
# SCRIPT DE REATIVAÇÃO DE IMPRESSORAS
# =============================================================================
log_info "Criando script de reativação de impressoras..."

cat > /etc/enableprinter.sh << 'EOF2'
#!/bin/bash
# Script para reativar impressoras desabilitadas
# Executado periodicamente via cron

enable_cmd=$(whereis -b cupsenable | awk '{print $2}')

if [ -z "$enable_cmd" ]; then
    # Se cupsenable não for encontrado, tenta usar o comando direto
    if command -v cupsenable >/dev/null 2>&1; then
        enable_cmd="cupsenable"
    else
        echo "ERRO: cupsenable não encontrado"
        exit 1
    fi
fi

# Obtém lista de impressoras desabilitadas
DISABLED=$(lpstat -t 2>/dev/null | awk '/desabilitada/ {print $2}' || lpstat -t 2>/dev/null | awk '/disabled/ {print $2}')

if [ -n "$DISABLED" ]; then
    echo "Reativando impressoras: $DISABLED"
    for p in $DISABLED; do
        $enable_cmd "$p" 2>/dev/null && echo "Impressora $p reativada" || echo "Falha ao reativar $p"
    done
else
    echo "Nenhuma impressora desabilitada encontrada"
fi
EOF2

chmod +x /etc/enableprinter.sh
log_info "✅ /etc/enableprinter.sh criado"

# =============================================================================
# CONFIGURAÇÃO DO SMARTMONTOOLS
# =============================================================================
log_info "Configurando smartmontools..."

cat > /etc/default/smartmontools << 'EOF2'
# Configuração do smartmontools
# lsblk -d -o NAME | grep nvme
# Habilita monitoramento S.M.A.R.T. para discos
enable_smart="/dev/sda /dev/sdb /dev/nvme0n1"

# Inicia o daemon smartd
start_smartd=yes

# Opções adicionais do smartd
# --interval=7200: verifica a cada 1 dia
smartd_opts="--interval=86400"
EOF2

log_info "✅ /etc/default/smartmontools configurado"

# =============================================================================
# CONFIGURAÇÃO DE HOSTS.ALLOW E HOSTS.DENY (SSH)
# =============================================================================
if [ -f "/etc/om.ips" ]; then
    log_info "Carregando configurações de acesso SSH do /etc/om.ips..."
    
    # Carrega variáveis do arquivo om.ips
    while IFS= read -r line; do
        line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [ -z "$line" ] && continue
        [ "${line#\#}" != "$line" ] && continue
        echo "$line" | grep -q '=' && export "$line"
    done < "/etc/om.ips"
    
    # Remove entradas existentes do sshd
    if [ -f /etc/hosts.allow ]; then
        grep -v "sshd" /etc/hosts.allow > /tmp/hosts.allow.tmp 2>/dev/null || true
        mv /tmp/hosts.allow.tmp /etc/hosts.allow
        log_info "Entradas sshd antigas removidas de /etc/hosts.allow"
    fi
    
    if [ -f /etc/hosts.deny ]; then
        grep -v "sshd" /etc/hosts.deny > /tmp/hosts.deny.tmp 2>/dev/null || true
        mv /tmp/hosts.deny.tmp /etc/hosts.deny
        log_info "Entradas sshd antigas removidas de /etc/hosts.deny"
    fi
    
    # Adiciona novas regras de allow
    for i in 0 1 2 3; do
    v="hostsallow$i"
    val="${!v:-}"
    val_trimmed="$(echo "$val" | xargs)"

    # CORREÇÃO: converte notação abreviada (ex: "sshd: 192.168.123.") para CIDR completo
    if [[ "$val_trimmed" =~ ^sshd:\ [0-9]+\.[0-9]+\.[0-9]+\.$ ]]; then
        val_trimmed="${val_trimmed}0/24"
    fi

    if [ -n "$val_trimmed" ]; then
        if ! grep -Fxq "$val_trimmed" /etc/hosts.allow 2>/dev/null; then
            echo "$val_trimmed" >> /etc/hosts.allow
            log_info "✅ Regra allow adicionada: $val_trimmed"
        else
            log_info "Regra allow já existente: $val_trimmed"
        fi
    fi
    done
    # Adiciona regra de deny
    if [ -n "${hostsdeny:-}" ]; then
        val_trimmed="$(echo "$hostsdeny" | xargs)"
        if [ -n "$val_trimmed" ]; then
            if ! grep -Fxq "$val_trimmed" /etc/hosts.deny 2>/dev/null; then
                echo "$val_trimmed" >> /etc/hosts.deny
                log_info "✅ Regra deny adicionada: $val_trimmed"
            fi
        fi
    fi
    log_info "Configurações de acesso SSH aplicadas"
else
    log_info "⚠️ /etc/om.ips não encontrado - pulando configuração de hosts.allow/deny"
fi

# =============================================================================
# CONFIGURAÇÃO DE TAREFAS CRON (CORRIGIDA)
# =============================================================================
log_info "Configurando tarefas agendadas (cron)..."

# Define as entradas de cron a serem adicionadas
CRON_ENTRIES=(
    "*/5 * * * * root /etc/enableprinter.sh"
    "@reboot root /bin/sleep 600 && bash /etc/aptcacher.sh"
    "20 12 */2 * * root /bin/sleep 3600 && apt update && apt upgrade -y && dpkg --configure -a && apt-get autoremove -y && apt clean && bash /etc/hookjava1.8.sh"
    "40 12 */63 * * root bash  /etc/clean.sh"
)

# Verifica e adiciona cada entrada se não existir
for entry in "${CRON_ENTRIES[@]}"; do
    if ! grep -Fxq "$entry" /etc/crontab 2>/dev/null; then
        echo "$entry" >> /etc/crontab
        log_info "✅ Tarefa cron adicionada: $entry"
    else
        log_info "Tarefa cron já existente: $entry"
    fi
done

# =============================================================================
# VERIFICAÇÃO FINAL DE SERVIÇOS
# =============================================================================
log_info "Verificando serviços de segurança..."

# Verifica se sshd está configurado corretamente e Garante que o SSH esteja habilitado e em execução
if systemctl enable --now ssh 2>/dev/null; then
    log_info "✅ Serviço SSH habilitado e em execução"
else
    log_info "⚠️ Falha ao habilitar/iniciar SSH"
fi

# =============================================================================
# CONCLUSÃO
# =============================================================================
log_info "========================================="
log_info "✅ Configurações de segurança concluídas"
log_info "========================================="
log_module_end "14-security"
