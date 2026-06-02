#!/bin/bash
# CARREGAdriverTOKEN.sh - Registra módulos PKCS#11 e configura cron
# CORRIGIDO: zenity só é chamado se DISPLAY estiver ativo

LOCKFILE="/tmp/$(basename "$0").lock"
if [ -f "$LOCKFILE" ]; then
    exit 0
fi
touch "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

# Registra os módulos se pkcs11-register existir
if [ -f /usr/bin/pkcs11-register ]; then
    # Lista de possíveis módulos
    MODULES=(
        "/usr/lib/x86_64-linux-gnu/opensc-pkcs11.so"
        "/usr/lib/libaetpkss.so.3"
        "/usr/lib/libaetpkss.so"
        "/usr/lib/libeToken.so"
        "/usr/lib/libOcsCryptoki.so"
        "/usr/local/AWP/lib/libOcsCryptoki.so"
        "/usr/lib/libcmP11.so"
        "/usr/lib/libbirdid.so"
        "/usr/lib/libeTPkcs11.so"
        "/usr/lib/libIDPrimePKCS11.so"
        "/usr/lib/libDXSafePKCS11.x64.so"
    )
    for module in "${MODULES[@]}"; do
        if [ -f "$module" ]; then
            /usr/bin/pkcs11-register --module="$module" 2>/dev/null
        fi
    done
else
    # Só exibe zenity se houver ambiente gráfico
    if [ -n "${DISPLAY:-}" ] && command -v zenity >/dev/null; then
        zenity --warning --text="Instale o pacote OPENSC para carregar os DRIVERS dos TOKENS! Informe o administrador." --width=450 --height=100
    else
        echo "AVISO: pkcs11-register não encontrado. Drivers de token não serão registrados."
    fi
    exit 1
fi

# Adiciona tarefa de limpeza no crontab do usuário, se não existir
crontab -l 2>/dev/null > /tmp/TstCRON
if ! grep -q "/etc/clean.sh" /tmp/TstCRON; then
    (crontab -l 2>/dev/null; echo "20 13 20 */2 * /etc/clean.sh") | crontab -
fi
rm -f /tmp/TstCRON
exit 0
