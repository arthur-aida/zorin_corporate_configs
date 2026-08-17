# Manual Completo do Projeto: zorin_corporate_configs

## Índice

1.  Introdução e Objetivo

2.  Visão Geral da Arquitetura

    - 2.1. Estrutura de Diretórios
    - 2.2. Sistema de Perfis
    - 2.3. Fluxo de Execução do main.sh

3.  Os Três Níveis de Cache e o Ecossistema Corporativo

    - 3.1. Cache Local, Proxy APT e Cache Flatpak
    - 3.2. Suporte ao Ecossistema GOV.BR (Certificados, Tokens,
      Assinadores, PJe Office, Saúde)

4.  Componentes Detalhados

    - 4.1. Scripts da Raiz (Funcionalidades Independentes)
    - 4.2. Módulos de Customização (00–15)
    - 4.3. Scripts Auxiliares (/scripts)
    - 4.4. Utilitários Compartilhados (/utils)

5.  Gerenciamento de Proxy e Roaming de Rede

    - 5.1. Teste e Exportação do Proxy
    - 5.2. Conversão e Restauração das Fontes APT
    - 5.3. Dispatcher do NetworkManager para Roaming
    - 5.4. Exemplos de Configuração de Perfil

6.  Guia de Implantação para os Três Públicos‑Alvo

    - 6.1. Usuário Doméstico / Independente (Máquina Única)
    - 6.2. Administrador de Sistemas (Implantação em Larga Escala)
    - 6.3. Desenvolvedor / Integrador (Extensão e Personalização)

7.  Referência Rápida de Comandos e Funções

8.  Recursos Ativados Pós-Customização (Para o Usuário Final)

9.  Considerações Finais e Recomendações

## 1. Introdução e Objetivo

O projeto **zorin_corporate_configs** é uma suíte de scripts para
automatizar a configuração, otimização e padronização de estações de
trabalho **Zorin OS** (e derivados Ubuntu) em ambientes corporativos,
educacionais e domésticos. Ele resolve problemas comuns em implantações
em massa:

- **Tempo de instalação** – Cache de pacotes APT e Flatpak reduz
  drasticamente o tempo de deploy.
- **Conformidade** – Gestão automatizada de certificados ICP‑Brasil e
  tokens A3, essenciais para acessar sistemas do governo federal
  (Comprasnet, SERPRO, PJe, etc.).
- **Segurança e manutenção** – Firewall, restrições SSH, monitoramento
  de discos, limpeza automática e atualizações programadas.
- **Mobilidade** – Suporte a roaming de rede para notebooks que alternam
  entre diferentes proxies.
- **Extensibilidade** – Arquitetura modular que permite adicionar novas
  funcionalidades com pouco esforço.

Este manual é o guia definitivo para **três perfis de usuário**:

- **Iniciante / Doméstico** – deseja aplicar as otimizações em um único
  computador, sem servidor.
- **Administrador de Sistemas** – precisa implantar a solução em dezenas
  ou centenas de máquinas.
- **Desenvolvedor / Engenheiro** – pretende modificar, estender ou
  integrar os scripts a outros sistemas.

A leitura sequencial das seções proporciona um entendimento gradual,
desde a arquitetura até a aplicação prática.

## 2. Visão Geral da Arquitetura

### 2.1. Estrutura de Diretórios

zorin_corporate_configs/  
├── Docs/ \# Documentação em PDF (manuais, relatórios)  
├── modules/ \# Módulos numerados (00 a 15)  
├── profiles/ \# Arquivos de perfil (.conf)  
├── scripts/ \# Scripts auxiliares e utilitários  
├── utils/ \# Funções compartilhadas  
└── main.sh \# Orquestrador principal

### 2.2. Sistema de Perfis

Os perfis (corporate.conf, domestic.conf, health.conf) definem variáveis
de ambiente que ativam/desativam funcionalidades. O perfil ativo é
carregado de /etc/customization/active-profile.env.

