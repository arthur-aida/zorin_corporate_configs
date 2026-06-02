#!/bin/bash
#-------------------------------------------------------------------------------------------------------------------------------
#   Este script instala/atualiza o assinador do serpro (Versão 4.4.0 - AppImage).
#   Nova lógica oficial: https://www.serpro.gov.br/links-fixos-superiores/assinador-digital/assinador-serpro
#-------------------------------------------------------------------------------------------------------------------------------

LOCKFILE="/tmp/$(basename "$0").lock"
if [ -f "$LOCKFILE" ]; then
    exit 0
fi
touch "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

REAL_USER="${SUDO_USER:-$USER}"

# Verifica se pertence ao grupo sudo ou admin
if ! groups "$REAL_USER" | grep -qE '\b(sudo|admin)\b'; then
    if [ -n "${SUDO_USER:-}" ] && command -v zenity >/dev/null 2>&1; then
        sudo -u "$REAL_USER" zenity --warning --width=450 --text="Solicite ao Administrador instalar o Assinador SERPRO.\nE criar um novo usuário para utilizá-lo." --timeout=15 2>/dev/null &
    fi
    exit 1
fi

INSTALLER_URL="https://artefatos-assinador.serpro.gov.br/downloads/appimage/instalar-dependencias"
TMP_FILE=$(mktemp /tmp/serpro-installer.XXXXXX)
ASSINADOR_VERSAO="4.4.0"

# Exibe aviso de início (como o usuário real, se disponível)
if [ -n "${SUDO_USER:-}" ] && command -v zenity >/dev/null 2>&1; then
    sudo -u "$REAL_USER" zenity --info --width=450 --text="Baixando e instalando o Assinador SERPRO $ASSINADOR_VERSAO. Aguarde..." --timeout=10 2>/dev/null &
fi

echo "Baixando instalador do SERPRO de $INSTALLER_URL..."

# Download com verificação de sucesso
if curl -fsSL --connect-timeout 15 --max-time 60 -o "$TMP_FILE" "$INSTALLER_URL"; then
    # Verifica se o arquivo não está vazio
    if [ -s "$TMP_FILE" ]; then
        echo "Download concluído. Executando instalador..."
        chmod +x "$TMP_FILE"
        if "$TMP_FILE" -versao "$ASSINADOR_VERSAO"; then
            echo "Assinador SERPRO $ASSINADOR_VERSAO instalado com sucesso."
            if [ -n "${SUDO_USER:-}" ] && command -v zenity >/dev/null 2>&1; then
                sudo -u "$REAL_USER" zenity --info --width=450 --text="Assinador SERPRO $ASSINADOR_VERSAO instalado com sucesso.\nPara usá-lo, digite 'Assinador Serpro' no menu de aplicativos." --timeout=20 2>/dev/null &
            fi
            # Remove o atalho antigo, se existir, para evitar confusão
            rm -f /usr/share/applications/InstaladorAssinadorSepro.desktop 2>/dev/null
        else
            echo "Erro na execução do instalador." >&2
            if [ -n "${SUDO_USER:-}" ] && command -v zenity >/dev/null 2>&1; then
                sudo -u "$REAL_USER" zenity --error --width=450 --text="Falha ao executar o instalador do SERPRO.\nVerifique os logs do sistema." --timeout=15 2>/dev/null &
            fi
        fi
    else
        echo "Erro: arquivo baixado está vazio." >&2
        if [ -n "${SUDO_USER:-}" ] && command -v zenity >/dev/null 2>&1; then
            sudo -u "$REAL_USER" zenity --error --width=450 --text="O instalador do SERPRO não pôde ser baixado (arquivo vazio). Tente novamente mais tarde." --timeout=15 2>/dev/null &
        fi
    fi
else
    echo "Erro ao baixar o instalador. Verifique sua conexão ou se o link ainda é válido." >&2
    if [ -n "${SUDO_USER:-}" ] && command -v zenity >/dev/null 2>&1; then
        sudo -u "$REAL_USER" zenity --error --width=450 --text="Falha ao baixar o instalador do SERPRO.\nVerifique sua conexão ou se o link do site oficial foi atualizado." --timeout=15 2>/dev/null &
    fi
fi

rm -f "$TMP_FILE"
exit 0
