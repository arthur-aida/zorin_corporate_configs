#!/bin/bash
# 13-desktop-config-user.sh
# Script para configurar certificados ICP no espaço do usuário
# Tenta carregar o sistema de log padronizado (fornecido pelo main.sh)
set -euo pipefail
if [ -f /etc/customization/utils/logging.sh ]; then
    source /etc/customization/utils/logging.sh
fi

# Fallback para funções de log (caso logging.sh não esteja disponível)
if ! command -v log_info >/dev/null 2>&1; then
    log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
    log_warning() { echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }
    log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }
    log_module_start() { log_info "Iniciando módulo: $1"; }
    log_module_end() { log_info "Finalizado módulo: $1"; }
fi

log_module_start "13-desktop-config-user"

# =============================================================================
# CRIAÇÃO DO SCRIPT DE ATUALIZAÇÃO (PAARA USO NO ESPAÇO DO USUÁRIO FINAL)
# =============================================================================
log_info "Gerando script de importação com checagem nativa de hash..."

cat > /usr/local/bin/setup-icp-tokens.sh << 'EOF_ICP'
#!/bin/bash
# setup-icp-tokens.sh – download robusto com fallback para SSL
set -euo pipefail
shopt -s nullglob

# ====== CONSTANTES ======
USER_VERSION_DIR="/tmp/icp-brasil"
ZIP_NAME="ACcompactado.zip"
HASH_NAME="hashsha512.txt"
LOG_FILE="$HOME/.local/share/icp-certs/import.log"
P11_KIT_DIR="$HOME/.p11-kit/trust"
LOCK_FILE="/tmp/setup-icp-tokens.lock"

# Binários
CURL=$(command -v curl || true)
UNZIP=$(command -v unzip || true)
TRUST=$(command -v trust || true)
CERTUTIL=$(command -v certutil || true)
PKILL=$(command -v pkill || true)
ZENITY=$(command -v zenity || true)

# ====== FUNÇÕES ======
mkdir -p "$(dirname "$LOG_FILE")" "$USER_VERSION_DIR" "$P11_KIT_DIR"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
error_exit() {
    log "ERRO: $*"
    exit 1
}