|                      |                                                                |
|----------------------|----------------------------------------------------------------|
| ENABLE_BACKUP        | Habilita cliente Proxmox Backup                                |
| ENABLE_FLATPAK_CACHE | Habilita uso de cache NFS para Flatpak                         |
| ENABLE_HEALTH_APPS   | Ativa aplicativos da área de saúde (Kaspersky, Weasis, PW3270) |
| APTCACHER            | IP do servidor APT‑Cacher‑NG                                   |
| CACHEPORT            | Porta do proxy (padrão 3142)                                   |
| NFSSERVERER          | IP do servidor NFS                                             |
| DNS                  | Servidor DNS para validação (perfil saúde)                     |

### 2.3. Fluxo de Execução do main.sh

1.  Carrega o perfil ativo e exporta as variáveis.
2.  Monta o cache NFS (se configurado).
3.  Configura o proxy APT via acngonoff.sh.
4.  Executa os módulos 00 a 15 em ordem.
5.  Realiza pós‑processamento (limpeza, reinstalação de GRUB, etc.).
6.  Logs centralizados em /var/log/customization-persist/main.log.

## 3. Os Três Níveis de Cache e o Ecossistema Corporativo

### 3.1. Os Três Níveis de Proxy/Cache

A solução implementa uma arquitetura de cache em três níveis para
garantir desempenho e escalabilidade em redes corporativas.

|                   |                            |                                                                                                                   |                                                                                                                 |
|-------------------|----------------------------|-------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| 1 – Local         | aptcacher.sh               | Testa conectividade com o proxy e ajusta as fontes APT dinamicamente.                                             | Permite que estações móveis operem fora da rede corporativa sem intervenção manual.                             |
| 2 – Proxy APT     | APT‑Cacher‑NG              | Cache central de pacotes .deb. A primeira requisição baixa da internet; as seguintes são servidas do cache local. | Reduz em mais de 80% o tráfego de internet para atualizações e instalações. Acelera o deploy de novas máquinas. |
| 3 – Cache Flatpak | Repositório OSTree via NFS | Armazena aplicativos Flatpak no servidor. Os clientes instalam por *sideload* (sem download).                     | Instalação de aplicativos grandes (ex: OnlyOffice, OBS) em segundos, diretamente do servidor local.             |

O servidor de cache é configurado pelo script
setup-server-KVM-nfs-acng.sh, que também prepara o KVM e o firewall.

### 3.2. Suporte ao Ecossistema GOV.BR e Corporativo

Este projeto não é apenas um instalador de pacotes; ele é uma
**plataforma de produtividade** para acesso a sistemas governamentais e
corporativos.

#### Infraestrutura de Certificados e Tokens

- **Raízes ICP‑Brasil** – instalar_certificados_icp_brasil.sh baixa e
  instala as cadeias oficiais no sistema.
- **Drivers para Tokens A3** – safenet.sh, tokenGD.sh, TokenDXSafe.sh
  instalam drivers para os principais modelos (Safenet, G&D, Dexon).
- **Registro PKCS#11** – CARREGAdriverTOKEN.sh registra os módulos nos
  navegadores e no sistema.
- **Importação para o usuário** – import-icp-brasil.sh (executado no
  autostart) injeta os certificados nos bancos NSS dos navegadores e no
  p11-kit.

#### Assinatura Digital e Acesso a Sistemas

- **Assinador SERPRO** – serproass.sh instala o aplicativo oficial para
  assinar PDFs e documentos com validade jurídica.

- **Assinador Certillion** – certillion.sh oferece uma alternativa
  igualmente reconhecida.

- **PJe Office** – O módulo 09-signers.sh instala o pacote do CNJ para
  visualização e assinatura de processos judiciais eletrônicos.

- **Acesso a portais** – Com certificados e tokens configurados, o
  usuário pode acessar:

  - Comprasnet (sistema de compras do governo federal)
  - Portal GOV.BR (assinatura de contratos)
  - Sistemas do SERPRO
  - Plataformas de receituário eletrônico (CFM) e dispensação
    farmacêutica

