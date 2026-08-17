## RELATÓRIO PARA O SYSADMIN

**Público‑alvo:** Administradores de sistemas operacionais, técnicos de TI, responsáveis pela gestão de estações de trabalho.

*Os números de tráfego e tempo de instalação foram medidos em maio de 2026. Com a evolução dos pacotes e versões, os valores absolutos podem variar, mas a eficiência relativa do cache (superior a 95%) e os ganhos percentuais de tempo (38–45%) se mantêm estáveis.*

### 1.1 Recursos embutidos no sistema preparatório da customização

#### 1.1.1 Infraestrutura de cache e otimização de rede

| Componente                             | Funcionalidade                                                                                               | Benefício para o SysAdmin                                                                                |
|----------------------------------------|--------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| **APT‑Cacher‑NG**                      | Proxy transparente para pacotes Debian (porta 3142). Suporte a HTTPS via prefixo HTTPS///.                   | Redução de tráfego de internet em redes corporativas. Conversão automática e reversível das fontes.      |
| **Cache NFS compartilhado**            | Diretórios /mnt (cache Flatpak) e /tmp/cache (repositório administrativo) montados a partir do servidor NFS. | Permite que múltiplas estações compartilhem arquivos baixados (drivers, instaladores, runtimes Flatpak). |
| **Função download_with_cache**         | Verifica primeiro em /tmp/cache (NFS) antes de baixar da internet.                                           | Economia de banda e aceleração de instalações subsequentes.                                              |
| **Backup e restauração de fontes APT** | Backup original (TAR) das listas de repositórios. Restauração atômica e limpa.                               | Garante reversão segura mesmo após testes de rede.                                                       |

O resultado abaixo é decorrente da análise realizada sobre um conjunto de logs da customização. Foram identificadas três origens principais de dados, discriminadas abaixo por IP, porta e volume transferido.

### 1.1.1.1. Tráfego Direto da Internet (sem proxy)

- Preflight (atualização de listas APT): **74,0 MB**  
  > (repositórios Ubuntu, Zorin, Brave etc., acessados diretamente antes da ativação do proxy)

### 1.1.1.2. Proxy APT‑Cacher‑NG (192.168.122.1:3142)

- Todo o tráfego **APT** pós‑conversão para HTTP (Mapeamento Direto) via proxy: **≈ 772 MB**

### 1.1.1.3. Cache NFS (192.168.3.3:2049)

- Repositório Flatpak (/mnt/.ostree/repo) via NFS **≈ 2,84 GB**

- Cache Administrativo de arquivos estáticos (/tmp/cache) via NFS **≈ 624 MB**

### 1.1.1.4. Consolidação Geral

| Origem                 | IP:Porta           | Volume                   | % do Total |
|------------------------|--------------------|--------------------------|------------|
| Internet direta        | diversos           | 74 MB                    | 1,7 %      |
| APT‑Cacher‑NG          | 192.168.122.1:3142 | 772 MB                   | 18,0 %     |
| NFS-flatpak            | 192.168.3.3:2049   | 2.844 MB                 | 66,3 %     |
| NFS-arquivos estáticos | 192.168.3.3:2049   | 624 MB                   | 14,5 %     |
| **Total geral**        |                    | **≈ 4.314 MB (4,31 GB)** | 100 %      |

### 1.1.1.5. Eficiência da Estratégia de Cache

- **98,3 % do volume total** foi suprido por caches internos (APT‑Cacher‑NG + NFS), eliminando quase que completamente o tráfego de saída para a Internet.

- Apenas a atualização inicial das listas de pacotes (74 MB) precisou acessar diretamente as URLs públicas.

- O APT‑Cacher‑NG atendeu 772 MB de pacotes APT; os caches NFS forneceram 3,4 GB (NFS-flatpak + NFS-arquivos estáticos) entre runtimes Flatpak e instaladores administrativos, comprovando a viabilidade do modelo para implantações em escala.

#### 1.1.2 Gestão de pacotes e serviços essenciais

**Pacotes instalados em massa** – o administrador tem à disposição uma base completa:

- **Desenvolvimento:** build-essential, gcc, g++, make, git, meld, hardinfo

- **Redes:** curl, wget, openssh-server, nfs-common, python3-pip, python3-smbc

- **Arquivos/compressão:** unrar, rar, p7zip-full, cabextract, fuseiso

