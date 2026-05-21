#!/bin/bash
# Script acionado automaticamente pelo NetworkManager ao trocar de rede

INTERFACE=$1
ACTION=$2

# Queremos agir apenas quando a rede conectar (up) e ignorar a interface de loopback
if [ "$ACTION" = "up" ] && [ "$INTERFACE" != "lo" ]; then
    
    # Opcional: Aguarda 3 segundos para garantir que as rotas e DNS estabilizaram
    sleep 3
    
    # Executa a verificação de infraestrutura de forma silenciosa no background
    # O aptcacher.sh (com as últimas alterações) já fará a conversão ou o rollback adequadamente.
    /bin/bash /etc/aptcacher.sh > /dev/null 2>&1 &
    
fi
