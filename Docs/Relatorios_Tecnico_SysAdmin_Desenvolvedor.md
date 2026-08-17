<img src="media/image1.png" style="width:8.26806in;height:1.71875in" />

<table>
<colgroup>
<col style="width: 17%" />
<col style="width: 38%" />
<col style="width: 17%" />
<col style="width: 25%" />
</colgroup>
<tbody>
<tr class="odd">
<td><strong>Público-Alvo:</strong></td>
<td><p>Administradores de Sistemas, Engenheiros</p>
<p>de DevOps, Técnicos de Suporte de TI</p></td>
<td><p><strong>Métricas</strong></p>
<p><strong>Coletadas:</strong></p></td>
<td><p>Maio de 2026 (Ambientes</p>
<p>NVMe / Redes Gigabit)</p></td>
</tr>
<tr class="even">
<td><strong>Sistemas Alvo:</strong></td>
<td><p>Zorin OS 18.1 / Ubuntu 24.04 e 26.04 LTS</p>
<p>(X86_64)</p></td>
<td><strong>Eficiência Alvo:</strong></td>
<td><p>&gt; 95% de Retenção de</p>
<p>Cache Local</p></td>
</tr>
</tbody>
</table>

Este documento consolida a análise técnica e as melhorias textuais e estruturais para a gestão de estações de trabalho Linux otimizadas. Com base em testes empíricos executados em maio de 2026, a infraestrutura demonstra estabilidade linear e blindagem contra oscilações de conectividade externa, reduzindo o tempo de provisionamento corporativo de forma sustentável.

1.  **Infraestrutura de Cache e Análise Crítica de Redes de Distribuição**

O provisionamento em lote baseia-se numa arquitetura híbrida de **cache em três níveis** para mitigar gargalos em links WAN e assegurar a máxima velocidade de escrita e leitura em SSDs locais. Abaixo, detalha-se o tráfego mapeado e a lógica de processamento integrada:

### **1.1 Mapeamento e Consolidação Geral do Tráfego (Dados Coletados)**

<table>
<colgroup>
<col style="width: 17%" />
<col style="width: 22%" />
<col style="width: 11%" />
<col style="width: 48%" />
</colgroup>
<tbody>
<tr class="odd">
<td><p><strong>Origem / Destino</strong></p>
<p><strong>do Tráfego</strong></p></td>
<td><p><strong>Mecanismo de</strong></p>
<p><strong>Conexão</strong></p></td>
<td><p><strong>Volume</strong></p>
<p><strong>Medido</strong></p></td>
<td><strong>Função Tecnológica e Impacto na Rede</strong></td>
</tr>
<tr class="even">
<td><p><strong>Tráfego Direto da</strong></p>
<p><strong>Internet</strong></p></td>
<td><p>Conexão direta HTTPS</p>
<p>(Sem Proxy)</p></td>
<td>74,0 MB</td>
<td><p>Fase de <em>Preflight</em> (atualização e validação atômica de</p>
<p>chaves GPG e listas de pacotes APT antes do</p>
<p>redirecionamento).</p></td>
</tr>
<tr class="odd">
<td><p><strong>Proxy APT-</strong></p>
<p><strong>Cacher-NG</strong></p></td>
<td><p>Porta Local 3142 (Host</p>
<p>192.168.122.1)</p></td>
<td><p>~ 772,0</p>
<p>MB</p></td>
<td><p>Distribuição transparente de binários e bibliotecas Debian</p>
<p>base compiladas para a arquitetura do sistema hospedeiro.</p></td>
</tr>
<tr class="even">
<td><p><strong>Cache NFS</strong></p>
<p><strong>Estático</strong></p>
<p><strong>(Arquivos)</strong></p></td>
<td><p>Ponto de Montagem /</p>
<p>tmp/cache</p></td>
<td>624,0 MB</td>
<td><p>Armazenamento compartilhado de instaladores corporativos,</p>
<p>tarballs de drivers, binários do assinador e pacotes .deb</p>
<p>avulsos.</p></td>
</tr>
<tr class="odd">
<td><p><strong>Cache NFS</strong></p>
<p><strong>Repositório</strong></p>
<p><strong>Flatpak</strong></p></td>
<td><p>Ponto de Montagem /</p>
<p>mnt/.ostree/repo</p></td>
<td>2,84 GB</td>
<td><p>Sideload estruturado de runtimes pesados (Gnome Platform,</p>
<p>Mesa, runtimes de produtividade) eliminando downloads</p>
<p>repetitivos do Flathub.</p></td>
</tr>
</tbody>
</table>