- **Impressão/digitalização:** cups, hplip, gscan2pdf, tesseract-ocr

- **Tokens e smartcards:** pcscd, libccid, opensc, e drivers proprietários (G&D SafeSign, Safenet, DXSafe)

- **Java/Wine:** openjdk-8-jre-headless, winehq-stable (11.0.0), winetricks

- **Multimídia:** vlc, gstreamer1.0-libav

- **Utilitários:** gparted, gsmartcontrol, recoll, pdfsam, bleachbit

**Serviços configurados automaticamente:**

| Serviço       | Ação                                                                             | Verificação nos logs                                                 |
|---------------|----------------------------------------------------------------------------------|----------------------------------------------------------------------|
| ssh (OpenSSH) | Habilitado e iniciado; regras hosts.allow/hosts.deny aplicadas.                  | 14-security.log mostra ✅ Serviço SSH habilitado e em execução.      |
| pcscd         | Serviço de smartcard ativado via socket.                                         | 00-dependencies.log e 05-tokens.log confirmam instalação e ativação. |
| smartd        | Monitoramento S.M.A.R.T. ativado; fstrim.timer ativado se SSD detectado.         | 02-bulk-packages.log configura smartmontools e smartd.               |
| cups          | Configurado com Browsing Off; enableprinter.sh reativa impressoras a cada 5 min. | 12-desktop-config.log aplica as configurações.                       |

**Tarefas agendadas (cron) supervisionáveis:**

\*/5 \* \* \* \* root /etc/enableprinter.sh

@reboot root /bin/sleep 600 && /etc/aptcacher.sh

20 12 \*/2 \* \* root /bin/sleep 3600 && apt update && apt upgrade -y

40 12 \*/63 \* \* root /etc/clean.sh

**Resiliência de repositórios de software:**  
O preflight (update_apt_keys_no_proxy) testa cada repositório com curl -4 -sI --max-time 2. Repositórios inacessíveis são **desabilitados temporariamente** (backup em disabled_repos_backup) e restaurados ao final. Isso evita falhas de apt update que poderiam interromper a customização.

#### 1.1.3 Otimizações específicas para economia de I/O e energia (base em laptop AMD Ryzen 5 3500U com NVMe)

| Estratégia                                         | Implementação                                                            | Benefício medido nos logs                               |
|----------------------------------------------------|--------------------------------------------------------------------------|---------------------------------------------------------|
| **Uso de tmpfs para logs**                         | Montagem de 50 MB em /var/log/customization.                             | Evita escrita constante no NVMe durante a customização. |
| **Instalação massiva de pacotes**                  | Um único apt install com 446 pacotes (perfil 2).                         | Redução do número de operações de escrita.              |
| **Paralelismo de módulos sem APT**                 | Módulos como 03-certificates, 04-browsers executados em background.      | Aproveitamento total da CPU, sem aumentar I/O.          |
| **Nice/ionice em operações pesadas**               | flatpak create-usb com nice -n 19 ionice -c 3.                           | Impacto mínimo em tarefas interativas.                  |
| **fstrim.timer ativado para SSD**                  | Detecta se o dispositivo de root é SSD (/sys/block/\*/queue/rotational). | Prolonga a vida útil do NVMe e mantém o desempenho.     |
| **Cache Flatpak via sideload**                     | Instalação a partir de /mnt/.ostree/repo (NFS).                          | Zero download na instalação dos pacotes flatpak         |
| **Desativação temporária de serviços automáticos** | packagekit, unattended-upgrades, apt-daily.timer são parados.            | Evita contenção de lock do dpkg e I/O concorrente.      |

### 1.2 Experiência do administrador na gestão pós‑instalação

- **Arquivos de configuração centralizados:**

  - Perfis em /etc/customization/profiles/\*.conf

  - Regras de acesso SSH via /etc/om.ips (gerado automaticamente pelo perfil)

- **Logs persistentes:**  
  > Após cada execução, os logs são copiados para /var/log/customization-persist. Isso facilita auditoria e debug.