#### Ferramentas para Saúde

- **Weasis** – visualizador de imagens DICOM, instalado via Flatpak no
  perfil saúde.
- **Kaspersky** – antivírus corporativo instalado sob demanda (perfil
  saúde) com validação de DNS (o pacote deste AV deve ser adquirido
  separadamente).

#### Estação Móvel com Acesso Corporativo

- **Roaming de rede** – O dispatcher do NetworkManager
  (99-apt-cacher-roaming) e o aptcacher.sh ajustam automaticamente o
  proxy ao mudar de rede.
- **Perfis flexíveis** – A mesma máquina pode ser usada em casa (perfil
  doméstico) ou no escritório (corporativo), mantendo as ferramentas
  necessárias.

## 4. Componentes Detalhados

### 4.1. Scripts em /etc (Funcionalidades Independentes)

|                                     |                                                                                                                        |
|-------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| acngonoff.sh                        | Testa conectividade com o proxy e exporta PROXY_URL para /tmp/acng_env.                                                |
| aptcacher.sh                        | Script de manutenção (cron): testa proxy, converte fontes, atualiza navegadores, executa Kaspersky, ativa trim em SSD. |
| bscautostart.sh                     | Instala ou inicia o Bonita Studio Community para usuários comuns.                                                      |
| CARREGAdriverTOKEN.sh               | Registra módulos PKCS#11 e adiciona cron para limpeza.                                                                 |
| certillion.sh                       | Instala o assinador Certillion para usuários comuns.                                                                   |
| clean.sh                            | Limpeza de caches de navegadores e temporários via BleachBit ou manual.                                                |
| firefox-manager.sh                  | Gerencia instalação/atualização do Firefox stable ou ESR, substituindo libnssckbi.so pelo p11‑kit do sistema.          |
| hookjava1.8.sh                      | Cria atalho para Java Web Start com JRE 8.                                                                             |
| instalar_certificados_icp_brasil.sh | Baixa e instala certificados ICP‑Brasil no sistema e configura Firefox.                                                |
| proxmoxbackupclient.sh              | Instala cliente Proxmox Backup com suporte a cache NFS e proxy.                                                        |
| safenet.sh                          | Instala drivers para tokens Safenet (versões 10.8/10.9).                                                               |
| serproass.sh                        | Baixa e executa o instalador oficial do Assinador Serpro (AppImage).                                                   |
| TokenDXSafe.sh                      | Instala driver para token Dexon DXSafe com ajustes para Ubuntu 24.04.                                                  |
| tokenGD.sh                          | Instala drivers para tokens G&D SafeSign para diversas distribuições.                                                  |

### 4.2. Módulos de Customização (00–15)

|                        |                                                                                                                      |
|------------------------|----------------------------------------------------------------------------------------------------------------------|
| 00‑dependencies        | Instala nfs-common, flatpak, ostree.                                                                                 |
| 01‑sync‑scripts        | Sincroniza scripts para /etc/ e /bin/; copia dispatcher e script de manutenção.                                      |
| 02‑bulk‑packages       | Instalação massiva de pacotes APT; configura Java 8 e JAVA_HOME.                                                     |
| 03‑certificates        | Executa instalar_certificados_icp_brasil.sh e update-ca-certificates.                                                |
| 04‑browsers            | Configura Firefox stable e ESR via firefox-manager.sh.                                                               |
| 05‑tokens              | Executa tokenGD.sh e safenet.sh; cria links para CARREGAdriverTOKEN.sh.                                              |
| 06‑icp‑user‑certs      | Prepara scripts de importação para usuários (skel e existentes).                                                     |
| 07‑kaspersky           | Copia tarball do Kaspersky do cache NFS e cria serviço systemd para instalação no boot (perfil saúde).               |
| 08‑wine                | Instala Wine (winehq‑stable ou fallback) e winetricks.                                                               |
| 09‑signers             | Instala libssl1.1, WebPKI e assinadores adicionais (Shodō, PJe Office).                                              |
| 10‑backup              | Se ENABLE_BACKUP=true, executa proxmoxbackupclient.sh.                                                               |
| 11‑flatpak‑cache       | Instala Flatpaks (BleachBit, KeePassXC, OBS, Jitsi, OnlyOffice/Weasis) via cache NFS; sincroniza e mantém cache.     |
| 12‑desktop‑config      | Configurações de desktop: drivers Epson, dicionários, cancelamento de ruído, CUPS, ícones, atalhos e wrapper DXSafe. |
| 13‑desktop‑config‑user | Gera script setup-icp-tokens.sh para usuários e cria atalho no menu.                                                 |
| 14‑security            | Configura script de reativação de impressoras, smartmontools, restrições SSH, cron e habilita SSH.                   |
| 15‑kvm‑menu            | Cria atalho no menu para instalação manual do KVM.                                                                   |