cleanup() {
    rm -f "$LOCK_FILE"
    [ -n "${ZENITY_PID:-}" ] && kill "$ZENITY_PID" 2>/dev/null || true
    [ -n "${FF_PID:-}" ] && kill "$FF_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# ====== PREVENÇÃO DE EXECUÇÃO SIMULTÂNEA ======
if [ -f "$LOCK_FILE" ]; then
    log "Script já está em execução. Encerrando."
    exit 0
fi
echo $$ > "$LOCK_FILE"

# Modo live
if grep -q "casper" /proc/cmdline 2>/dev/null; then
    exit 0
fi

# Dependências mínimas
if [ -z "$CURL" ] || [ -z "$UNZIP" ]; then
    error_exit "curl e unzip são obrigatórios. Instale-os."
fi

# Barra de progresso
if [ -n "$ZENITY" ]; then
    "$ZENITY" --pulsate --no-cancel --progress --width=450 --height=100 \
        --title="Processando certificados" \
        --text="Aguarde a conclusão automática..." 2>/dev/null &
    ZENITY_PID=$!
fi

# Opcional: abrir Firefox headless para gerar perfil NSS
FIREFOX=$(command -v firefox-esr || command -v firefox || true)
if [ -n "$FIREFOX" ]; then
    "$FIREFOX" --headless >/dev/null 2>&1 &
    FF_PID=$!
fi

# ====== DOWNLOAD COM FALLBACK DE SSL ======
log "Iniciando download dos certificados..."

# Tenta primeiro com a verificação SSL padrão do sistema (mais confiável)
if curl -sS --connect-timeout 15 --max-time 60 -L \
    -o "$USER_VERSION_DIR/$HASH_NAME" \
    "https://acraiz.icpbrasil.gov.br/credenciadas/CertificadosAC-ICP-Brasil/hashsha512.txt" >> "$LOG_FILE" 2>&1; then
    log "Download de $HASH_NAME OK (SSL verificado)."
else
    log "Falha na verificação SSL ou rede. Tentando com --insecure (a integridade será conferida pelo hash)."
    if [ -n "$ZENITY" ]; then
        "$ZENITY" --warning --text="A verificação SSL falhou. O download prosseguirá sem validação de certificado.\nA integridade do arquivo será verificada via hash." --timeout=10
    fi
    if ! curl -sS --insecure --connect-timeout 15 --max-time 60 -L \
        -o "$USER_VERSION_DIR/$HASH_NAME" \
        "https://acraiz.icpbrasil.gov.br/credenciadas/CertificadosAC-ICP-Brasil/hashsha512.txt" >> "$LOG_FILE" 2>&1; then
        error_exit "Falha ao baixar $HASH_NAME mesmo após fallback."
    fi
fi

# Baixa o ZIP (mesma lógica)
if curl -sS --connect-timeout 15 --max-time 120 -L \
    -o "$USER_VERSION_DIR/$ZIP_NAME" \
    "https://acraiz.icpbrasil.gov.br/credenciadas/CertificadosAC-ICP-Brasil/ACcompactado.zip" >> "$LOG_FILE" 2>&1; then
    log "Download de $ZIP_NAME OK (SSL verificado)."
else
    log "Falha SSL no ZIP. Tentando com --insecure."
    if ! curl -sS --insecure --connect-timeout 15 --max-time 120 -L \
        -o "$USER_VERSION_DIR/$ZIP_NAME" \
        "https://acraiz.icpbrasil.gov.br/credenciadas/CertificadosAC-ICP-Brasil/ACcompactado.zip" >> "$LOG_FILE" 2>&1; then
        error_exit "Falha ao baixar $ZIP_NAME após fallback."
    fi
fi

# ====== VERIFICAÇÃO DE HASH ======
log "Validando sha512 do arquivo baixado..."
if [ ! -s "$USER_VERSION_DIR/$HASH_NAME" ]; then
    error_exit "Arquivo de hashes vazio ou não baixado."
fi

ACTUAL_HASH=$(sha512sum "$USER_VERSION_DIR/$ZIP_NAME" | awk '{print $1}')
EXPECTED_HASH=$(grep -F "$ZIP_NAME" "$USER_VERSION_DIR/$HASH_NAME" | awk '{print $1}')

if [ -z "$EXPECTED_HASH" ]; then
    error_exit "Hash para $ZIP_NAME não encontrada na lista."
fi

if [ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]; then
    log "Hash esperado:   $EXPECTED_HASH"
    log "Hash calculado:  $ACTUAL_HASH"
    error_exit "Verificação de integridade FALHOU! Arquivo corrompido."
fi
log "✅ Integridade confirmada."

# ====== EXTRAÇÃO ======
log "Extraindo certificados..."
"$UNZIP" -o -q "$USER_VERSION_DIR/$ZIP_NAME" -d "$USER_VERSION_DIR"

# ====== ENCERRAMENTO DE NAVEGADORES ======
log "Encerrando navegadores..."
if [ -n "$PKILL" ]; then
    "$PKILL" -f firefox || true
    "$PKILL" -f chrome  || true
    "$PKILL" -f brave   || true
    "$PKILL" -f edge    || true
fi
sleep 1

# ====== SINCRONIZAÇÃO P11-KIT ======
if [ -n "$TRUST" ]; then
    log "Importando certificados via trust..."
    cp "$USER_VERSION_DIR"/*.crt "$P11_KIT_DIR/" 2>/dev/null || true
    for cert in "$USER_VERSION_DIR"/*.crt; do
        "$TRUST" anchor --store "$cert" >/dev/null 2>&1 || true
    done
    log "p11-kit atualizado."
else
    log "trust não encontrado, etapa ignorada."
fi

# ====== INJEÇÃO NOS BANCOS NSS ======
if [ -n "$CERTUTIL" ]; then
    log "Injetando certificados nos perfis NSS..."
    SEARCH_PATHS=("$HOME/.mozilla" "$HOME/.pki" "$HOME/.var" "$HOME/.local/share/pki/")
    while IFS= read -r db_path; do
        db_dir=$(dirname "$db_path")
        log "  Processando: $db_path"
        for cert_file in "$USER_VERSION_DIR"/*.crt; do
            cert_name=$(basename "$cert_file" .crt)
            if "$CERTUTIL" -A -n "ICP-$cert_name" -t "TCu,Cu,Tu" \
                -i "$cert_file" -d "sql:$db_dir" >> "$LOG_FILE" 2>&1; then
                log "    OK: $cert_name"
            else
                log "    FALHA ao adicionar $cert_name em $db_dir"
            fi
        done
    done < <(find "${SEARCH_PATHS[@]}" -name "cert9.db" 2>/dev/null)
else
    log "certutil não encontrado."
fi

# ====== DRIVER DE TOKEN ======
if [ -x /bin/carregadrivertoken ]; then
    /bin/carregadrivertoken || true
    log "Drivers de token carregados."
fi

# ====== FLATPAK ======
if command -v flatpak >/dev/null 2>&1; then
    if flatpak info com.google.Chrome 2>/dev/null | grep -q "Installed: true"; then
        flatpak override com.google.Chrome --user --filesystem=~/.pki:create 2>/dev/null || true
        log "Permissão flatpak para Chrome ajustada."
    fi
fi

# ====== FINALIZAÇÃO ======
log "Processo concluído com sucesso."
echo "Certificados ICP-Brasil atualizados no seu perfil."
sleep 2

EOF_ICP

chmod +x /usr/local/bin/setup-icp-tokens.sh

# =============================================================================
# ATALHO .DESKTOP | Exec=/usr/local/bin/setup-icp-tokens.sh
# =============================================================================
log_info "Atualizando atalho de menu..."

cat > /usr/share/applications/Carrega.Drivers.Tokens.desktop << 'EOF2'
[Desktop Entry]
Name=Habilita Certificados GOV e Tokens
Comment=Importa Certificados ITI/Brasil e carrega drivers de tokens
Exec=xterm -e '/bin/bash -c "/usr/local/bin/setup-icp-tokens.sh 2>&1 | tee $HOME/.local/share/icp-certs/import.log"'
Type=Application
Categories=System;
Icon=security-high
Terminal=false
Keywords=Tokens;Token;Certificados;ITI;gov;br;AC;Brasil;Serpro;Compras;Siafi;Licitação;
EOF2

chmod 644 /usr/share/applications/*.desktop
chmod +x /usr/share/applications/*.desktop

flatpak override com.google.Chrome --filesystem=$HOME

log_module_end "13-desktop-config-user"