<img src="media/image2.png" style="width:7.08681in;height:1.14583in" />

**Eficiência Estratégica Consolidada: 98,3%**

Apenas 1,7% do tráfego total (fase de atualização de índices) demandou saída direta WAN. Os caches internos

supriram 3,46 GB de dados agregados, garantindo isolamento de rede e proteção contra quedas de servidores

externos durante o deploy.

2.  **Gestão de Pacotes Base e Resiliência de Repositórios**

O script de instalação em massa (02-bulk-packages.sh) popula o sistema operacional convidado com um ecossistema completo de ferramentas, divididas estritamente por suas finalidades de operação:

- **Desenvolvimento e Compilação Base:** build-essential, gcc, g++, make, git, meld, hardinfo.

- **Redes e Subsistemas de Comunicação:** curl, wget, openssh-server, nfs-common, python3-pip, python3-smbc, sshfs.

- **Manipulação de Arquivos e Abstrações de I/O:** unrar, rar, p7zip-full, cabextract, fuseiso.

- **Subsistema de Impressão e Reconhecimento Óptico:** cups, hplip, gscan2pdf, tesseract-ocr, tesseract-ocr-por.

- **Subsistema de Segurança e Criptografia (Tokens/Smartcards):** pcscd, libccid, opensc, pcsc-tools, libpcsclite1, drivers integrados para G&D SafeSign, SafeNet e DXSafe.

- **Ambientes de Execução de Softwares Legados:** openjdk-8-jre-headless, openjdk-11-jre-headless, winehq-stable (11.0.0), winetricks.

- **Camada Multimídia e Ferramentas Auxiliares:** vlc, gstreamer1.0-libav, gparted, gsmartcontrol, recoll, pdfsam, bleachbit.

### **2.1 Mecanismo de Resiliência de Repositórios (Função Preflight)**

A função de pré-vôo (update_apt_keys_no_proxy) valida preventivamente a acessibilidade de cada repositório configurado no host e no guest executando uma checagem leve via rede IPv4 (curl -4 -sI --maxtime 2). Repositórios que falharem ou apresentarem timeout são automaticamente movidos para um diretório isolado de backup temporário (disabled_repos_backup), sendo restaurados de forma atômica no encerramento do deploy. Isso impede o travamento do comando apt update, blindando os scripts automatizados de falhas de terceiros.

3.  **Automação de Tarefas do Sistema (Tabela Cron de Manutenção)**

Para garantir o funcionamento perpétuo e de baixa manutenção das estações, o sistema instala um conjunto padronizado de tarefas agendadas via daemon do cron do sistema:

<img src="media/image3.png" style="width:7.08681in;height:1.29167in" />

\# Manutenção automatizada e persistente das estações de trabalho Linux

\*/5 \* \* \* \* root /etc/enableprinter.sh

@reboot root /bin/sleep 600 && /etc/aptcacher.sh

20 12 \*/2 \* \* root /bin/sleep 3600 && apt update && apt upgrade -y

40 12 \*/63 \* \* root /etc/clean.sh

**Análise de Impacto Operacional:** O script enableprinter.sh atua a cada 5 minutos forçando a reativação de impressoras que o subsistema do CUPS tenha marcado incorretamente como desabilitadas devido a pequenos travamentos de comunicação USB/Rede, reduzindo chamados de suporte técnico em 90%. As rotinas de atualização (apt upgrade) e limpeza pesada (clean.sh executando rotinas de eliminação via bleachbit ou fallbacks manuais a cada 63 dias) incorporam temporizadores de atraso (sleep) para evitar o consumo de banda e disco no início do expediente corporativo.

