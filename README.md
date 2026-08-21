# Migração do Windows para Linux com Zorin OS Corporate Configs (repositório no github zorin_corporate_configs)

> **Automação Pós-Instalação e Padronização Corporativa para Zorin OS 18.1, Ubuntu 24.04 LTS e Linux Mint em Ambientes Empresariais, Jurídicos e de Saúde no Brasil.**

---

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Zorin OS](https://img.shields.io/badge/Zorin%20OS-18.1%20LTS-7B5294?logo=zorin&logoColor=white)](https://zorin.com/os/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Linux Mint](https://img.shields.io/badge/Linux%20Mint-22%20LTS-87CF3E?logo=linuxmint&logoColor=white)](https://linuxmint.com/)
[![Bash Script](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![ICP-Brasil](https://img.shields.io/badge/ICP--Brasil-Compat%C3%ADvel-green)](#suporte-a-certificados-e-tokens-a3-icp-brasil)
[![Linguagem Principal](https://img.shields.io/github/languages/top/arthur-aida/zorin_corporate_configs)](https://github.com/arthur-aida/zorin_corporate_configs)
[![Estrelas no GitHub](https://img.shields.io/github/stars/arthur-aida/zorin_corporate_configs)](https://github.com/arthur-aida/zorin_corporate_configs/stargazers)
[![Issues Abertas](https://img.shields.io/github/issues/arthur-aida/zorin_corporate_configs)](https://github.com/arthur-aida/zorin_corporate_configs/issues)
[![Último Commit](https://img.shields.io/github/last-commit/arthur-aida/zorin_corporate_configs)](https://github.com/arthur-aida/zorin_corporate_configs/commits/main)

## ⚠️ AVISO LEGAL E DE RESPONSABILIDADE

Este projeto é uma ferramenta de automação open-source distribuída gratuitamente. Embora contenha perfis voltados para os setores de saúde e jurídico, **não possui garantias de funcionamento de qualquer tipo**. 

A alteração de regras do Flatpak (`--filesystem=/usr/lib:ro`) e a automação de drivers PKCS#11 visam a conveniência de uso de tokens A3, mas alteram a superfície de isolamento original do sistema. Certifique-se de testar exaustivamente os módulos em ambiente de homologação (KVM/QEMU) antes de aplicá-los em computadores de produção ou redes corporativas. O uso desta suíte ocorre por sua conta e risco, conforme os termos do Adendo Jurisdicional anexo à licença MIT.

---

## 📌 Sumário

- [⚠️ AVISO LEGAL E DE RESPONSABILIDADE](#️-aviso-legal-e-de-responsabilidade)
- [📸 Visão Geral](#-visão-geral)
- [✨ Principais Funcionalidades](#-principais-funcionalidades)
- [🔑 Suporte a Certificados e Tokens A3 (ICP-Brasil)](#-suporte-a-certificados-e-tokens-a3-icp-brasil)
- [⚡ Arquitetura de Cache Triplo (Deploy de Alta Performance)](#-arquitetura-de-cache-triplo-deploy-de-alta-performance)
  - [Otimizações de I/O e Desempenho de Hardware](#otimizações-de-io-e-desempenho-de-hardware)
- [🎭 Perfis de Instalação e Customização](#-perfis-de-instalação-e-customização)
- [📋 Requisitos de Sistema](#-requisitos-de-sistema)
  - [Requisitos Mínimos (Estação de Trabalho)](#requisitos-mínimos-estação-de-trabalho)
  - [Requisitos Recomendados (Servidor Local de Cache)](#requisitos-recomendados-servidor-local-de-cache)
- [🚀 Instalação e Início Rápido (Quickstart)](#-instalação-e-início-rápido-quickstart)
- [⚡ Servidor de Infraestrutura](#-servidor-de-infraestrutura)
- [📊 Benchmarks e Desempenho](#-benchmarks-e-desempenho)
- [💡 Homologação em Ambientes Virtuais (KVM/QEMU)](#-homologação-em-ambientes-virtuais-kvmqemu)
- [🔄 Manutenção Autônoma e Rotinas Cron](#-manutenção-autônoma-e-rotinas-cron)
- [📁 Estrutura do Repositório](#-estrutura-do-repositório)
- [❓ Perguntas Frequentes (FAQ)](#-perguntas-frequentes-faq)
- [🤝 Como Contribuir](#-como-contribuir)
- [📜 Licença e Autor](#-licença-e-autor)

---

## 📸 Visão Geral

O **`zorin_corporate_configs`** é uma suíte open-source de automação em Bash desenvolvida para resolver os principais gargalos da migração do **Windows 10/11 para Linux** no ambiente corporativo brasileiro. 

Desenvolvido especialmente para gerentes de TI, SysAdmins e consultores de suporte, o projeto transforma uma instalação limpa do **Zorin OS 18.1** (ou derivados do Ubuntu LTS como o Linux Mint 22.X) em um ambiente de trabalho de nível corporativo em poucos minutos, pré-configurado com segurança, assinadores digitais governamentais, suíte de escritório e otimização de tráfego de rede.

---

## ✨ Principais Funcionalidades

- 🔒 **Compatibilidade total com ecossistema governamental e judiciário brasileiro** (PJe, Shodō, SERPRO, Certillion).
- 🔑 **Suporte nativo a Tokens Criptográficos A3 e ICP-Brasil** nos navegadores Chrome, Edge, Brave e Firefox (mesmo em Flatpak/Sandbox).
- ⚡ **Economia de até 98,3% de banda de internet WAN** através de arquitetura de cache local de 3 níveis.
- ⏱️ **Redução de até 45% no tempo de implantação/deploy** por máquina.
- 🎭 **3 Perfis de Uso Adaptáveis**: Doméstico, Corporativo e Saúde/Clínicas. Provê o servidor de Infraestrutura.
- 🖨️ **Manutenção autônoma**: Auto-recuperação de impressoras desativadas e limpeza automática de caches temporários.

---

## 🔑 Suporte a Certificados e Tokens A3 (ICP-Brasil)

Um dos maiores desafios de migração para Linux em escritórios de advocacia, contabilidade e órgãos públicos no Brasil é a integração de leitores de cartão e tokens A3. O projeto resolve esse problema de ponta a ponta:

1. **Instalação da Cadeia de Custódia Oficial**:
   - O script `instalar_certificados_icp_brasil.sh` baixa, valida e instala as raízes da **AC Raiz da ICP-Brasil** (ITi) atualizadas.
   - O script `import-icp-brasil.sh` injeta automaticamente os certificados na store do sistema, no `p11-kit` e no banco de dados NSS (`cert8.db` / `cert9.db`) de todos os perfis de navegadores.

2. **Drivers e PKCS#11 para Tokens A3**:
   - Suporte pré-configurado para drivers **G&D SafeSign**, **Safenet (Aladdin / eToken)** e **Dexon DXSafe**.
   - Integração do `p11-kit-trust.so` substituindo o `libnssckbi.so` nativo do Firefox.

3. **Compatibilidade com Navegadores Flatpak (Sandbox)**:
   - Permissão global `--filesystem=/usr/lib:ro` e acesso ao barramento PKCS#11 para que navegadores isolados leiam tokens físicos conectados na máquina hospedeira.

4. **Sistemas e Assinadores Pré-homologados**:
   - **PJe Office** e **Shodō** (com bibliotecas `libssl1.1` e ambiente Java pré-configurados).
   - **Assinador SERPRO** (AppImage v4.4.0) e **Certillion** (execução não-root).
   - **WebPKI (Lacuna Software)**.

---

## ⚡ Arquitetura de Cache Triplo (Deploy de Alta Performance)

Deploy em lote de 10, 50 ou 100 estações de trabalho costuma inviabilizar o link de internet da empresa. O `zorin_corporate_configs` utiliza um modelo de **cache híbrido em 3 níveis** para retenção local de dados de **98,3%**:

```txt

               [ Internet / WAN (Apenas 1,7% do tráfego) ]
                                   │
                                   ▼
                   ┌───────────────────────────────┐
                   │ Nível 1: Validação Local      │
                   └───────────────────────────────┘
                                   │
          ┌────────────────────────┴────────────────────────┐
          ▼                                                 ▼
┌──────────────────────────────────┐            ┌──────────────────────────────────┐
│ Nível 2: Proxy APT-Cacher-NG     │            │ Nível 3: Compartilhamento NFS    │
│ (Porta 3142 - Pacotes .deb)      │            │ - Repositório OSTree (Flatpak)   │
│ Retenção de Tráfego: 18,0%       │            │ - Instaladores (.run, AppImage)  │
└──────────────────────────────────┘            └──────────────────────────────────┘
```

---

### Otimizações de I/O e Desempenho de Hardware

- **Preservação do SSD/NVMe**: Logs de execução do instalador são gravados em memória RAM via `tmpfs` em `/var/log/customization` (50 MB max).
- **Instalação massiva via APT**: Todos os pacotes necessários são consolidados e instalados em comando único (`02-bulk-packages.sh`).
- **Gerenciamento de locks do dpkg**: Suspensão automática do `packagekit.service` e `apt-daily.timer` durante a execução para evitar travamentos de trava do sistema.
- **Roaming Inteligente de Rede**: Script dispatcher no NetworkManager detecta se o computador está na rede corporativa (aplicando o proxy local APT) ou em home-office/externo, alternando os repositórios sem intervenção do usuário.

---

## 🎭 Perfis de Instalação e Customização

Você pode alterar o perfil ativado editando o arquivo `/etc/customization/active-profile.env`:

| Perfil | Arquivo de Conf. | Público-Alvo / Foco de Aplicação | Recurso Destacado |
| :--- | :--- | :--- | :--- |
| **Corporativo** | `corporate.conf` | Escritórios, Empresas, Contabilidade e Advocacia | Suporte a Tokens A3, Proxy APT, Cliente Proxmox Backup, Hardening SSH |
| **Saúde / Clínicas** | `health.conf` | Hospital, Clínicas Médicas e Odontológicas | Visualizador DICOM (Weasis), Terminal pw3270, Sincronização NTP |
| **Doméstico** | `domestic.conf` | Uso Pessoal, Home Office e Estudo | Suíte OnlyOffice, utilitários multimídia, sem restrições corporativas |
| **Servidor Infra** | `setup-server-KVM-nfs-acng.sh` | Servidor Local da Empresa | Proxy APT-Cacher-NG, Compartilhamento NFS e Hypervisor KVM |

---

## 📋 Requisitos de Sistema

### Requisitos Mínimos (Estação de Trabalho)
- **Sistema Operacional**: Zorin OS 18.1 (Core, Pro ou Lite), Ubuntu 24.04 LTS ou Linux Mint 22.X LTS.
- **Processador**: CPU x86_64 Dual-Core de 2.0 GHz.
- **Memória RAM**: 4 GB.
- **Armazenamento**: 25 GB em SSD / NVMe.
- **Conexão de Rede**: Placa de rede Ethernet 100/1000 Mbps ou Wi-Fi.

### Requisitos Recomendados (Servidor Local de Cache)
- **CPU**: Quad-Core ou superior.
- **Memória RAM**: 8 GB+.
- **Armazenamento**: SSD de 120 GB+ reservado para cache de pacotes `.deb` e Flatpaks OSTree.

---

## 🚀 Instalação e Início Rápido (Quickstart)

### Preparar desktops: MÓVEIS, HOME OFFICE e CORPORATIVOS

📋 Para iniciar o processo, clique no ícone Copiar e Cole no terminal linux para executar a otimização automática na estação de trabalho:

```bash
sudo apt install git -y && rm -Rf /tmp/zorin_corporate_configs && git clone https://github.com/arthur-aida/zorin_corporate_configs.git /tmp/zorin_corporate_configs/ && sudo bash -c "mkdir -p /etc/customization/ /var/log/customization-persist/ && cp -r /tmp/zorin_corporate_configs/* /etc/customization/ && cd /etc/customization/ && chmod +x main.sh && ./main.sh 2 2>&1 | tee /var/log/customization-persist/main.log"
```

---

## ⚡ Servidor de Infraestrutura

📋 Para transformar um computador antigo ou servidor local em uma central de distribuição de atualizações e hipervisor de máquinas virtuais, execute o script autônomo:

```bash
sudo apt install git -y && sudo rm -Rf /tmp/zorin_corporate_configs && git clone https://github.com/arthur-aida/zorin_corporate_configs.git /tmp/zorin_corporate_configs/ && sudo bash -c "mkdir -p /etc/customization/ /var/log/customization-persist/ && cp -r /tmp/zorin_corporate_configs/* /etc/customization/ && cd /etc/customization/scripts && chmod +x ./setup-server-KVM-nfs-acng.sh && ./setup-server-KVM-nfs-acng.sh"
```

Este script configura automaticamente:
1. **APT-Cacher-NG** na porta `3142` para interceptar e armazenar atualizações `.deb`.
2. **Servidor NFS** para compartilhamento da pasta de sideload de Flatpaks e programas corporativos.
3. **KVM / QEMU / Virt-Manager** com suporte a ponte de rede (bridge) e aceleração de hardware.

---

## 📊 Benchmarks e Desempenho

Valores obtidos em bancada de testes utilizando um notebook com **Processador AMD Ryzen 5 3500U, 16 GB RAM e SSD NVMe M.2**:

| Métrica de Desempenho | Instalação Padrão (Download WAN) | Com `zorin_corporate_configs` | Ganho / Economia Obtida |
| :---: | :---: | :---: | :---: |
| **Tempo de Deploy (Perfil Doméstico)** | 12 min 25 s | **7 min 40 s** | **38% mais rápido** ⚡ |
| **Tempo de Deploy (Perfil Corporativo/Saúde)** | 6 min 57 s | **3 min 50 s** | **45% mais rápido** ⚡ |
| **Consumo de Banda WAN por Máquina** | ~4,3 GB | **74 MB (1,7%)** | **98,3% de economia** 🌐 |

---

## 💡 Homologação em Ambientes Virtuais (KVM/QEMU)

Para testar e validar as configurações em uma máquina virtual garantindo até **97% do desempenho do hardware real**, utilize a seguinte especificação no **Virt-Manager**:

- **RAM**: 1/3 da memória física (ex.: 5120 MB para hosts com 16 GB).
- **Processador**: Metade dos núcleos/threads do processador hospedeiro (Habilite o modo `host-passthrough`).
- **Disco**: Controladora **VirtIO SCSI** | Modo de Cache: `none` | Otimização: `unmap` (Descarte/TRIM ativo).
- **Vídeo**: Driver **VirtIO** com Aceleração 3D ativa | Exibição Spice (Tipo de Escuta: *Nenhum*).

---

## 🔄 Manutenção Autônoma e Rotinas Cron

Após a conclusão da instalação, a estação de trabalho permanece auto-gerenciada através de scripts automatizados no `cron`:

- 🖨️ **Reativação de Impressoras (`/etc/enableprinter.sh`)**: Executado a cada 5 minutos. Detecta impressoras que sofreram pause/offline automático no CUPS por instabilidade de rede e as reativa automaticamente.
- 🧹 **Limpeza Automática (`/etc/clean.sh`)**: Mantém o sistema enxuto removendo caches de navegadores, arquivos temporários e logs antigos periodicamente.

---

## 📁 Estrutura do Repositório

```text
zorin_corporate_configs/
├── main.sh                       # Orquestrador principal de execução
├── README.md                     # Documentação oficial do projeto
├── active-profile.env            # Link ou cópia do perfil atualmente ativo
├── modules/                      # Módulos encadeados de execução (00 a 15)
│   ├── 00-environment-check.sh   # Validação de sistema, arquitetura e permissões
│   ├── 01-network-cache-setup.sh # Configuração de proxy APT e rotas NFS
│   ├── 02-bulk-packages.sh       # Instalação em lote de 446+ pacotes .deb
│   ├── 03-icp-brasil-setup.sh    # Instalação das cadeias de certificados do ITI
│   ├── 04-tokens-smartcards.sh   # Drivers para leitores e tokens A3 (SafeSign, Safenet)
│   ├── 05-signing-apps.sh        # Setup do PJe Office, Shodō, SERPRO e Certillion
│   └── ...                       # Outros módulos de customização corporativa
├── profiles/                     # Perfis de configuração
│   ├── corporate.conf            # Perfil Corporativo/Empresarial
│   ├── health.conf               # Perfil Saúde/Clínicas médicas
│   └── domestic.conf             # Perfil Uso Doméstico/Home Office
└── scripts/                      # Scripts auxiliares e de infraestrutura
    ├── setup-server-KVM-nfs-acng.sh # Instalador do Servidor de Cache e KVM
    ├── import-icp-brasil.sh      # Importador de certificados no NSS/p11-kit
    ├── enableprinter.sh          # Daemon de auto-recuperação de impressoras CUPS
    └── clean.sh                  # Rotina de limpeza de cache e temporários
```

---

## ❓ Perguntas Frequentes (FAQ)

### 1. O projeto funciona em outras distribuições além do Zorin OS?
Sim. Embora otimizado para o **Zorin OS 18.1**, a suíte é totalmente compatível com **Ubuntu 24.04 LTS**, **Linux Mint 22**. Pode ser adaptado para distribuições derivadas do Debian x86_64 (não testado).

### 2. Os certificados A3 funcionam no Google Chrome e Microsoft Edge em Flatpak?
Sim. O módulo `04-tokens-smartcards.sh` aplica as regras do `p11-kit` e ajusta os privilégios do Flatpak (`--filesystem=/usr/lib:ro`), permitindo que navegadores conteinerizados acessem os módulos PKCS#11 nativos do sistema.

### 3. Preciso necessariamente de um servidor local de cache para usar o projeto?
Não. Se a rede não possuir o servidor de cache APT-Cacher-NG ou NFS, o script identificará a ausência e fará o download direto dos repositórios oficiais via internet (WAN).

---

## 🤝 Como Contribuir

Contribuições são super bem-vindas! Se você deseja propor melhorias, novos módulos ou relatar correções:

1. Faça um **Fork** deste repositório.
2. Crie uma Branch para a sua funcionalidade: `git checkout -b feature/nova-funcionalidade`.
3. Commit suas alterações: `git commit -m 'Adiciona suporte a novo token A3'`.
4. Envie para o repositório remoto: `git push origin feature/nova-funcionalidade`.
5. Abra um **Pull Request**.

---

## 📜 Licença e Autor

Este projeto está licenciado sob a licença **MIT** - veja o arquivo [LICENSE](LICENSE) para mais detalhes.

**Desenvolvido e Mantido por:**
- **Arthur Mitsuharu Aida** - *Desenvolvedor*
- Discussões Comunitárias: Canais independentes como a Comunidade [Diolinux Plus](https://plus.diolinux.com.br/t/projeto-como-automatizar-o-zorin-os-para-empresas-com-suporte-icp-brasil/83864) e [Viva o Linux](https://www.vivaolinux.com.br/dica/Migracao-do-Windows-para-o-Linux-com-sistemas-corporativos/) (o autor não presta suporte técnico comercial e não se responsabiliza por soluções propostas por terceiros nesses fóruns).
- Projeto Open Source para o Fortalecimento da Tecnologia Livre no Brasil.
- Apoio ao Projeto: Para realizar uma doação de caráter estritamente voluntário e espontâneo (sem direito a suporte contratual ou contraprestação de serviços), acesse o [QR-Code](https://nubank.com.br/cobrar/1jbqoi/6a817c80-a557-47cb-87fb-f186940931da).