### 4.3. Scripts Auxiliares (/scripts)

|                                      |                                                                                                       |
|--------------------------------------|-------------------------------------------------------------------------------------------------------|
| 99-apt-cacher-roaming                | Dispatcher do NetworkManager: executa aptcacher.sh ao conectar uma rede.                              |
| convert-sources-to-proxy.sh          | Converte fontes APT para proxy com backup, roaming e validação.                                       |
| flatpak-cache-maintenance.sh         | Executa ostree prune no repositório NFS.                                                              |
| import-certs.desktop                 | Atalho de autostart para importar certificados ICP.                                                   |
| import-icp-brasil.sh                 | Importa certificados para o usuário via trust e certutil.                                             |
| install-kvm.desktop / install-kvm.sh | Instalação sob demanda do KVM/QEMU.                                                                   |
| kaspersky-boot-install.sh            | Aguarda DNS e instala Kaspersky a partir do tarball.                                                  |
| restore-sources-from-backup.sh       | Restaura fontes APT do backup original removendo proxy.                                               |
| setup-dxsafe-wrapper.sh              | Cria wrapper para TokenDXSafe.sh com interface GUI e atalho.                                          |
| setup-server-KVM-nfs-acng.sh         | Configura servidor de cache: APT‑Cacher‑NG, NFS, Flatpak OSTree, KVM, firewall e rebuild sob demanda. |

### 4.4. Utilitários Compartilhados (/utils)

|                     |                                                                                                                   |
|---------------------|-------------------------------------------------------------------------------------------------------------------|
| common.sh           | Funções essenciais: download_with_cache, log\_\*, check_root, wait_for_apt_unlock, load_om_ips, install_packages. |
| logging.sh          | Funções padronizadas de log com timestamps e marcadores de início/fim.                                            |
| fix-sources-list.sh | Corrige problemas comuns em listas de fontes APT.                                                                 |

## 5. Gerenciamento de Proxy e Roaming de Rede

### 5.1. Teste e Exportação do Proxy (acngonoff.sh)

- Lê APTCACHER e CACHEPORT do perfil.
- Se não definidos, usa o gateway padrão e porta 3142.
- Tenta conexão TCP via /dev/tcp.
- Em sucesso, escreve PROXY_URL em /tmp/acng_env; em falha, remove o
  arquivo.

### 5.2. Conversão e Restauração das Fontes APT

- **convert-sources-to-proxy.sh**:

  - Faz backup original (tarball) na primeira execução.
  - Substitui http:// por http://PROXY/ e https:// por
    http://PROXY/HTTPS///.
  - Adiciona marcador \# CONVERTED_TO_PROXY_BY_SCRIPT.
  - Detecta mudança de proxy (roaming) e atualiza seletivamente.
  - Valida com apt-get update.

- **restore-sources-from-backup.sh**:

  - Restaura o backup original, removendo qualquer proxy.
  - Preserva repositórios adicionados posteriormente.

### 5.3. Dispatcher do NetworkManager para Roaming

