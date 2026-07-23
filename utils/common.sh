#!/bin/bash
# common.sh - Funções comuns para todos os scripts de customização
# 
# REDES KVM:
#   - 192.168.122.0/24 (rede padrão libvirt)
#   - 192.168.123.0/24 (rede secundária)
#   O servidor NFS está sempre no IP .1 da rede ativa
#   PORTA PADRÃO NFS: 2049
#
# DEPENDÊNCIA: O arquivo /etc/customization/utils/logging.sh DEVE conter as funções:
#   log_info, log_warning, log_error, log_module_start, log_module_end

source /etc/customization/utils/logging.sh

export LOG_FILE="/var/log/customization.log"
export NFS_PORT="2049"
export APT_CACHER_PORT="3144"

# =============================================================================
# FUNÇÕES DE UTILITÁRIO
# =============================================================================

check_root() { 
    if [ "$EUID" -ne 0 ]; then 
        log_info "ERRO: root necessario"
        exit 1
    fi 
}

# ----------------------------------------------------------------------
# Proteção contra locks do packagekitd (e outros processos APT)
# ----------------------------------------------------------------------
wait_for_apt_unlock() {
    local max_wait=60
    local attempt=0
    local lock_file="/var/lib/apt/lists/lock"

    # Aguarda a liberação do lock do APT
    while fuser "$lock_file" >/dev/null 2>&1; do
        attempt=$((attempt + 1))
        if [ $attempt -ge $max_wait ]; then
            log_warning "Timeout aguardando liberação do lock APT. Forçando remoção e prosseguindo."
            rm -f "$lock_file" 2>/dev/null || true
            break
        fi
        log_info "Aguardando liberação do lock APT (tentativa $attempt)..."
        sleep 2
    done
}

show_warning() {
    local msg="$1"
    if command -v zenity >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ] && [ -e /tmp/.X11-unix/X0 ]; then
        zenity --warning --text="$msg" --width=450 --height=100 2>/dev/null
    else
        echo "========================================" >&2
        echo "ATENCAO: $msg" >&2
        echo "========================================" >&2
        read -p "Pressione Enter..." </dev/tty
    fi
}

show_notify() {
    local title="$1" msg="$2"
    if command -v notify-send >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
        notify-send --urgency=normal --icon=wine --expire-time=15000 "$title" "$msg" 2>/dev/null
    else
        echo "[NOTIFY] $title: $msg"
    fi
}

load_profile() {
    local num="$1"
    case "$num" in
        1) 
            if [ -f /etc/customization/profiles/domestic.conf ]; then
                . /etc/customization/profiles/domestic.conf
                cp -f /etc/customization/profiles/domestic.conf /etc/om.ips
                cp -f /etc/customization/profiles/domestic.conf /etc/customization/original_scripts/om.ips
            else
                log_info "ERRO: Perfil domestic.conf nao encontrado"
                exit 1
            fi
            ;;
        2) 
            if [ -f /etc/customization/profiles/corporate.conf ]; then
                . /etc/customization/profiles/corporate.conf
                cp -f /etc/customization/profiles/corporate.conf /etc/om.ips
                cp -f /etc/customization/profiles/corporate.conf /etc/customization/original_scripts/om.ips
            else
                log_info "ERRO: Perfil corporate.conf nao encontrado"
                exit 1
            fi
            ;;
        3) 
            if [ -f /etc/customization/profiles/health.conf ]; then
                . /etc/customization/profiles/health.conf
                cp -f /etc/customization/profiles/health.conf /etc/om.ips
                cp -f /etc/customization/profiles/health.conf /etc/customization/original_scripts/om.ips
            else
                log_info "ERRO: Perfil health.conf nao encontrado"
                exit 1
            fi
            ;;
        *) 
            log_info "Perfil invalido: $num"
            exit 1 
            ;;
    esac
    log_info "Perfil $num carregado"
}

check_network() { 
    nc -w 2 -v "$1" "${2:-80}" </dev/null 2>/dev/null
}

