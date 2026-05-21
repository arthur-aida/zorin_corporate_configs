#!/bin/bash
# kaspersky-boot-install.sh - Aguarda DNS do perfil saúde e instala Kaspersky uma única vez
# Executado pelo systemd service em todo boot

set -euo pipefail

LOG_FILE="/var/log/kaspersky-boot-install.log"
FLAG_INSTALLED="/var/lib/kaspersky-installed"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Já instalado?
if [ -f "$FLAG_INSTALLED" ]; then
    log "Kaspersky já foi instalado anteriormente. Nada a fazer."
    exit 0
fi

# Carrega configurações do perfil (contém DNS)
if [ -f /etc/om.ips ]; then
    . /etc/om.ips
else
    log "ERRO: /etc/om.ips não encontrado. Impossível determinar DNS."
    exit 1
fi

DNS_SERVER="${DNS:-}"
if [ -z "$DNS_SERVER" ]; then
    log "ERRO: Variável DNS não definida em /etc/om.ips."
    exit 1
fi

# Testa conectividade DNS usando o servidor especificado
log "Aguardando conectividade com DNS $DNS_SERVER..."

dns_ok=false
for i in $(seq 1 30); do
    if command -v dig >/dev/null 2>&1; then
        if dig @"$DNS_SERVER" google.com +short | grep -qE '^[0-9.]+$'; then
            dns_ok=true
            break
        fi
    elif command -v nslookup >/dev/null 2>&1; then
        if nslookup google.com "$DNS_SERVER" >/dev/null 2>&1; then
            dns_ok=true
            break
        fi
    else
        # Fallback: ping no servidor DNS
        if ping -c 1 -W 2 "$DNS_SERVER" >/dev/null 2>&1; then
            dns_ok=true
            break
        fi
    fi
    log "Tentativa $i: DNS $DNS_SERVER não responde. Aguardando 10s..."
    sleep 10
done

if [ "$dns_ok" = false ]; then
    log "Falha ao conectar ao DNS $DNS_SERVER após 30 tentativas. Instalação adiada para próximo boot."
    exit 1  # systemd irá reiniciar no próximo boot (ou com RestartSec)
fi

log "DNS $DNS_SERVER acessível. Prosseguindo com instalação do Kaspersky."

# Verifica se o tarball existe
if [ ! -f /etc/KSE-12.3.tar ]; then
    log "ERRO: /etc/KSE-12.3.tar não encontrado. Instalação impossível."
    exit 1
fi

# Executa o instalador
if [ -x /etc/instalaKSE.sh ]; then
    log "Executando /etc/instalaKSE.sh..."
    if bash /etc/instalaKSE.sh; then
        log "Instalação concluída com sucesso."
        touch "$FLAG_INSTALLED"
        rm -f /etc/KSE-12.3.tar  # remove tarball após sucesso
        # Desabilita o serviço para não rodar novamente
        systemctl disable kaspersky-installer.service
        exit 0
    else
        log "Falha na execução do instalador."
        exit 1
    fi
else
    log "ERRO: /etc/instalaKSE.sh não encontrado ou não executável."
    exit 1
fi