- **Recursos instaláveis pelo administrador (opcionais):**

  - **Servidor de cache (opção 9):** o script setup-server-KVM-nfs-acng.sh configura uma estação como servidor NFS + APT‑Cacher‑NG + Flatpak cache.

  - **Kaspersky (perfil saúde):** a instalação é adiada para o próximo boot quando a estação estiver conectividade com o servidor de atualização centralizada, garantindo que o sistema esteja pronto antes da ativação do antivírus.

  - **Proxmox Backup Client:** ativado via ENABLE_BACKUP=true. Integração com **Proxmox Backup Server** para backup centralizado.

- **Resiliência e manutenção automática minimizada:**

  - **Reabilitação automática de impressoras (enableprinter.sh)** – a cada 5 minutos, verifica impressoras desabilitadas e as reativa.

  - **Atualizações intervaladas (2/2 dias)** – o cron executa apt upgrade com atraso de 1 hora para não coincidir com inicio de horário comercial.

  - **Limpeza automática (clean.sh)** – a cada 63 dias, executa bleachbit ou fallback manual, removendo caches de navegadores e lixo do sistema.

**Conclusão para o administrador:** O sistema customizado oferece **estabilidade, baixa manutenção e alta eficiência de I/O**, permitindo ao SysAdmin focar em tarefas de maior valor, como a integração com servidores de backup e a personalização de perfis.

Observação: o Kaspersky é exclusivo do perfil Saúde e o Proxmox Backup Client depende da variável ENABLE_BACKUP=true.

## 2. RELATÓRIO DE ARQUITETURA E DESENVOLVIMENTO

**Público‑alvo:** Desenvolvedores de sistemas, engenheiros de automação e técnicos que desejam entender ou estender a solução.

### 2.1 Estrutura da árvore de customização

/etc/customization/

├── main.sh

├── utils/

│ ├── common.sh

│ ├── logging.sh

│ └── fix-sources-list.sh

├── modules/

├── scripts/

├── original_scripts/

└── profiles/

### 2.2 Funções de cada script – módulo a módulo

| Módulo                     | Função principal                                                                          | Estratégia de robustez                                                                     |
|----------------------------|-------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------|
| **00‑dependencies**        | Instala nfs-common, flatpak, ostree.                                                      | Usa install_packages com wait_for_apt_unlock.                                              |
| **01‑sync‑scripts**        | Cria links simbólicos dos scripts originais; copia om.ips e scripts auxiliares.           | Mapeamento de destinos especiais; exclusão de TokenDXSafe.sh (tratado separadamente).      |
| **02‑bulk‑packages**       | Instalação massiva de pacotes APT (446 pacotes).                                          | Adiciona i386; lista de pacotes única; configura Java 8 como padrão.                       |
| **03‑certificates**        | Instala certificados ICP-Brasil no sistema (/etc/ssl/certs).                              | Verifica SHA do ZIP antes de extrair; usa update-ca-certificates.                          |
| **04‑browsers**            | Instala Java JRE 1.8 e navegadores Firefox (stable e ESR).                                | download_with_cache para tarballs; link dinâmico de certificados (p11-kit-trust.so).       |
| **05‑tokens**              | Executa tokenGD.sh e safenet.sh; registra módulos PKCS#11.                                | Isola instaladores; chama CARREGAdriverTOKEN.sh que percorre lista de módulos.             |
| **06‑icp‑user‑certs**      | Configura script de autostart para usuários (importação de certificados).                 | Copia arquivos para /etc/skel e para homes existentes.                                     |
| **07‑kaspersky**           | Prepara Kaspersky para perfil saúde (copia tarball, cria serviço systemd).                | Instalação adiada para o boot (evita conflitos de rede).                                   |
| **08‑wine**                | Instala WineHQ stable (11.0.0).                                                           | Detecta cache e converte fontes APT para HTTP; aplica hold.                                |
| **09‑signers**             | Instala libssl1.1 e WebPKI.                                                               | Busca no cache assinadores adicionais (pje-office).                                        |
| **10‑backup**              | Instala proxmox-backup-client se ENABLE_BACKUP=true.                                      | Adiciona repositório Proxmox; instala via cache.                                           |
| **11‑flatpak‑cache**       | Instala Flatpak via sideload do cache NFS ou direto.                                      | Sincroniza pacotes para o NFS com nice/ionice; manutenção diária com lock atômico (mkdir). |
| **12‑desktop‑config**      | Configura desktop: BleachBit, drivers Epson, dicionários, cancelamento de ruído, atalhos. | Usa cache NFS para os .debs e .zips; fallback para download direto.                        |
| **13‑desktop‑config‑user** | Cria script setup-icp-tokens.sh e atalho de menu.                                         | Atualiza atalhos de usuário com /usr/local/bin/setup-icp-tokens.sh.                        |
| **14‑security**            | Configura enableprinter.sh, smartmontools, regras SSH, cron.                              | Lê variáveis hostsallow\* do perfil e aplica em hosts.allow/hosts.deny.                    |
| **15‑kvm‑menu**            | Cria atalho no menu para instalação do KVM.                                               | Copia install-kvm.sh e .desktop para /usr/share/applications.                              |