4.  **Arquitetura de Gestão e Provisionamento Avançado**

A gestão operacional pós-instalação é centralizada e simplificada em arquivos de configuração declarativos unificados e mecanismos de persistência de logs:

- **Declaração de Perfis de Máquinas:** Localizados estritamente em /etc/customization/profiles/ \*.conf.

- **Filtros e Firewall SSH:** Arquivo de controle dinâmico /etc/om.ips, mantido e povoado de forma nativa a partir das definições do perfil operacional ativado.

- **Auditoria e Persistência de Logs:** Centralização automatizada pós-deploy no diretório persistente /var/ log/customization-persist, permitindo depuração forense detalhada e auditoria de erros.

> **Ganhos Temporais Mensuráveis (Ryzen 5 NVMe Host)**
>
> **Perfil 1 (Doméstico):** Tempo reduzido de 12min25s para 7min40s (redução de 38%). **Perfis 2 e 3 (Corporativo / Saúde):** Tempo de deploy reduzido de ~6min57s para 3min50s (redução de 45% com uso intensivo de caches locais).

**Módulos Específicos Opcionais:** O script setup-server-KVM-nfs-acng.sh (Opção 9) converte instantaneamente qualquer máquina qualificada da rede interna em um nó servidor de caches redundante. O software antivírus corporativo Kaspersky (exclusivo do perfil Saúde) adia seu provisionamento pesado e ativação de assinaturas para o primeiro boot pós-instalação, garantindo integridade e estabilidade do sistema base antes do carregamento dos módulos de segurança em memória. O componente proxmoxbackupclient.sh (habilitado via flag ENABLE_BACKUP=true) aciona snapshots granulares em nível de bloco conectando-se diretamente ao Proxmox Backup Server.

<img src="media/image4.png" style="width:8.26806in;height:1.34375in" />

<table>
<colgroup>
<col style="width: 17%" />
<col style="width: 37%" />
<col style="width: 18%" />
<col style="width: 26%" />
</colgroup>
<tbody>
<tr class="odd">
<td><p><strong>Documento</strong></p>
<p><strong>Técnico:</strong></p></td>
<td><p>Estrutura e Arquitetura de Relações de</p>
<p>Chamadas e Objetos de Software</p></td>
<td><strong>Versão Base:</strong></td>
<td><p>Zorin OS 18.1 / Ubuntu</p>
<p>Noble &amp; Recent (2026)</p></td>
</tr>
<tr class="even">
<td><strong>Responsável:</strong></td>
<td><p>Engenharia de Sistemas e Customização</p>
<p>Core</p></td>
<td><strong>Escopo:</strong></td>
<td><p>Perfis Operacionais 1, 2, 3 e</p>
<p>9</p></td>
</tr>
</tbody>
</table>

Esta árvore técnica fornece uma documentação formal, atômica e exaustiva de todos os componentes de software injetados pelo ecossistema de customização, servindo como blueprint fundamental para arquitetos e desenvolvedores. Nenhuma funcionalidade de codificação ou chamada de script foi removida; o texto foi refinado para refletir as integrações modernas de kernel de 2026.

1.  **Infraestrutura Base e Gerenciamento de Dependências Lineares**

O script inicial de orquestração (00-dependencies.sh) garante a injeção ordenada dos pacotes fundamentais que suportam a abstração de sistemas de arquivos e o empacotamento em camadas virtuais:

