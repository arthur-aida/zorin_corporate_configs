Perfis de Configuração

_1. Estrutura Real dos Arquivos de Perfil_

Os arquivos .conf em profiles/ não utilizam o formato chave="valor" com nomes semânticos como PROFILE_NAME, CACHE_HOST ou INSTALL_ICP_BRASIL. Eles são arquivos shell com variáveis de ambiente específicas, carregadas pelo main.sh e pelos módulos via source. O conteúdo real é:

**corporate.conf**

```text
APTCACHER="192.168.122.1"
CACHEPORT="3142"
NFSSERVERER="192.168.122.1"
NFSPORT="2049"
DNS="10.89.36.196"
site="https://intranet.corporativo.com"
sigh="10.0.0.30"
ENABLE_BACKUP=true
ENABLE_FLATPAK_CACHE=true
ENABLE_HEALTH_APPS=false
hostsallow0="sshd: 192.168.123.0/24"
hostsallow1="sshd: 10.0.0.0/16"
hostsallow2="sshd: 192.168.122.0/24"
hostsallow3="sshd: 127.0.0.1"
hostsdeny="sshd: ALL"
```

**domestic.conf**

```text
site="https://www.google.com.br"
ENABLE_BACKUP=false
ENABLE_FLATPAK_CACHE=true
ENABLE_HEALTH_APPS=false
hostsallow0=""
hostsallow1=""
hostsallow2=""
hostsallow3=""
hostsdeny=""
```

**health.conf**

```text
APTCACHER="192.168.3.3"
CACHEPORT="3142"
NFSSERVERER="192.168.3.3"
NFSPORT="2049"
DNS="10.89.36.196"
site="10.89.200.10"
sigh="10.89.200.17"
ENABLE_BACKUP=true
ENABLE_FLATPAK_CACHE=true
ENABLE_HEALTH_APPS=true
hostsallow0="sshd : 192.168.123.0/24"
hostsallow1="sshd : 192.168.122.0/24"
hostsallow2="sshd : 192.168.3.0/24"
hostsallow3="sshd : 127.0.0.1"
hostsdeny="sshd : ALL"
ntpserver="10.89.37.46"
```

_2. Descrição das Variáveis Reais_
```text
Variável	Descrição	Obrigatória
APTCACHER	            IP do servidor APT-Cacher-NG	                    Apenas perfis 2 e 3
CACHEPORT	            Porta do APT-Cacher-NG	                          Apenas perfis 2 e 3
NFSSERVERER	          IP do servidor NFS (grafia conforme arquivo real)	Apenas perfis 2 e 3
NFSPORT	              Porta NFS	                                        Apenas perfis 2 e 3
DNS	                  Servidor DNS interno	                            Apenas perfis 2 e 3
site	                Página inicial do navegador	                      Todos
sigh	                IP do servidor de assinatura digital	            Apenas perfis 2 e 3
ENABLE_BACKUP	        Habilita backup Proxmox	                          Todos
ENABLE_FLATPAK_CACHE	Habilita cache Flatpak via NFS	                  Todos
ENABLE_HEALTH_APPS	  Habilita apps de saúde (Weasis, pw3270)	          Todos
hostsallow0–3	        Regras de acesso SSH	                            Todos
hostsdeny	            Regra de negação SSH padrão	                      Todos
ntpserver	            Servidor NTP dedicado	                            Apenas health.conf
```

_3. Perfil corporate.conf — Corporativo_

```text
APTCACHER: 192.168.122.1
NFSSERVERER: 192.168.122.1
ENABLE_BACKUP: true
ENABLE_HEALTH_APPS: false
Regras SSH para redes 192.168.123.0/24, 10.0.0.0/16, 192.168.122.0/24 e localhost
Sem servidor NTP dedicado
```

_4. Perfil health.conf — Saúde_

```text
APTCACHER: 192.168.3.3 (distinto do corporativo)
NFSSERVERER: 192.168.3.3
ENABLE_BACKUP: true
ENABLE_HEALTH_APPS: true
ntpserver: 10.89.37.46 (exclusivo deste perfil)
DNS: 10.89.36.196 (compartilhado com corporativo)
sigh: 10.89.200.17
```

_5. Perfil domestic.conf — Doméstico_

```text
APTCACHER: ausente (sem cache corporativo)
ENABLE_BACKUP: false
ENABLE_FLATPAK_CACHE: true
ENABLE_HEALTH_APPS: false
hostsallow: todos vazios
hostsdeny: vazio
site: https://www.google.com.br
```

_6. Módulos Impactados por Perfil_

O ENABLE_HEALTH_APPS é consumido diretamente pelo módulo 11-flatpak-cache.sh:

```bash
if [ "${ENABLE_HEALTH_APPS:-false}" = "true" ]; then
    packages+=("io.github.nroduit.Weasis" "br.app.pw3270.terminal")
else
    packages+=("org.onlyoffice.desktopeditors")
fi
```

O ENABLE_BACKUP é consumido pelo módulo 10-backup.sh:

```bash
if [ "${ENABLE_BACKUP:-false}" != "true" ]; then
    log_info "ENABLE_BACKUP não está habilitado. Pulando configuração."
    exit 0
fi
```

O ENABLE_FLATPAK_CACHE é consumido pelo módulo 11-flatpak-cache.sh:

```bash
if [ "${ENABLE_FLATPAK_CACHE:-false}" != "true" ]; then
    log_info "ℹ️ ENABLE_FLATPAK_CACHE=false - pulando"
    exit 0
fi
```

_7. Carregamento dos Perfis_

O main.sh carrega o perfil selecionado pelo usuário e persiste o perfil ativo para ferramentas independentes:
```bash
cat > /etc/customization/active-profile.env <<EOF
PERFIL="$PERFIL"
...
EOF
```

A função load_om_ips (em utils/common.sh) é responsável por carregar as variáveis do perfil (referenciada nos módulos 10-backup.sh e 11-flatpak-cache.sh).