### 2.3 Estratégias de funcionamento e modularidade

1.  **Orquestração por main.sh:**

    - Carrega perfil → executa preflight → sincroniza scripts → verifica cache → instala dependências → monta NFS → executa módulos em paralelo ou sequencial conforme necessidade.

    - **Paralelismo inteligente:** módulos sem APT (03,04,06,07) rodam em background simultaneamente. Módulos com APT (05,08,09,10) rodam sequencialmente para evitar lock.

    - Ao final, restaura fontes APT (se convertidas ao formato do apt-cacher-ng) e reativa serviços automáticos.

2.  **Testes de robustez embutidos:**

    - **Lock de execução:** cada script que pode ser chamado manualmente possui arquivo de lock com trap.

    - **Verificação de conectividade de repositórios (update_apt_keys_no_proxy):** evita que apt update falhe devido a mirrors inativos.

    - **Validação de hash (certificados ICP):** apenas extrai o ZIP se o SHA256 for diferente.

    - **Fallbacks para sem cache:** todo download passa por download_with_cache; se o cache não estiver disponível, baixa da internet e armazena no cache local /tmp/cache/ que é um filesystem em RAM.

3.  **Modularidade e extensibilidade:**

    - Novos módulos podem ser adicionados em modules/ seguindo a numeração.

    - O administrador pode criar perfis personalizados copiando e editando os arquivos .conf.

    - A opção 9 (setup-server-KVM-nfs-acng.sh) é um script independente que configura um servidor de cache, demonstrando o poder e a capacidade de expansão da solução.

### 2.4 Justificativa da escolha das distribuições base

**Zorin OS 18.1, Linux Mint 22.x e Ubuntu 24.04** foram escolhidas por:

- **Maturidade de drivers:** Estas versões são LTS (Ubuntu 24.04) ou baseadas em LTS. Drivers para tokens (OpenSC, PC/SC), dispositivos de hardware e impressoras estão estáveis e amplamente testados.

- **Suporte a longo prazo:** Ubuntu 24.04 tem suporte até 2029; Zorin 18.1 e Mint 22 acompanham esse ciclo.

- **Desvio do Ubuntu 26.04:** Versões muito recentes (26.04) frequentemente quebram compatibilidade com drivers de tokens proprietários (ex.: Safenet, G&D SafeSign). Também podem introduzir alterações no sistema de inicialização ou nas bibliotecas que afetam aplicações corporativas.

- **Compatibilidade com a opção 9:** O script setup-server-KVM-nfs-acng.sh foi testado nessas bases e configura corretamente APT‑Cacher‑NG, NFS e Flatpak.

**Exemplo prático no ambiente de laboratório (laptop AMD Ryzen 5 3500U):**

- O hardware tem suporte completo no kernel 6.8 (Ubuntu 24.04). Todos os drivers de áudio, rede e aceleração gráfica funcionam sem ajustes.

- A instalação do conjunto de scripts em uma distribuição estável garante que não haverá surpresas com drivers de token ou com o funcionamento do cache NFS.

### 2.5 A opção 9 – Camada extra para customização específica do desenvolvedor/customizador

O script setup-server-KVM-nfs-acng.sh transforma uma estação (pode ser um laptop ou desktop) em um **servidor de cache e virtualização KVM**. Ele:

- Instala apt-cacher-ng, nfs-kernel-server, flatpak, qemu-kvm, libvirt.

- Cria/monta /partimag e compartilha via NFS (exporta para a rede KVM).