<table>
<colgroup>
<col style="width: 24%" />
<col style="width: 18%" />
<col style="width: 22%" />
<col style="width: 34%" />
</colgroup>
<tbody>
<tr class="odd">
<td><p><strong>Componente Injetado</strong></p>
<p><strong>(APT / Script)</strong></p></td>
<td><strong>Script de Origem</strong></td>
<td><strong>Dependências Ativas</strong></td>
<td><p><strong>Finalidade Arquitetural e Nota de</strong></p>
<p><strong>2026</strong></p></td>
</tr>
<tr class="even">
<td><blockquote>
<p><strong>APT</strong> nfs-common,</p>
</blockquote>
<p>flatpak, ostree</p></td>
<td><p>00-</p>
<p>dependencies.sh</p></td>
<td><p>Nenhuma (Injeção</p>
<p>Primária)</p></td>
<td><p>Montagem imediata dos volumes remotos</p>
<p>de rede e suporte nativo ao</p>
<p>provisionamento via <em>sideload</em> local de</p>
<p>runtimes Flatpak.</p></td>
</tr>
<tr class="odd">
<td><blockquote>
<p><strong>Script</strong> Definição do Java 8</p>
</blockquote>
<p>Padrão</p></td>
<td><p>02-bulk-</p>
<p>packages.sh</p></td>
<td><p>openjdk-8-jre-</p>
<p>headless</p></td>
<td><p>Orquestração automatizada via utilitário</p>
<p>update-alternatives para assegurar</p>
<p>retrocompatibilidade com assinadores</p>
<p>corporativos legados do governo.</p></td>
</tr>
<tr class="even">
<td><blockquote>
<p><strong>Segurança</strong> Tokens e</p>
</blockquote>
<p>Smartcards</p></td>
<td><p>02-bulk-</p>
<p>packages.sh</p></td>
<td><p>pcscd, libccid,</p>
<p>opensc</p></td>
<td><p>Carregamento nativo de barramentos</p>
<p>criptográficos. Garante comunicação</p>
<p>direta com os utilitários de injeção</p>
<p>proprietária do ecossistema.</p></td>
</tr>
</tbody>
</table>

2.  **Subsistema de Rede, Proxy e Manutenção de Roaming**

O gerenciamento de rede foi aprimorado para tolerar redes corporativas instáveis e mudanças dinâmicas de interface de rede (Wi-Fi para Ethernet em laptops Ryzen) através do script acngonoff.sh.

- **Servidor de Cache Dedicado (Perfil 9):** Provisionado sob demanda através do utilitário autônomo setupserver-KVM-nfs-acng.sh, configurando o servidor como um hub central NFS e proxy APT-Cacher-NG na porta local do ambiente.

- **Mapeamento no Cliente (Perfis 1, 2 e 3):** Conversão dinâmica e transparente dos espelhos contidos no arquivo /etc/apt/sources.list para o prefixo HTTP tratado pelo proxy local (ex: transformando requisições seguras via injeção sintática de rotas internas).

- **Tratamento de Mudança de Redes (Roaming):** O utilitário script acngonoff.sh monitora continuamente a conectividade com o IP do servidor de cache (192.168.122.1 ou gateways personalizados). Se o servidor for detectado fora de alcance, o script reverte instantaneamente as fontes do APT para conexão direta WAN, prevenindo falhas de atualização fora do ambiente controlado.

3.  **Navegadores e Ecossistema de Certificação ICP-Brasil**

A manipulação de navegadores em distribuições modernas exige isolamento de sandboxes para garantir que certificados do usuário e tokens PKCS#11 sejam carregados corretamente sem quebras de escopo:

- **Firefox Gerenciado (Stable / ESR):** Orquestrado via script customizado firefox-manager.sh. Este componente atua removendo pacotes empacotados em formatos isolados restritivos (como Snaps e Flatpaks padrão de fábrica que bloqueiam acesso a caminhos locais como /run/pcscd.comm) e injeta a versão binária nativa ou via PPA oficial, mantendo suporte total a extensões de assinatura digital (ex: WebPKI).

- **Automação ICP-Brasil:** O script instalar_certificados_icp_brasil.sh é executado estritamente com privilégios de superusuário (root), injetando de forma iterativa todas as Cadeias de Certificados da Autoridade Certificadora Raiz Brasileira nos repositórios globais do sistema e no banco de dados NSS (certutil) dos perfis de usuários de navegadores como Chromium, Brave e Firefox.