O script 99-apt-cacher-roaming (colocado em
/etc/NetworkManager/dispatcher.d/) executa aptcacher.sh em segundo plano
sempre que uma interface de rede (exceto loopback) é ativada (up),
garantindo que o proxy correto seja usado.

### 5.4. Exemplos de Configuração de Perfil

Cliente corporativo:

ENABLE_BACKUP=true  
ENABLE_FLATPAK_CACHE=true  
APTCACHER="192.168.1.10"  
CACHEPORT="3142"  
NFSSERVERER="192.168.1.10"

Ambiente doméstico (sem servidor):

ENABLE_FLATPAK_CACHE=false  
\# APTCACHER e CACHEPORT não definidos – fallback para gateway

## 6. Guia de Implantação para os Três Públicos‑Alvo

No número 11 do README do repositório são apresentados 2 modos rápidos
para testar a implantação.

### 6.1. Usuário Doméstico / Independente (Máquina Única)

**Objetivo:** Aplicar as otimizações em um único computador, sem
servidor externo.

**Pré‑requisitos:** Zorin OS (ou Ubuntu 20.04/22.04/24.04), acesso root,
internet.

Passo a passo:

1.  Clonar o repositório:

    git clone https://github.com/arthur-aida/zorin_corporate_configs.git
    /opt/zorin_configs  
    cd /opt/zorin_configs

2.  **Escolher um perfil** (doméstico é o mais adequado):

    sudo mkdir -p /etc/customization  
    sudo cp profiles/domestic.conf /etc/customization/active-profile.env

3.  **(Opcional) Configurar proxy local** – Se tiver um servidor
    APT‑Cacher‑NG na rede, edite o perfil com APTCACHER e CACHEPORT.
    Caso contrário, o fallback usará o gateway (pode não funcionar sem
    proxy).

4.  Executar a customização:

    sudo bash main.sh

    O processo pode levar de 30 minutos a 2 horas. Logs são gravados em
    /var/log/customization-persist/main.log.

5.  Pós‑instalação:

    - Reinicie o sistema.
    - Execute os atalhos do menu para instalar assinadores (Serpro,
      Certillion) ou Bonita Studio.
    - Execute **"Habilita Certificados GOV e Tokens"** para importar os
      certificados ICP no seu perfil.

6.  **Manutenção automática:** O cron executará atualizações, limpeza e
    reativação de impressoras.

### 6.2. Administrador de Sistemas (Implantação em Larga Escala)

**Objetivo:** Implantar a configuração padronizada em dezenas/centenas
de máquinas, utilizando servidor de cache.

**Arquitetura recomendada:** Servidor com APT‑Cacher‑NG, NFS e
repositório Flatpak OSTree; clientes na mesma rede.

Passo a passo (Servidor):

1.  **Preparar o servidor** (Zorin OS ou Ubuntu, com pelo menos 100 GB
    livres).

2.  Clonar e executar o script de configuração do servidor:

    git clone https://github.com/arthur-aida/zorin_corporate_configs.git
    /opt/zorin_configs  
    cd /opt/zorin_configs  
    sudo bash scripts/setup-server-KVM-nfs-acng.sh

    Este script instala todos os serviços, configura exportações NFS,
    firewall e cria o cache Flatpak inicial.

3.  Verificar os serviços:

    systemctl status apt-cacher-ng nfs-kernel-server libvirtd

    Ajuste /etc/exports conforme sua rede e recarregue com exportfs -ra.

4.  **(Opcional) Reconstruir o cache Flatpak** com aplicativos
    específicos:

    sudo scripts/setup-server-KVM-nfs-acng.sh --rebuild-flatpak

Passo a passo (Clientes):

1.  Em cada estação, clone o repositório ou disponibilize os scripts via
    NFS.

