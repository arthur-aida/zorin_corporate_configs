#!/bin/bash
# ==============================================================================
# Script: instalar_certificados_icp_brasil.sh (OTIMIZADO)
# Nível: Root / Sistema
# ==============================================================================

set -euo pipefail

URL="https://acraiz.icpbrasil.gov.br/credenciadas/CertificadosAC-ICP-Brasil/ACcompactado.zip"
DEST_DIR="/etc/ssl/certs"
ICP_DIR="$DEST_DIR/icp-brasil"
ZIP_FILE="$DEST_DIR/ACcompactado.zip"
VERSION_FILE="$DEST_DIR/icp-version.txt"

# 1. Download inteligente
wget --no-check-certificate -q -N -P "$DEST_DIR" "$URL"

# 2. Verificação de versão (SHA256)
NEW_HASH=$(sha256sum "$ZIP_FILE" | awk '{print $1}')
OLD_HASH=$(cat "$VERSION_FILE" 2>/dev/null || echo "")

if [ "$NEW_HASH" = "$OLD_HASH" ] && [ "$(ls -A "$ICP_DIR" 2>/dev/null)" ]; then
    exit 0
fi

# 3. Extração Global e Atualização do OpenSSL (Nível SO)
rm -rf "$ICP_DIR"/*
unzip -o -q "$ZIP_FILE" -d "$ICP_DIR"
update-ca-certificates >/dev/null 2>&1

# 4. Políticas Corporativas (Abrange .deb e tar.gz)
# Força o Firefox a confiar nas raízes do sistema operativo
for dir in /usr/lib/firefox /usr/lib64/firefox /opt/firefox /usr/lib/firefox-esr; do
    if [ -d "$dir" ]; then
        mkdir -p "$dir/distribution"
        echo '{"policies": {"Certificates": {"ImportEnterpriseRoots": true}}}' > "$dir/distribution/policies.json"
    fi
done

# 5. Autorização de escrita para sinalizar conclusão
echo "$NEW_HASH" > "$VERSION_FILE"
chmod 644 "$VERSION_FILE"