- Configura o APT‑Cacher‑NG com suporte a HTTPS (prefixo HTTPS///).

- Inicializa um repositório Flatpak OSTree em /partimag/flatpakcache/.ostree/repo.

**Utilidade para um desenvolvedor ou técnico:**

- Permite criar um **ambiente de desenvolvimento isolado** que serve como cache para outros testes de VMs ou novas configurações de estações da rede local.

- Reduz drasticamente o I/O no NVMe do laptop, pois todos os downloads (APT, Flatpak, arquivos temporários) são armazenados em cache no próprio laptop (ou em um storage externo montado em /partimag).

- A opção 9 é **executada apenas uma vez por ambiente**; após configurado, as outras estações apontam para este servidor, via edição de variáveis nos arquivos do profiles.

**Diferencial para o administrador/desenvolvedor:**

- Esta opção está intimamente ligado aos dados constantes dos arquivos em profiles.

<!-- -->

- Pode-se criar perfis de configuração customizados para cada cliente editando os arquivos em /etc/customization/profiles/.

- Pode adicionar novos scripts em modules/ ou scripts/ sem alterar a lógica central.

##  

## 3. RELATÓRIO AO GESTOR DE NEGÓCIOS

**Público‑alvo:** Proprietários de negócios, gestores corporativos, gestores de TI, consultores de migração, provedores de serviços de implantação, e profissionais que buscam uma alternativa ao Windows para escritórios e serviços públicos.

### 3.1 Público‑alvo detalhado – profissionais que dependem de tokens e assinaturas digitais

| Segmento / Profissão                         | Sistemas que exigem token/certificado ICP‑Brasil                                            |
|----------------------------------------------|---------------------------------------------------------------------------------------------|
| **Advogados**                                | PJe, eproc, sistemas dos tribunais (TJ, TRF, TST)                                           |
| **Médicos**                                  | Sistema CFM (Certillion), E-SUS, PEC, laudos digitais, certificado digital para receituário |
| **Farmacêuticos**                            | Anvisa (sistema de notificação), nota fiscal eletrônica, controle de medicamentos           |
| **Contadores**                               | SPED, ECD, ECF, sistemas do CRC, Receita Federal (e-CAC)                                    |
| **Gestores públicos (finanças, licitações)** | SIAFI, SIASG, ComprasNet, BLL (Banco de Licitações e Leilões)                               |
| **Cartórios**                                | Registro de imóveis, protesto, sistema eletrônico de registros (SER)                        |
| **Imobiliárias**                             | Matrículas online, contratos digitais com certificado A3                                    |
| **Engenheiros e arquitetos**                 | CREA (ART/RRT), sistemas de fiscalização de obras                                           |
| **Segurança privada**                        | Sistema de controle da Polícia Federal (CSP)                                                |
| **Instituições de ensino**                   | FIES, PROUNI, sistema e-MEC                                                                 |
| **Entidades sindicais**                      | SindicatoWeb, declarações ao Ministério do Trabalho                                         |
| **Fisioterapeutas**                          | CREFITO – certificado para documentos digitais                                              |

**Milhões de usuários no Brasil** utilizam diariamente tokens ou smartcards para autenticação e assinatura.

### 3.2 Diferencial competitivo da solução

- **Suporte nativo aos tokens mais usados no Brasil:** G&D SafeSign, Safenet (Aladdin), Dexon DXSafe, eToken, Gemalto. Todos os drivers são instalados automaticamente e registrados no PKCS#11.

- **Assinadores digitais integrados:** PJe Office, WebPKI (Lacuna), Assinador Serpro, Certillion – prontos para uso em sites governamentais e sistemas corporativos.

- **Certificados ICP‑Brasil (ITI) instalados no sistema e nos perfis dos usuários:** ao executar o atalho “Habilita Certificados GOV e Tokens”, o usuário final atualiza sua base de certificados e habilita-os nos navegadores (Firefox, Chrome, Edge).

- **Perfis de uso pré‑configurados (Home Office, Corporativo, Saúde):** edição simples de arquivos de configuração para ativar/desativar recursos (backup, Kaspersky, etc.).

- **Cache compartilhado (NFS + APT‑Cacher‑NG):** reduz drasticamente o consumo de banda em escritórios com várias estações a ser customizadas. A solução já inclui o script para configurar o servidor de cache (opção 9).

- **Baixo impacto em hardware e prolongamento da vida útil do SSD:** otimizações de I/O (tmpfs, instalação massiva, fstrim) e uso de cache NFS.

### 3.3 Segmentação de mercado e casos de uso

| Segmento                                    | Necessidade                                                            | Como a solução atende                                                                        |
|---------------------------------------------|------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| **Escritórios de advocacia (20+ estações)** | Certificado digital para PJe, segurança, baixo custo de licença        | Perfil Corporativo ativa backup Proxmox, tokens e WebPKI. Cache NFS otimiza a rede.          |
| **Clínicas e hospitais**                    | Laudos digitais, integração com sistemas do CFM, antivírus corporativo | Perfil Saúde prepara Kaspersky, instala Weasis (DICOM).                                      |
| **Contabilidade e assessoria**              | SPED, e-CAC, certificado A3, backup centralizado                       | ENABLE_BACKUP=true e comunicação com servidor Proxmox. Token G&D SafeSign suportado.         |
| **Gestão pública (prefeituras, câmaras)**   | ComprasNet, SIAFI, SIASG, necessidade de rastreabilidade               | Perfil Corporativo com regras de acesso SSH (hosts.allow) e auditoria via logs persistentes. |
| **Home office (profissionais liberais)**    | Ambiente leve, fácil de reinstalar, compatível com token               | Perfil Home Office. O usuário pode instalar certificados e tokens via atalhos no menu.       |

### 3.4 Argumentos de conversão para migração do Windows para Zorin OS 18.1

1.  **Gratuidade total** – sem custo de licenças do Windows ou de antivírus corporativo.

2.  **Interface familiar** – Zorin OS 18.1 possui layout similar ao Windows 10/11, reduzindo a curva de aprendizado.

3.  **Pronto para uso imediato** – após rodar main.sh com o perfil desejado, o sistema já possui todos os drivers de tokens, assinadores e navegadores configurados.

4.  **Integração com a infraestrutura existente** – suporte a Active Directory via SSSD, a servidores de backup Proxmox, a impressoras de rede (CUPS).

5.  **Menor necessidade de hardware** – a otimização de I/O e o uso de cache permitem rodar em equipamentos com SSD pequeno e pouca RAM (8 GB mínimo recomendado, 16 GB ideal).

6.  **Segurança por design** – permissões de arquivos, isolamento de usuários, atualizações automáticas espaçadas, e possibilidade de usar Kaspersky licenciado (opcional).

7.  **Resiliência de repositórios** – o preflight testa e desabilita temporariamente repositórios inacessíveis, garantindo que apt update nunca falhe.

8.  **Reabilitação automática de impressoras** – script enableprinter.sh evita que impressoras desabilitadas pelo CUPS interrompam o trabalho.

9.  **Atualizações intervaladas (2/2 dias) e limpeza automática** – manutenção programada sem sobrecarga do administrador.

**Simulação:**

“O Zorin OS pode ser instalado e customizado em 50 estações de um escritório de contabilidade. Com o cache, o tempo de customização cai de 20 minutos para menos de 6 minutos por máquina. Os tokens e o WebPKI funcionam sem problemas, e a economia com licenças Windows é em torno de R\$ 40.000 por ano.”

### 3.5 Próximos passos para adoção do serviço

1.  **Demonstração técnica** – executar o main.sh perfil 2 em um laptop com Zorin OS 18.1, mostrando a instalação automática dos tokens.

2.  **Estudo de capacidade** – calcular a necessidade de um servidor de cache (opção 9) baseado no número de estações e na banda disponível (opcional).

3.  **Contrato de suporte** – oferecer treinamento para o administrador local sobre como editar perfis e gerenciar as tarefas cron.

4.  **Migração piloto** – escolher um setor (ex.: financeiro ou jurídico) para validação de 30 dias.

5.  **Como iniciar a instalação (recomenda-se fazê-lo em uma VM) copie e cole <u>como uma única linha</u> no terminal o texto a seguir:**

    sudo apt install git -y && rm -rf /tmp/customization\* && git clone <https://github.com/arthur-aida/zorin_corporate_configs.git> /tmp/zorin_corporate_configs/ && sudo bash -c "mkdir -p /etc/customization/ /var/log/customization-persist/ && cp -r /tmp/zorin_corporate_configs/\* /etc/customization/ && cd /etc/customization/ && chmod +x main.sh && ./main.sh 2 2\>&1 \| tee /var/log/customization-persist/main.log"