2.  Crie o arquivo de perfil com as variáveis do servidor:

    sudo mkdir -p /etc/customization  
    sudo tee /etc/customization/active-profile.env \<\<EOF  
    ENABLE_BACKUP=true  
    ENABLE_FLATPAK_CACHE=true  
    APTCACHER="192.168.1.10"  
    CACHEPORT="3142"  
    NFSSERVERER="192.168.1.10"  
    EOF

3.  Execute sudo bash main.sh. Com o cache, o tempo de instalação cai
    drasticamente.

4.  O roaming de rede é automático via dispatcher do NetworkManager.

5.  Monitore os logs e utilize o Proxmox Backup Client (se habilitado)
    para backups.

### 6.3. Desenvolvedor / Integrador (Extensão e Personalização)

**Objetivo:** Compreender, modificar e estender os scripts para atender
a novas necessidades ou integrar com outras ferramentas.

**Ambiente recomendado:** VM ou container com Zorin OS, editor de
código, git, ShellCheck.

Fluxo de trabalho:

1.  **Estudar a estrutura** – Leia o manual e os comentários nos
    scripts.

2.  **Personalizar um perfil** – Crie um novo arquivo em
    /profiles/meu_perfil.conf com variáveis customizadas.

3.  **Adicionar um novo módulo** – Crie modules/16-meu-modulo.sh
    seguindo o padrão:

    \#!/bin/bash  
    set -euo pipefail  
    source /etc/customization/utils/logging.sh  
    log_module_start "16-meu-modulo"  
    source /etc/customization/utils/common.sh  
    check_root  
    \# Sua lógica aqui  
    log_module_end "16-meu-modulo"

4.  **Testar em modo seco** – Use --dry-run nos scripts de conversão de
    fontes para simular alterações.

5.  **Criar novos atalhos .desktop** – Siga o exemplo do módulo 15
    (KVM).

6.  **Integrar com ferramentas de gerenciamento** – Os scripts podem ser
    chamados por Ansible, Puppet ou Chef.

7.  **Contribuir** – Após validação, envie um pull request para o
    repositório original.

Dicas de depuração:

- Ative set -x nos scripts para rastrear execução.
- Utilize bats (Bash Automated Testing System) para testes unitários.
- Mantenha a documentação atualizada com suas extensões.

## 7. Referência Rápida de Comandos e Funções

### 7.1. Funções Úteis do common.sh

|                                        |                                                   |
|----------------------------------------|---------------------------------------------------|
| download_with_cache \<url\> \<output\> | Baixa arquivo usando cache NFS ou internet.       |
| log_info, log_warning, log_error       | Mensagens de log com timestamp.                   |
| check_root                             | Verifica se o script é executado como root.       |
| wait_for_apt_unlock                    | Aguarda liberação do lock do dpkg (timeout 300s). |
| load_om_ips                            | Carrega variáveis de /etc/om.ips.                 |
| install_packages \<pkg1\> \<pkg2\> ... | Instala pacotes com apt install -y -qq.           |

### 7.2. Comandos Úteis para Administração

\# Verificar status dos serviços de cache  
systemctl status apt-cacher-ng nfs-kernel-server  
  
\# Recarregar exportações NFS  
exportfs -ra  
  
\# Reconstruir cache Flatpak manualmente no servidor  
sudo scripts/setup-server-KVM-nfs-acng.sh --rebuild-flatpak  
  
\# Restaurar fontes APT para o estado original (sem proxy)  
sudo scripts/restore-sources-from-backup.sh  
  
\# Converter fontes APT para proxy (modo seco)  
sudo scripts/convert-sources-to-proxy.sh --dry-run
--proxy=192.168.1.10:3142  
  
\# Ver logs do processo de customização  
tail -f /var/log/customization-persist/main.log  
  
\# Executar manutenção de cache Flatpak (prune)  
sudo /usr/local/bin/flatpak-cache-maintenance.sh  
  
\# Instalar KVM sob demanda (via atalho no menu ou)  
sudo /usr/local/bin/install-kvm.sh

## 8. Recursos Ativados Pós-Customização (Para o Usuário Final)

