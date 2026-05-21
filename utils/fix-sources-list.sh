#!/bin/bash
# fix-sources-list.sh - Corrige arquivo sources.list adicionando signed-by
set -euo pipefail

SOURCES_FILE="/etc/apt/sources.list"
BACKUP_FILE="/etc/apt/sources.list.bak.$(date +%Y%m%d_%H%M%S)"

# Verifica se arquivo existe
if [ ! -f "$SOURCES_FILE" ]; then
    echo "ERRO: $SOURCES_FILE não encontrado"
    exit 1
fi

# Cria backup
cp "$SOURCES_FILE" "$BACKUP_FILE" || exit 1
echo "Backup criado: $BACKUP_FILE"

# Processa o arquivo
TEMP=$(mktemp)
while IFS= read -r line; do
    case "$line" in
        deb\ *|deb-src\ *)
            case "$line" in
                *ubuntu.com/ubuntu/*)
                    case "$line" in
                        *"[signed-by=/usr/share/keyrings/ubuntu-archive-keyring.gpg]"*) 
                            echo "$line" 
                            ;;
                        *)
                            pref=$(echo "$line" | awk '{print $1}')
                            rest=$(echo "$line" | sed "s/^$pref //")
                            echo "$pref [signed-by=/usr/share/keyrings/ubuntu-archive-keyring.gpg] $rest"
                            ;;
                    esac
                    ;;
                *) echo "$line" ;;
            esac
            ;;
        *) echo "$line" ;;
    esac
done < "$SOURCES_FILE" > "$TEMP"

# Aplica alterações
mv "$TEMP" "$SOURCES_FILE"
echo "Arquivo $SOURCES_FILE atualizado com sucesso!"
chmod 644 /etc/apt/sources.list