install_packages() {
    [ $# -eq 0 ] && return
    log_info "Instalando: $*"
    wait_for_apt_unlock                          # ← aguarda lock
    if [ "${APT_UPDATED:-0}" = "0" ]; then
        apt-get update -qq
        APT_UPDATED=1
    fi
    if ! apt-get install --assume-yes --no-install-recommends -qq "$@"; then
        log_warning "Falha parcial na instalação. Tentando corrigir..."
        apt-get --fix-broken install -y -qq
    fi
}

load_om_ips() {
    if [ -f /etc/om.ips ]; then
        . /etc/om.ips
        log_info "Arquivo /etc/om.ips carregado"
        return 0
    else
        log_info "AVISO: /etc/om.ips nao encontrado"
        return 1
    fi
}

get_profile_from_om_ips() {
    if [ -f /etc/om.ips ]; then
        if grep -q "ENABLE_HEALTH_APPS=true" /etc/om.ips 2>/dev/null; then
            echo "3"
        elif grep -q "ENABLE_BACKUP=true" /etc/om.ips 2>/dev/null; then
            echo "2"
        else
            echo "1"
        fi
    else
        echo "1"
    fi
}

ensure_network() {
    local host="$1"
    local port="${2:-80}"
    local timeout="${3:-5}"
    if nc -w "$timeout" -v "$host" "$port" </dev/null 2>/dev/null; then
        return 0
    else
        log_info "AVISO: Host $host:$port nao acessivel"
        return 1
    fi
}

# =============================================================================
# DETECÇÃO DO SERVIDOR NFS
# =============================================================================
detect_nfs_server() {
    local kvmip hostip oi1 oi2 oi3
    
    kvmip=$(ip addr show 2>/dev/null | grep "virbr0" | grep -v dynamic | grep "inet " | head -1 | awk '{print $2}' | cut -d/ -f1)
    
    if [ -n "$kvmip" ]; then
        oi1=$(echo "$kvmip" | cut -d . -f 1)
        oi2=$(echo "$kvmip" | cut -d . -f 2)
        oi3=$(echo "$kvmip" | cut -d . -f 3)
        echo "$oi1.$oi2.$oi3.1"
        return 0
    fi
    
    hostip=$(ip addr show 2>/dev/null | grep "inet " | grep -v 127.0.0. | head -1 | awk '{print $2}' | cut -d/ -f1)
    if [ -n "$hostip" ]; then
        oi1=$(echo "$hostip" | cut -d . -f 1)
        oi2=$(echo "$hostip" | cut -d . -f 2)
        oi3=$(echo "$hostip" | cut -d . -f 3)
        echo "$oi1.$oi2.$oi3.1"
        return 0
    fi
    
    echo "192.168.122.1"
    return 1
}


mount_nfs_if_available() {
    local nfs_server="$1"
    local mount_point="$2"
    local export_path="$3"
    local description="$4"
    local nfs_port="${5:-$NFS_PORT}"   # usa 5º argumento ou padrão

    if [ -z "$nfs_server" ] || [ -z "$mount_point" ] || [ -z "$export_path" ]; then
        echo "[ERROR] mount_nfs_if_available: argumentos insuficientes" >&2
        return 1
    fi

    if ! command -v mount.nfs >/dev/null 2>&1; then
        log_info "   ❌ mount.nfs não encontrado. O pacote nfs-common está instalado?"
        return 1
    fi

    if [ ! -d "$mount_point" ]; then
        mkdir -p "$mount_point" 2>/dev/null
    fi

    if mountpoint -q "$mount_point" 2>/dev/null; then
        log_info "   ✅ $description já montado em $mount_point" >&2
        return 0
    fi

    if ! nc -w 2 -v "$nfs_server" "$nfs_port" < /dev/null 2>/dev/null; then
        log_info "   ❌ Servidor NFS $nfs_server:$nfs_port inacessível para $description"
        return 1
    fi

    log_info "Montando $nfs_server:$export_path em $mount_point"
    if mount -t nfs -o vers=4.2 "$nfs_server:$export_path" "$mount_point" -o nolock,soft,timeo=50,retrans=2 2>/dev/null; then
        log_info "   ✅ $description montado: $mount_point"
        return 0
    else
        log_info "   ❌ Falha ao montar $description: $nfs_server:$export_path"
        return 1
    fi
}

# =============================================================================
# download_with_cache - Download com cache persistente em /tmp/cache
#   Uso: download_with_cache <URL> <arquivo_destino> [--no-cache]
#   - Utiliza /tmp/cache como repositório (NFS ou local)
#   - Gera nome único baseado na URL para evitar colisões
#   - Se destino já existe e tem mesmo tamanho do cache, pula cópia
#   - --no-cache força download mesmo que cache exista
# =============================================================================
download_with_cache() {
    local url="$1"
    local output="$2"
    local use_cache=true

    if [ "${3:-}" = "--no-cache" ]; then
        use_cache=false
    fi

    local cache_dir="/tmp/cache"
    mkdir -p "$cache_dir" 2>/dev/null || {
        log_error "Não foi possível criar $cache_dir"
        return 1
    }

    # Gera nome seguro baseado na URL completa (evita colisão de basename)
    local safe_name=$(echo "$url" | sed 's|https\?://||; s|/|_|g; s|[?&=]|_|g')
    local cache_file="$cache_dir/${safe_name}"

    # Se cache for permitido e arquivo no cache existir
    if [ "$use_cache" = true ] && [ -f "$cache_file" ]; then
        # Se o destino já existe e tem o mesmo tamanho do cache, pulamos cópia (reutiliza)
        if [ -f "$output" ] && [ $(stat -c%s "$output" 2>/dev/null || echo 0) -eq $(stat -c%s "$cache_file" 2>/dev/null || echo -1) ]; then
            log_info "✅ Arquivo já presente em $output (tamanho consistente com cache)"
            return 0
        fi
        cp "$cache_file" "$output" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_info "✅ Usando cache: $cache_file → $output"
            return 0
        else
            log_warning "⚠️ Falha ao copiar do cache: $cache_file"
        fi
    fi

    # Download real
    log_info "🌐 Baixando de: $url"
    if wget --timeout=30 --tries=3 -q --show-progress -O "$output" "$url"; then
        # Armazena no cache para uso futuro
        if [ "$use_cache" = true ]; then
            cp "$output" "$cache_file" 2>/dev/null && \
                log_info "📦 Arquivo armazenado em cache: $cache_file"
        fi
        return 0
    else
        log_error "❌ Falha no download: $url"
        return 1
    fi
}

# =============================================================================
# update_apt_keys_no_proxy - Atualiza chaves GPG e listas SEM proxy
# 
#   - TODOS - os hosts são testados a cada execução. Se um host estiver offline,
#     ele será desabilitado APENAS durante esta execução (backup em
#     disabled_repos_backup). O main.sh se encarrega de restaurá-los ao final.
#   - Mantido o cache de 30 minutos apenas para evitar reexecuções
#     desnecessárias do apt-get update quando o main.sh é chamado múltiplas
#     vezes em sequência.
# =============================================================================
update_apt_keys_no_proxy() {
    # -------------------------------------------------------------------------
    # Cache de execução recente (30 min) – pula toda a verificação se já feita
    # -------------------------------------------------------------------------
    local PREFLIGHT_CACHE="/tmp/preflight_done"
    local MAX_AGE_SECONDS=1800  # 30 minutos

    if [ -f "$PREFLIGHT_CACHE" ]; then
        local cache_time=$(stat -c %Y "$PREFLIGHT_CACHE" 2>/dev/null || echo 0)
        local now=$(date +%s)
        if [ $((now - cache_time)) -lt $MAX_AGE_SECONDS ]; then
            log_info "⏭️ Preflight já executado há menos de 30 min. Pulando verificação de conectividade e atualização."
            return 0
        fi
    fi

    log_info "Atualizando chaves GPG do sistema (sem proxy)..."
    
    # Reinstala o keyring do Ubuntu para garantir chaves atualizadas
    wget http://archive.ubuntu.com/ubuntu/pool/main/u/ubuntu-keyring/ubuntu-keyring_2023.11.28.1_all.deb \
        -O /tmp/ubuntu-keyring_2023.11.28.1_all.deb 2>/dev/null
    apt install -y -qq /tmp/ubuntu-keyring_2023.11.28.1_all.deb 2>/dev/null

    local SOURCES_DIR="/etc/apt/sources.list.d"
    local MAIN_SOURCES="/etc/apt/sources.list"
    local TIMEOUT=2   # reduzido de 5 para 2 segundos
    local BACKUP_DIR="${SOURCES_DIR}/disabled_repos_backup"
    local TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    local disabled_count=0
    local ok_count=0
    
    mkdir -p "$BACKUP_DIR"

    # =========================================================================
    # VERIFICAÇÃO DE CONECTIVIDADE DOS REPOSITÓRIOS .sources (DEB822)
    # =========================================================================
    log_info "Verificando conectividade dos repositórios .sources..."
    
    # Processa cada arquivo .sources
    for srcfile in "$SOURCES_DIR"/*.sources; do
        [ -f "$srcfile" ] || continue
        
        local basename=$(basename "$srcfile")
        
        # Pula arquivos que já estão desabilitados
        if grep -q "^Enabled: no" "$srcfile" 2>/dev/null; then
            log_info "   ⏭️ $basename já está desabilitado. Pulando."
            continue
        fi
        
        # Extrai o host da linha URIs: (suporta múltiplos formatos)
        local host=$(grep -m1 "^URIs:" "$srcfile" 2>/dev/null | \
                     sed 's/^URIs:[[:space:]]*//' | \
                     sed 's|https\?://||' | \
                     sed 's|/.*||' | \
                     sed 's/:.*//' | \
                     tr -d '[:space:]')
        
        if [ -z "$host" ]; then
            log_info "   ⚠️ $basename: não foi possível extrair host. Pulando."
            continue
        fi
        
        # Pula hosts locais (proxy, cache, localhost)
        if [[ "$host" == "192.168."* ]] || [[ "$host" == "10."* ]] || \
           [[ "$host" == "127.0.0.1" ]] || [[ "$host" == "localhost" ]]; then
            log_info "   ⏭️ $basename ($host): host local. Pulando."
            continue
        fi
        
        # =====================================================================
        # TESTE DE CONECTIVIDADE REAL
        # Usa curl -4 -sI --max-time para verificar se o host responde a
        # requisições HTTP/HTTPS reais, não apenas se a porta TCP está aberta.
        # Força IPv4 (-4) para evitar falsos negativos com IPv6 inacessível.
        # =====================================================================
        echo -n "   Testando $host ... "
        
        # Tenta HTTPS primeiro (requisição real com curl)
        if curl -4 -sI --max-time "$TIMEOUT" "https://${host}/" >/dev/null 2>&1; then
            echo "✅ OK (HTTPS)"
            ok_count=$((ok_count + 1))
            continue
        fi
        
        # Fallback: tenta HTTP com curl
        if curl -4 -sI --max-time "$TIMEOUT" "http://${host}/" >/dev/null 2>&1; then
            echo "✅ OK (HTTP)"
            ok_count=$((ok_count + 1))
            continue
        fi
        
        # Último fallback: tenta nc -z (menos confiável, mas melhor que nada)
        if nc -w "$TIMEOUT" -z "$host" 443 2>/dev/null || nc -w "$TIMEOUT" -z "$host" 80 2>/dev/null; then
            echo "⚠️ OK (TCP only - pode falhar)"
            ok_count=$((ok_count + 1))
            continue
        fi
        
        echo "❌ INACESSÍVEL"
        
        # Faz backup antes de modificar
        cp "$srcfile" "$BACKUP_DIR/${basename}.bak_${TIMESTAMP}"
        
        # Desabilita o repositório: adiciona "Enabled: no"
        if grep -q "END PGP PUBLIC KEY BLOCK" "$srcfile" 2>/dev/null; then
            sed -i "/END PGP PUBLIC KEY BLOCK/a Enabled: no" "$srcfile"
        elif grep -q "^Signed-By:" "$srcfile" 2>/dev/null; then
            sed -i "/^Signed-By:/a Enabled: no" "$srcfile"
        else
            sed -i "1i Enabled: no" "$srcfile"
        fi
        
        log_warning "   ⚠️ DESABILITADO: $basename ($host inacessível)"
        disabled_count=$((disabled_count + 1))
    done
    
    # Resumo da verificação .sources
    if [ $disabled_count -gt 0 ] || [ $ok_count -gt 0 ]; then
        log_info "📊 Verificação de repositórios .sources:"
        log_info "   ✅ Acessíveis: $ok_count"
        [ $disabled_count -gt 0 ] && log_warning "   ⚠️ Desabilitados: $disabled_count (backup em $BACKUP_DIR)"
    fi

    # =========================================================================
    # VERIFICAÇÃO DE CONECTIVIDADE DOS REPOSITÓRIOS .list (TRADICIONAIS)
    # =========================================================================
    log_info "Verificando conectividade dos repositórios .list..."
    
    local list_ok_count=0
    local list_disabled_count=0
    
    # =========================================================================
    # FUNÇÃO INTERNA: Testa um host e retorna 0 se acessível, 1 se inacessível
    # =========================================================================
    _test_host_connectivity() {
        local host="$1"
        local protocol="${2:-https}"
        local cache_var="TESTED_HOST_${host//[.-]/_}"
        
        # Verifica cache
        if [ "${!cache_var:-}" = "ok" ]; then
            return 0
        elif [ "${!cache_var:-}" = "fail" ]; then
            return 1
        fi
        
        # Testa com curl (força IPv4)
        if curl -4 -sI --max-time "$TIMEOUT" "${protocol}://${host}/" >/dev/null 2>&1; then
            eval "$cache_var=ok"
            return 0
        fi
        
        # Fallback HTTP se HTTPS falhou
        if [ "$protocol" = "https" ] && curl -4 -sI --max-time "$TIMEOUT" "http://${host}/" >/dev/null 2>&1; then
            eval "$cache_var=ok"
            return 0
        fi
        
        # Último fallback: nc -z
        if nc -w "$TIMEOUT" -z "$host" 443 2>/dev/null || nc -w "$TIMEOUT" -z "$host" 80 2>/dev/null; then
            eval "$cache_var=ok"
            return 0
        fi
        
        eval "$cache_var=fail"
        return 1
    }
    
    # =========================================================================
    # FUNÇÃO INTERNA: Processa um único arquivo .list
    # =========================================================================
    _process_list_file() {
        local listfile="$1"
        local basename=$(basename "$listfile")
        local modified=false
        local tempfile=$(mktemp)
        local file_disabled=0
        local file_ok=0
        
        # Lê o arquivo linha por linha
        while IFS= read -r line || [ -n "$line" ]; do
            # Pula linhas vazias ou já comentadas (preserva comentários existentes)
            if [ -z "$line" ] || [[ "$line" =~ ^[[:space:]]*# ]]; then
                echo "$line" >> "$tempfile"
                continue
            fi
            
            # Verifica se é uma linha deb ou deb-src
            if [[ "$line" =~ ^[[:space:]]*(deb|deb-src)[[:space:]]+ ]]; then
                # Extrai a URL da linha
                local url=$(echo "$line" | sed -n 's/^[[:space:]]*\(deb\|deb-src\)[[:space:]]\+\(\[[^]]*\][[:space:]]\+\)\?\(https\?:\/\/[^[:space:]]*\).*/\3/p')
                
                if [ -z "$url" ]; then
                    echo "$line" >> "$tempfile"
                    continue
                fi
                
                # Extrai o host da URL
                local host=$(echo "$url" | sed 's|https\?://||' | sed 's|/.*||' | tr -d '[:space:]')
                
                if [ -z "$host" ]; then
                    echo "$line" >> "$tempfile"
                    continue
                fi
                
                # Pula hosts locais (proxy, cache, localhost)
                if [[ "$host" == "192.168."* ]] || [[ "$host" == "10."* ]] || \
                   [[ "$host" == "127.0.0.1" ]] || [[ "$host" == "localhost" ]]; then
                    echo "$line" >> "$tempfile"
                    continue
                fi
                
                # Determina o protocolo
                local protocol="https"
                if [[ "$url" == http://* ]]; then
                    protocol="http"
                fi
                
                # Testa conectividade
                echo -n "   Testando $host ($protocol)... "
                
                if _test_host_connectivity "$host" "$protocol"; then
                    echo "✅ OK"
                    file_ok=$((file_ok + 1))
                    echo "$line" >> "$tempfile"
                else
                    echo "❌ INACESSÍVEL"
                    echo "# [DISABLED] $line" >> "$tempfile"
                    modified=true
                    file_disabled=$((file_disabled + 1))
                fi
            else
                # Linha não é deb/deb-src (ex: comentário, linha em branco)
                echo "$line" >> "$tempfile"
            fi
        done < "$listfile"
        
        if [ "$modified" = true ]; then
            cp "$listfile" "$BACKUP_DIR/${basename}.bak_${TIMESTAMP}"
            mv "$tempfile" "$listfile"
            chmod 644 "$listfile"
            log_warning "   ⚠️ $file_disabled repositório(s) desabilitado(s) em $basename"
        else
            rm -f "$tempfile"
            if [ $file_ok -gt 0 ]; then
                log_info "   ✅ $basename: $file_ok repositório(s) acessível(is)"
            fi
        fi
        
        list_ok_count=$((list_ok_count + file_ok))
        list_disabled_count=$((list_disabled_count + file_disabled))
    }
    
    # Processa o sources.list principal (se existir)
    if [ -f "$MAIN_SOURCES" ]; then
        log_info "   📄 Processando sources.list principal..."
        _process_list_file "$MAIN_SOURCES"
    fi
    
    # Processa cada arquivo .list em sources.list.d
    for listfile in "$SOURCES_DIR"/*.list; do
        [ -f "$listfile" ] || continue
        
        if [ "$(basename "$listfile")" = "sources.list" ]; then
            log_info "   ⏭️ sources.list em sources.list.d: ignorado (pertence a /etc/apt/)."
            continue
        fi
        
        _process_list_file "$listfile"
    done
    
    # Resumo da verificação .list
    if [ $list_disabled_count -gt 0 ] || [ $list_ok_count -gt 0 ]; then
        log_info "📊 Verificação de repositórios .list:"
        log_info "   ✅ Acessíveis: $list_ok_count"
        [ $list_disabled_count -gt 0 ] && log_warning "   ⚠️ Desabilitados: $list_disabled_count (backup em $BACKUP_DIR)"
    fi

    # =========================================================================
    # ATUALIZAÇÃO DAS LISTAS (com timeout e saída redirecionada)
    # =========================================================================
    log_info "Preparando listas de pacotes (sem proxy) para validar assinaturas..."
    log_info "   (Esta operação pode levar alguns minutos. Detalhes em: ${LOG_DIR:-/var/log/customization}/preflight_update.log)"
    rm -rf /var/lib/apt/lists/*
    
    local preflight_log="${LOG_DIR:-/var/log/customization}/preflight_update.log"
    mkdir -p "$(dirname "$preflight_log")" 2>/dev/null || true
    
    {
        echo "=== Início da atualização de listas (preflight) - $(date) ==="
        echo ""
        timeout 120 apt-get update \
            -o Acquire::http::Timeout=10 \
            -o Acquire::https::Timeout=10 \
            -o Acquire::ftp::Timeout=10 2>&1
        local exit_code=$?
        echo ""
        echo "=== Fim da atualização de listas (preflight) - $(date) ==="
        echo "Exit code: $exit_code"
    } > "$preflight_log" 2>&1
    
    local result=${PIPESTATUS[0]:-0}
    if [ "$result" -eq 0 ]; then
        log_info "   ✅ Listas de pacotes atualizadas com sucesso."
    else
        log_warning "⚠️ apt-get update reportou erros (detalhes em ${preflight_log})."
        log_warning "   Repositórios inacessíveis foram desabilitados. Backups em: $BACKUP_DIR"
    fi

    # Marca que o preflight foi executado com sucesso
    touch "$PREFLIGHT_CACHE"
}

# ----------------------------------------------------------------------
# Obtém o IP do servidor NFS com base nas variáveis do perfil:
# 1. NFSSERVERER (se definido)
# 2. APTCACHER (fallback)
# 3. Detecção automática do gateway (KVM ou padrão)
# ----------------------------------------------------------------------
get_nfs_server() {
    local nfs_server=""
    local nfs_port="${NFSPORT:-$NFS_PORT}"
    local testado=0

    # 1. Tenta NFSSERVERER
    if [ -n "${NFSSERVERER:-}" ]; then
        echo "[INFO] Tentando servidor NFS definido no perfil (NFSSERVERER): $NFSSERVERER" >&2
        if check_nfs_server "$NFSSERVERER" "$nfs_port"; then
            nfs_server="$NFSSERVERER"
            echo "[INFO] ✅ Servidor NFS do perfil ($nfs_server) acessível na porta $nfs_port." >&2
            testado=1
        else
            echo "[WARN] ⚠️ Servidor NFS do perfil ($NFSSERVERER) não responde na porta $nfs_port." >&2
        fi
    fi

    # 2. Tenta APTCACHER (se não encontrou ainda)
    if [ -z "$nfs_server" ] && [ -n "${APTCACHER:-}" ]; then
        echo "[INFO] Tentando servidor NFS via APTCACHER: $APTCACHER" >&2
        if check_nfs_server "$APTCACHER" "$nfs_port"; then
            nfs_server="$APTCACHER"
            echo "[INFO] ✅ Servidor NFS via APTCACHER ($nfs_server) acessível na porta $nfs_port." >&2
            testado=1
        else
            echo "[WARN] ⚠️ Servidor NFS via APTCACHER ($APTCACHER) não responde na porta $nfs_port." >&2
        fi
    fi

    # 3. Fallback para detecção automática
    if [ -z "$nfs_server" ]; then
        echo "[INFO] Usando detecção automática de servidor NFS." >&2
        nfs_server=$(detect_nfs_server)
        if nc -w 2 -v "$nfs_server" "$port" </dev/null 2>/dev/null && check_nfs_server "$nfs_server" "$nfs_port"; then
            echo "[INFO] ✅ NFS disponível em $nfs_server (porta $nfs_port)" >&2
        else
            echo "[WARN] ⚠️ NFS: indisponível - instalações Flatpak serão mais lentas" >&2
        fi
    fi

    # Retorna apenas o IP, sem logs
    echo "$nfs_server"
}

# ----------------------------------------------------------------------
# check_nfs_server - testa conectividade na porta NFS (padrão 2049)
# ----------------------------------------------------------------------
check_nfs_server() {
    local nfs_server="$1"
    local port="${NFSPORT:-$NFS_PORT}"   # prioriza NFSPORT do perfil
    if nc -w 2 -v "$nfs_server" "$port" </dev/null 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# =============================================================================
# FUNÇÃO: MONTA NFS
# =============================================================================
mount_nfs_direct() {
    local NFS_PORT_ACTUAL="${NFSPORT:-$NFS_PORT}"
    log_info "Montando NFS para cache Flatpak (porta $NFS_PORT_ACTUAL)..."

    # NFS_SERVER é global para uso posterior no rebuild_flatpak_cache_if_empty
    NFS_SERVER=""
    if [ -n "${NFS_SERVER_SELECTED:-}" ]; then
        NFS_SERVER="$NFS_SERVER_SELECTED"
        log_info "Usando servidor NFS selecionado no preflight: $NFS_SERVER"
    else
        NFS_SERVER=$(get_nfs_server)
        log_info "Servidor NFS detectado agora: $NFS_SERVER"
    fi

    if [ -z "$NFS_SERVER" ]; then
        log_warning "Não foi possível determinar servidor NFS. Abortando montagem."
        return 1
    fi

    if nc -w 2 -v "$NFS_SERVER" "$NFS_PORT_ACTUAL" < /dev/null 2>/dev/null; then
        log_info "Servidor NFS acessível"
    else
        log_warning "Servidor NFS $NFS_SERVER:$NFS_PORT_ACTUAL inacessível"
        return 1
    fi

    log_info "Montando Flatpak cache..."
    mount_nfs_if_available "$NFS_SERVER" "/mnt" "/partimag/flatpakcache/" "Flatpak cache" "$NFS_PORT_ACTUAL"

    log_info "Montando repositório administrativo..."
    mount_nfs_if_available "$NFS_SERVER" "/tmp/cache" "/partimag/cache/" "Repositório admin" "$NFS_PORT_ACTUAL"

    if mountpoint -q /mnt && [ -d /mnt/.ostree/repo ]; then
        log_info "Configurando Flatpak para usar cache NFS..."
        flatpak remote-modify --collection-id=org.flathub.Stable flathub 2>/dev/null || true
        log_info "Flatpak configurado com cache em /mnt/.ostree/repo"
    else
        log_info "Cache Flatpak NFS não encontrado em /mnt/.ostree/repo"
    fi

    export NFS_MOUNTED_BY_MAIN=true
    return 0
}

# =============================================================================
# run_preflight - Verifica pré-requisitos priorizando configurações do perfil
# =============================================================================
run_preflight() {
    local perfil_num="$1"
    
    log_info "========================================="
    log_info "🔍 PREFLIGHT - Verificação de pré-requisitos"
    log_info "========================================="
    
    # -------------------------------------------------------------------------
    # 1. Verificação do servidor NFS (prioridade para perfil)
    # -------------------------------------------------------------------------
    log_info "1. Verificando servidor NFS..."
    
    local NFS_SERVER=""
    local NFS_PORT="${NFSPORT:-$NFS_PORT}"   # padrão 2049, sobrescrito por NFSPORT do perfil
    local testado=0
    
    # 1.1 Tenta NFSSERVERER definido no perfil
    if [ -n "${NFSSERVERER:-}" ]; then
        log_info "   Tentando servidor NFS definido no perfil (NFSSERVERER): $NFSSERVERER"
        if check_nfs_server "$NFSSERVERER" "$NFS_PORT"; then
            NFS_SERVER="$NFSSERVERER"
            log_info "   ✅ Servidor NFS do perfil ($NFS_SERVER) está acessível na porta $NFS_PORT."
            testado=1
        else
            log_warning "   ⚠️ Servidor NFS do perfil ($NFSSERVERER) não responde na porta $NFS_PORT."
        fi
    fi
    
    # 1.2 Se falhou ou não definido, tenta APTCACHER (que pode ser o mesmo IP)
    if [ -z "$NFS_SERVER" ] && [ -n "${APTCACHER:-}" ]; then
        log_info "   Tentando servidor NFS via APTCACHER: $APTCACHER"
        if check_nfs_server "$APTCACHER" "$NFS_PORT"; then
            NFS_SERVER="$APTCACHER"
            log_info "   ✅ Servidor NFS via APTCACHER ($NFS_SERVER) está acessível na porta $NFS_PORT."
            testado=1
        else
            log_warning "   ⚠️ Servidor NFS via APTCACHER ($APTCACHER) não responde na porta $NFS_PORT."
        fi
    fi
    
    # 1.3 Se nenhum dos anteriores funcionou, usa detecção automática (gateway KVM)
    if [ -z "$NFS_SERVER" ]; then
        log_info "   Usando detecção automática de servidor NFS (gateway KVM)."
        NFS_SERVER=$(detect_nfs_server)
        if check_nfs_server "$NFS_SERVER" "$NFS_PORT"; then
            log_info "   ✅ NFS: Disponível (porta $NFS_PORT)"
            testado=1
        else
            log_info "   ⚠️ NFS: Indisponível - instalações Flatpak serão mais lentas"
        fi
    fi
    
    # Armazena o servidor NFS escolhido para uso posterior (exportável)
    if [ -n "$NFS_SERVER" ]; then
        export NFS_SERVER_SELECTED="$NFS_SERVER"
    fi
    
    # -------------------------------------------------------------------------
    # 2. Verificação do APT-Cacher-NG (apenas script, a lógica real está no acngonoff.sh)
    # -------------------------------------------------------------------------
    log_info ""
    log_info "2. Verificando APT-Cacher-NG..."
    if [ -f /etc/acngonoff.sh ]; then
        log_info "   ✅ /etc/acngonoff.sh encontrado"
    else
        log_info "   ℹ️ /etc/acngonoff.sh será criado na sincronização"
    fi
    
    # -------------------------------------------------------------------------
    # 3. Verificação do Flatpak
    # -------------------------------------------------------------------------
    log_info ""
    log_info "3. Verificando Flatpak..."
    if command -v flatpak >/dev/null 2>&1; then
        log_info "   ✅ Flatpak instalado: $(flatpak --version)"
    else
        log_info "   ⚠️ Flatpak não instalado"
    fi
    
    # -------------------------------------------------------------------------
    # 4. Exibição do perfil selecionado e suas variáveis relevantes
    # -------------------------------------------------------------------------
    log_info ""
    log_info "4. Perfil selecionado: $perfil_num"
    case "$perfil_num" in
        1) log_info "   🏠 Perfil DOMÉSTICO" ;;
        2) log_info "   🏢 Perfil CORPORATIVO" ;;
        3) log_info "   🏥 Perfil SAÚDE" ;;
    esac
    
    # Exibe configurações definidas (se houver)
    [ -n "${APTCACHER:-}" ] && log_info "   🔧 Proxy APT definido no perfil: ${APTCACHER}:${CACHEPORT:-3142}"
    [ -n "${NFSSERVERER:-}" ] && log_info "   🔧 Servidor NFS definido no perfil: ${NFSSERVERER}:${NFSPORT:-2049}"
    [ -n "${DNS:-}" ] && log_info "   🔧 DNS primário: $DNS"
    [ -n "${DNS2:-}" ] && log_info "   🔧 DNS secundário: $DNS2"
    
    log_info "========================================="
    return 0
}

ostree-repo-maintenance-mark() {
# =============================================================================
# Manutençãoo diária do cache NFS (prune de versões antigas)
# Agora com marcador compartilhado via NFS e lock atômico
# =============================================================================
if [ "$CACHE_AVAILABLE" = true ] && [ -w /mnt/.ostree/repo ]; then
    MAINT_SCRIPT="/usr/local/bin/flatpak-cache-maintenance.sh"
    FLAG_FILE="/mnt/.ostree/repo/.last-maintenance"  # \u2190 marcador no NFS
    LOCK_DIR="/mnt/.ostree/repo/.maintenance.lock"
    TODAY=$(date +%Y%m%d)
    
    if [ -f "$MAINT_SCRIPT" ] && [ -x "$MAINT_SCRIPT" ]; then
        # Tenta adquirir o lock atômico (mkdir é operação atôpmica)
        if mkdir "$LOCK_DIR" 2>/dev/null; then
            # Verifica a data do marcador compartilhado
            if [ -f "$FLAG_FILE" ]; then
                LAST_RUN=$(cat "$FLAG_FILE" 2>/dev/null)
            else
                LAST_RUN=""
            fi

            if [ "$LAST_RUN" = "$TODAY" ]; then
                log_info "\u2139\ufe0f Manutencao do cache Flatpak ja executada hoje ($TODAY). Nada a fazer."
            else
                log_info "\U0001f4c6 Ultima execucao: ${LAST_RUN:-nunca}. Executando manutencao..."
                if bash "$MAINT_SCRIPT"; then
                    echo "$TODAY" > "$FLAG_FILE"
                    log_info "\u2705 Manutencao concluida. Marcador atualizado para $TODAY."
                else
                    log_warning "\u26a0\ufe0f Falha na manutencao. Tente novamente amanha."
                fi
            fi
            rmdir "$LOCK_DIR" 2>/dev/null   # libera o lock
        else
            log_info "\u23f3 Outra VM esta executando a manutencao. Aguardando..."
            # Aguarda um pouco e reavalia o marcador
            sleep 5
            if [ -f "$FLAG_FILE" ]; then
                LAST_RUN=$(cat "$FLAG_FILE")
                if [ "$LAST_RUN" = "$TODAY" ]; then
                    log_info "\u2705 Manutencao concluida por outra VM (marcador atualizado)."
                fi
            fi
        fi
    else
        log_info "\u26a0\ufe0f Script de manutencao nao encontrado ou nao executavel: $MAINT_SCRIPT"
    fi
fi
}