Após a execução bem‑sucedida do **main.sh**, a estação de trabalho
estará preparada com um conjunto de ferramentas e atalhos que tornam o
dia a dia do usuário mais produtivo, especialmente em ambientes
corporativos que exigem acesso a sistemas governamentais, assinatura
digital e virtualização. Esta seção descreve os principais recursos que
o usuário final encontrará no menu de aplicativos e como utilizá‑los.

### 8.1. Navegadores com Suporte a Java e Certificados

- **Firefox ESR (Extended Support Release):**  
  O script **firefox-manager.sh** instala a versão ESR do Firefox,
  configurada para abrir a página **https://hod.serpro.gov.br** por
  padrão. Este navegador é especialmente preparado para ambientes
  corporativos, com suporte a **Java Web
  Start** (via **hookjava1.8.sh**) e com a
  biblioteca **libnssckbi.so** substituída pelo **p11-kit-trust.so** do
  sistema, garantindo que os certificados ICP‑Brasil sejam reconhecidos
  automaticamente.

  **Atalho no menu:** **Mozilla-ESR HOD** (na categoria **Internet**).

- **Firefox Stable:**  
  Também é instalada a versão estável mais recente, com as mesmas
  configurações de certificados.

  **Atalho no menu:** **Navegador Firefox** (na categoria **Internet**).

- **Configuração de Certificados ICP‑Brasil:**  
  O script **import-icp-brasil.sh** (executado automaticamente na
  primeira inicialização do usuário) injeta as raízes ICP‑Brasil nos
  bancos NSS dos navegadores e no **p11-kit**. O usuário pode forçar a
  reimportação a qualquer momento através do atalho:  
  **Atalho no menu:** **Habilita Certificados GOV e Tokens** (na
  categoria **Sistema**). Este atalho também carrega os drivers de
  tokens PKCS#11.

### 8.2. Assinadores Digitais (SERPRO e Certillion)

Dois dos assinadores mais utilizados no Brasil estão disponíveis para
instalação sob demanda, respeitando as políticas de segurança (apenas
usuários comuns podem instalá‑los; administradores são bloqueados).

- **Assinador SERPRO:**  
  O atalho **Instala Assinador Serpro** baixa e executa o instalador
  oficial do SERPRO (versão 4.4.0 – AppImage). Após a instalação, o
  aplicativo fica disponível no menu como **Assinador Serpro**.  
  **Atalho no menu:** **Instala Assinador
  Serpro** (categoria **Sistema**).
- **Assinador Certillion:**  
  O atalho **Instala Assinador Certillion para usuários** dispara o
  instalador **.run** do Certillion, que é interativo. Após a conclusão,
  o atalho do Certillion é criado no desktop e no menu.  
  **Atalho no menu:** **Instala Assinador Certillion para
  usuários** (categoria **Sistema**).

### 8.3. Virtualização KVM (Instalação Sob Demanda)

O projeto não instala o KVM por padrão para não sobrecarregar máquinas
que não o utilizam. Em vez disso, disponibiliza um atalho para que o
próprio usuário (com privilégios de administrador) instale o ambiente de
virtualização quando necessário.

- **Atalho no menu:** **Instalador de Virtualização
  KVM** (categoria **Ferramentas do Sistema**).  
  Ao clicar, o script **install-kvm.sh** instala os
  pacotes **qemu-kvm**, **virt-manager**, **libvirt** e adiciona o
  usuário ao grupo **libvirt**. Após a instalação, é necessário
  reiniciar a sessão ou o sistema para que as permissões tenham efeito.

### 8.4. Drivers para Tokens Criptográficos (Safenet, G&D, DXSafe)

Os drivers para os principais modelos de tokens (Safenet 5100/5110, G&D
SafeSign, Dexon DXSafe) são instalados automaticamente durante a
customização. Além disso, o sistema registra os módulos PKCS#11
correspondentes.