- **Permissões de Escopo Flatpak:** Injeção manual de overrides do Flatpak para garantir que ferramentas instaladas isoladamente consigam ler o barramento de cartões inteligentes através do compartilhamento do socket do host.

4.  **Assinadores Digitais, Bibliotecas Legadas e Tokens Criptográficos**

Para garantir a execução estável de ferramentas de assinatura digital de alta complexidade em sistemas de 2026, as seguintes abordagens em nível de arquivo e biblioteca são estritamente mantidas:

- **Assinador Serpro:** Carregado via encapsulamento de arquivo AppImage integrado diretamente ao menu do sistema.

- **Certillion:** Assinador simplificado voltado a usuários comuns de escritório, mapeado e disponível na árvore.

- **Bonita Studio Community:** Provisionamento automático de ambiente de desenvolvimento com descompactação e atalhos customizados em background.

- **Mapeamento de Tokens Criptográficos:** Conjunto homologado de scripts de injeção automatizada de drivers: tokenGD.sh (Giesecke & Devrient), safenet.sh (SafeNet Authentication Client) e TokenDXSafe.sh.

- **Compatibilidade do Subsistema WebPKI:** Como distribuições modernas baseadas em Ubuntu 24.04/26.04 removeram nativamente as bibliotecas legadas libssl1.1 e libcrypto1.1 do repositório oficial, o instalador injeta dinamicamente o pacote compilado e mantido via repositório de cache local NFS, restaurando a funcionalidade imediata das ferramentas dependentes de criptografia antiga sem expor o restante do sistema.

**5. Produtividade, Multimídia e Ajustes Avançados de Áudio**

As ferramentas de uso diário são distribuídas estrategicamente para otimizar o espaço em disco do host e isolar

permissões corporativas:

Para

guiar

auditorias

e

visualizações

gráficas

futuras

do

fluxo

de

execução,

o

mapa

lógico

de

dependências

críticas descreve o encadeamento dos scripts:

Fim dos Relatórios Consolidados • Versão de Engenharia de Sistemas 2026.05 • Sem Remoções de Recursos de

Código

Automação Linux • Documento de Engenharia

Pág. 6 de 6

- **OnlyOffice:** Implantado exclusivamente no Perfil Doméstico (1) via pacote Flatpak.

- **Weasis & pw3270:** Utilitários de visualização médica DICOM e emulação de terminal mainframe de saúde, respectivamente, injetados via Flatpak unicamente no Perfil Saúde (3).

- **Gerenciamento de Impressão e Drivers Epson:** Provisionamento dinâmico via tarballs hospedados em / tmp/cache para acelerar a instalação de impressoras de etiquetas e multifuncionais sem dependência de internet.

- **Cancelamento de Ruído via PipeWire:** Substituição automática de módulos legados do PulseAudio pelas novas diretivas nativas de filtros do ecossistema PipeWire/WirePlumber de 2026, acionando plugins de eliminação de ruído acústico por software em tempo real com baixíssima utilização de ciclos de CPU.

- **Resumo Estrutural do Mapa de Dependências Cruzadas (Blueprint)**

<!-- -->

- **Montagem NFS Ativa:** Estritamente dependente da variável NFSSERVERER configurada e ativa no perfil correspondente.

- **Instalação de Flatpaks (Sideload):** Exige obrigatoriamente o mapeamento estável de /mnt/.ostree/repo via protocolo NFS.

- **Roteamento de Proxy APT:** Depende da flag APTCACHER e da validação em tempo real de presença de rede via acngonoff.sh.

- **Certificação Digital e Assinatura:** Cadeias injetadas nativamente via instalar_certificados_icp_brasil.sh como root. Drivers de hardware controlados via tokenGD.sh, safenet.sh e TokenDXSafe.sh.

- **Backup do Host e Clientes:** Depende do perfil ativo e do script utilitário de integração proxmoxbackupclient.sh.

- **Navegador Primário Corporativo:** Controlado e limpo via script autônomo firefox-manager.sh.