- **Registro manual de drivers:** O atalho ****Habilita Certificados GOV
  e Tokens**** (mencionado em 8.1) também executa o
  script **CARREGAdriverTOKEN.sh**, que registra novamente os módulos
  PKCS#11 caso necessário.
- **Instalação do Token DXSafe (via wrapper):**  
  O atalho **Instalar Token DXSafe** (categoria **Sistema**) executa um
  wrapper que baixa o instalador do driver DXSafe (se não estiver em
  cache) e o executa com uma interface gráfica (zenity), guiando o
  usuário no processo.  
  **Atalho no menu:** **Instalar Token DXSafe**.

### 8.5. Ferramenta de Edição de Processos BPMN – Bonita Studio

Para equipes de desenvolvimento e automação de processos, o Bonita
Studio Community é disponibilizado.

- **Instalação e execução:** O atalho **Instala Bonita Studio para
  usuários** (categoria **Sistema**) baixa o tarball do Bonita Studio
  (versão 2024.3), extrai no diretório **~/BonitaStudioCommunity** e
  cria um atalho no menu. Após a primeira instalação, o atalho
  simplesmente inicia o aplicativo.  
  **Atalho no menu:** **Bonita Studio
  Community** (categoria **Desenvolvimento**).

### 8.6. Roaming de Rede e Adaptação Automática

Para usuários móveis (notebooks), o sistema se adapta automaticamente a
mudanças de rede:

- O script **99-apt-cacher-roaming**, acionado pelo NetworkManager,
  executa **aptcacher.sh** sempre que uma nova rede é conectada.
- Se o proxy corporativo (APT‑Cacher‑NG) estiver acessível, as fontes
  APT são convertidas para usá‑lo; caso contrário, as fontes são
  restauradas para acesso direto à internet.
- Tudo isso ocorre em segundo plano, sem intervenção do usuário.

### 8.7. Manutenção Automática (Cron)

O sistema agenda tarefas de manutenção que garantem a boa saúde da
estação:

- **Reativação de impressoras:** a cada 5 minutos, o
  script **/etc/enableprinter.sh** reativa impressoras que porventura
  tenham sido desabilitadas.
- **Atualizações e limpeza:** a cada 2 dias, às 12:20, o sistema
  executa **apt update && apt upgrade**, seguido de limpeza de pacotes e
  execução do **hookjava1.8.sh**. A cada 63 dias, é executada uma
  limpeza profunda de caches (**/etc/clean.sh**).
- **Trim em SSDs:** se o disco for SSD e a opção **discard** não estiver
  no fstab, o serviço **fstrim.timer** é ativado para execução
  periódica.

**Observação:** Todos os atalhos mencionados estão disponíveis no menu
de aplicativos do sistema, organizados por categoria (Internet, Sistema,
Desenvolvimento, etc.). Caso algum atalho não apareça imediatamente, o
usuário pode atualizar o banco de dados do menu com o
comando **update-desktop-database** ou simplesmente reiniciar a sessão.

## 9. Considerações Finais e Recomendações

- **Leia o README** e a documentação em **/Docs** para obter informações
  detalhadas sobre testes e casos de uso.
- **Teste em ambiente isolado** (VM) antes de implantar em produção.
- **Mantenha o cache NFS atualizado** – Execute periodicamente o rebuild
  do Flatpak no servidor para incluir novas versões de aplicativos.
- **Monitore os logs** – Em caso de falhas,
  verifique **/var/log/customization-persist/main.log** e os logs
  específicos dos serviços.
- **Personalize os perfis** conforme a necessidade do seu ambiente – as
  variáveis podem ser estendidas.
- **Contribua com o projeto** – Relate problemas, sugira melhorias e
  compartilhe suas adaptações.

O projeto **zorin_corporate_configs** é uma solução madura e bem
documentada que atende desde o usuário doméstico até grandes
corporações. Sua flexibilidade e abrangência o tornam uma ferramenta
valiosa para qualquer organização que busca eficiência, segurança e
padronização em seu parque de máquinas Linux.
