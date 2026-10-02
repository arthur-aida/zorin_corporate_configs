# Migração do Windows para Linux com Zorin OS Corporate Configs

> **Zorin Corporate Configs – Automação pós-instalação para Zorin OS, Ubuntu e Linux Mint com suporte a ICP-Brasil.**

---

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Zorin OS](https://img.shields.io/badge/Zorin%20OS-18.1%20LTS-7B5294?logo=zorin&logoColor=white)](https://zorin.com/os/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Linux Mint](https://img.shields.io/badge/Linux%20Mint-22%20LTS-87CF3E?logo=linuxmint&logoColor=white)](https://linuxmint.com/)
[![Bash Script](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![ICP-Brasil](https://img.shields.io/badge/ICP--Brasil-Compat%C3%ADvel-green)](#-suporte-a-certificados-e-tokens-a3-icp-brasil)
[![Linguagem Principal](https://img.shields.io/github/languages/top/arthur-aida/zorin_corporate_configs)](https://github.com/arthur-aida/zorin_corporate_configs)
[![Estrelas no GitHub](https://img.shields.io/github/stars/arthur-aida/zorin_corporate_configs)](https://github.com/arthur-aida/zorin_corporate_configs/stargazers)
[![Issues Abertas](https://img.shields.io/github/issues/arthur-aida/zorin_corporate_configs)](https://github.com/arthur-aida/zorin_corporate_configs/issues)
[![Último Commit](https://img.shields.io/github/last-commit/arthur-aida/zorin_corporate_configs)](https://github.com/arthur-aida/zorin_corporate_configs/commits/main)
![GitHub release](https://img.shields.io/github/v/release/arthur-aida/zorin_corporate_configs)

---

## ⚠️ AVISO LEGAL E DE RESPONSABILIDADE

Este projeto é uma ferramenta de automação open-source distribuída gratuitamente. Embora contenha perfis voltados para os setores de saúde e jurídico, **não possui garantias de funcionamento de qualquer tipo**.

A alteração de regras do Flatpak (`--filesystem=/usr/lib:ro`) e a automação de drivers PKCS#11 visam a conveniência de uso de tokens A3, mas alteram a superfície de isolamento original do sistema. Certifique-se de testar exaustivamente os módulos em ambiente de homologação (KVM/QEMU) antes de aplicá-los em computadores de produção ou redes corporativas. O uso desta suíte ocorre por sua conta e risco, conforme os termos do Adendo Jurisdicional anexo à licença MIT.

---

## 📌 Sumário

- [⚠️ Aviso Legal e de Responsabilidade](#️-aviso-legal-e-de-responsabilidade)
- [📸 Visão Geral](#-visão-geral)
- [✨ Principais Funcionalidades](#-principais-funcionalidades)
- [🔑 Suporte a Certificados e Tokens A3 (ICP-Brasil)](#-suporte-a-certificados-e-tokens-a3-icp-brasil)
- [⚡ Arquitetura de Cache Triplo](#-arquitetura-de-cache-triplo)
  - [Otimizações de I/O e Desempenho](#otimizações-de-io-e-desempenho)
- [🎭 Perfis de Instalação](#-perfis-de-instalação)
- [🧩 Módulos do Pipeline](#-módulos-do-pipeline)
- [📋 Requisitos de Sistema](#-requisitos-de-sistema)
  - [Requisitos Mínimos (Estação de Trabalho)](#requisitos-mínimos-estação-de-trabalho)
  - [Requisitos Recomendados (Servidor Local de Cache)](#requisitos-recomendados-servidor-local-de-cache)
- [🚀 Instalação e Início Rápido](#-instalação-e-início-rápido)
- [⚡ Servidor de Infraestrutura](#-servidor-de-infraestrutura)
- [📊 Benchmarks](#-benchmarks)
- [💡 Homologação em Ambientes Virtuais (KVM/QEMU)](#-homologação-em-ambientes-virtuais-kvmqemu)
- [🔄 Manutenção Autônoma](#-manutenção-autônoma)
- [📁 Estrutura do Repositório](#-estrutura-do-repositório)
- [❓ Perguntas Frequentes](#-perguntas-frequentes)
- [🤝 Como Contribuir](#-como-contribuir)
- [📜 Licença e Autor](#-licença-e-autor)

---

## 📸 Visão Geral

O **`zorin_corporate_configs`** é uma suíte open-source de automação em Bash desenvolvida para resolver os principais gargalos da migração do **Windows 10/11 para Linux** no ambiente corporativo brasileiro. Desenvolvido especialmente para gerentes de TI, SysAdmins e consultores de suporte, o projeto transforma uma instalação limpa do **Zorin OS 18.1** (ou derivados do Ubuntu LTS, como Linux Mint 22.X) em um ambiente de trabalho de nível corporativo em poucos minutos, pré-configurado com segurança, assinadores digitais governamentais, suíte de escritório e otimização de tráfego de rede.

---

## ✨ Principais Funcionalidades

- 🔒 **Compatibilidade com ecossistema governamental e judiciário brasileiro** (PJe, Shodō, SERPRO, Certillion, WebPKI).
- 🔑 **Suporte nativo a tokens criptográficos A3 e ICP-Brasil** nos navegadores Chrome, Edge, Brave e Firefox, inclusive em versões Flatpak/Sandbox.
- ⚡ **Economia de até 98,3% de banda WAN** através de arquitetura de cache local em 3 níveis.
- ⏱️ **Redução de até 45% no tempo de implantação** por máquina.
- 🎭 **3 perfis de uso adaptáveis**: Doméstico, Corporativo e Saúde/Clínicas, mais o provisionamento do servidor de infraestrutura.
- 🖨️ **Manutenção autônoma**: auto-recuperação de impressoras desativadas e limpeza automática de caches temporários.

---

## 🔑 Suporte a Certificados e Tokens A3 (ICP-Brasil)

Um dos maiores desafios de migração para Linux em escritórios de advocacia, clínicas, contabilidade e órgãos públicos no Brasil é a integração de leitores de cartão e tokens A3. O projeto resolve esse problema de ponta a ponta:

1. **Instalação da Cadeia de Custódia Oficial**
   - O script `original_scripts/instalar_certificados_icp_brasil.sh` (invocado pelo módulo `03-certificates.sh`) baixa, valida e instala as raízes da **AC Raiz da ICP-Brasil** (ITi) atualizadas.
   - O script `scripts/import-icp-brasil.sh` (invocado pelo módulo `06-icp-user-certs.sh`) injeta automaticamente os certificados no trust store do sistema, no `p11-kit` e nos bancos NSS (`cert8.db` / `cert9.db`) dos perfis de usuários atuais e futuros (via `/etc/skel`).

2. **Drivers e PKCS#11 para Tokens A3**
   - Suporte pré-configurado para drivers **G&D SafeSign**, **Safenet (Aladdin/eToken)** e **Dexon DXSafe**, por meio dos scripts `original_scripts/tokenGD.sh`, `original_scripts/safenet.sh` e `original_scripts/TokenDXSafe.sh`.
   - Integração do `p11-kit-trust.so` substituindo o `libnssckbi.so` nativo do Firefox.

3. **Compatibilidade com Navegadores Flatpak (Sandbox)**
   - Permissão global `--filesystem=/usr/lib:ro` e acesso ao barramento PKCS#11 para que navegadores isolados leiam tokens físicos conectados à máquina hospedeira. Overrides aplicados pelo módulo `06-icp-user-certs.sh`.

4. **Sistemas e Assinadores Pré-homologados**
   - **PJe Office** e **Shodō** (com bibliotecas `libssl1.1` e ambiente Java configurados pelo módulo `09-signers.sh`).
   - **Assinador SERPRO** (AppImage v4.4.0) e **Certillion**.
   - **WebPKI (Lacuna Software)**.

---

## ⚡ Arquitetura de Cache Triplo

Deploy em lote de 10, 50 ou 100 estações de trabalho costuma inviabilizar o link de internet da empresa. O `zorin_corporate_configs` utiliza um modelo de **cache híbrido em 3 níveis** com retenção local de até **98,3%**:

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
│ (Porta 3142 – pacotes .deb)      │            │ – Repositório OSTree (Flatpak)   │
│ Retenção de Tráfego: 18,0%       │            │ – Instaladores (.run, AppImage)  │
└──────────────────────────────────┘            └──────────────────────────────────┘
```

---

### Otimizações de I/O e Desempenho

- **Preservação do SSD/NVMe**: Logs de execução do instalador são gravados em memória RAM via `tmpfs` em `/var/log/customization` (50 MB max).
- **Instalação massiva via APT**: Todos os pacotes necessários são consolidados e instalados em comando único (`02-bulk-packages.sh`).
- **Gerenciamento de locks do dpkg**: A função `wait_for_apt_unlock` (em `utils/common.sh`) suspende o `packagekit.service` e o `apt-daily.timer` durante a execução, evitando travamentos por lock do dpkg.
- **Roaming Inteligente de Rede**: Os scripts `99-apt-cacher-roaming.sh`, `convert-sources-to-proxy.sh` e `restore-sources-from-backup.sh` preparam o NetworkManager para detectar se o computador está na rede corporativa ou em home-office/externo, alternando os repositórios sem intervenção do usuário.

---

## 🎭 Perfis de Instalação

Após a customização inicial, o perfil ativo pode ser alterado editando o arquivo `/etc/customization/active-profile.env`, que é gerado a partir do arquivo correspondente em `profiles/`:

- **corporate.conf** é especializado em Escritórios, Empresas, Contabilidade, Advocacia, Suporte a Tokens A3, Proxy APT, Cliente Proxmox Backup, Hardening SSH;
- **health.conf** é especializado em hospitais e clínicas com o visualizador DICOM (Weasis), Terminal pw3270, Sincronização NTP;
- **domestic.conf** é focado no uso pessoal, home office com a suíte OnlyOffice, utilitários multimídia sem as restrições corporativas.

> Para o conteúdo integral dos arquivos `.conf`, a lista de variáveis (`APTCACHER`, `ENABLE_HEALTH_APPS`, `ntpserver`, etc.) e a forma como cada perfil é consumida pelos módulos, consulte [`profiles/perfis.md`](profiles/perfis.md).

---

## 🧩 Módulos do Pipeline

O pipeline é composto por **16 módulos** (`00` a `15`), executados pelo `main.sh` em etapas sequenciais e paralelas. A documentação técnica completa — incluindo a tabela de módulos, as etapas de execução (Passos 6 a 9), o tratamento de falhas (`FAILED_MODULES`) e as flags do orquestrador (`--skip-errors`, `--no-preflight`, `--no-apt-cacher`, `--no-nfs`) — está em [`modules/modules.md`](modules/modules.md).

---

## 📋 Requisitos de Sistema

### Requisitos Mínimos (Estação de Trabalho)
- **Sistema Operacional**: Zorin OS 18.1 (Core, Pro ou Lite), Ubuntu 24.04 LTS ou Linux Mint 22.X LTS.
- **Processador**: CPU x86_64 Dual-Core de 2.0 GHz.
- **Memória RAM**: 4 GB.
- **Armazenamento**: 25 GB em SSD / NVMe.
- **Conexão de Rede**: Placa de rede Ethernet 100/1000 Mbps ou Wi-Fi.

### Requisitos Recomendados (Servidor Local de Cache)

> O script `scripts/setup-server-KVM-nfs-acng.sh` implementa um servidor local com APT-Cacher-NG, compartilhamento NFS e hypervisor KVM.

- **CPU**: Quad-Core ou superior.
- **Memória RAM**: 8 GB+.
- **Armazenamento**: SSD de 120 GB+ reservado para cache de pacotes `.deb` e Flatpaks OSTree.

---

## 🚀 Instalação e Início Rápido

**Preparar desktops: móveis, home office e corporativos**

📋 Para iniciar o processo de instalação, copie o bloco abaixo e cole no terminal do Zorin OS para executar a otimização automática na estação de trabalho:

```bash
sudo apt install git -y && rm -Rf /tmp/zorin_corporate_configs && git clone https://github.com/arthur-aida/zorin_corporate_configs.git /tmp/zorin_corporate_configs/ && sudo bash -c "mkdir -p /etc/customization/ /var/log/customization-persist/ && cp -r /tmp/zorin_corporate_configs/* /etc/customization/ && cd /etc/customization/ && chmod +x main.sh && ./main.sh 2 2>&1 | tee /var/log/customization-persist/main.log"
```

> O argumento `2` seleciona o Perfil Corporativo. Substitua por `1` (Doméstico), `3` (Saúde/Clínicas) ou `9` (Servidor de Infraestrutura) conforme necessário.

---

## ⚡ Servidor de Infraestrutura

📋 Para transformar um computador antigo ou servidor local em uma central de distribuição de atualizações e hipervisor de máquinas virtuais, execute o script autônomo:

```bash
sudo apt install git -y && sudo rm -Rf /tmp/zorin_corporate_configs && git clone https://github.com/arthur-aida/zorin_corporate_configs.git /tmp/zorin_corporate_configs/ && sudo bash -c "mkdir -p /etc/customization/ /var/log/customization-persist/ && cp -r /tmp/zorin_corporate_configs/* /etc/customization/ && cd /etc/customization/scripts && chmod +x ./setup-server-KVM-nfs-acng.sh && ./setup-server-KVM-nfs-acng.sh"
```

> Este script configura automaticamente:
>
> 1. **APT-Cacher-NG** na porta `3142` para interceptar e armazenar atualizações `.deb`.
> 2. **Servidor NFS** para compartilhamento da pasta de sideload de Flatpaks e programas corporativos.
> 3. **KVM/QEMU/Virt-Manager** com suporte a bridge de rede e aceleração de hardware.

---

## 📊 Benchmarks

Valores obtidos em bancada de testes utilizando um notebook com **Processador AMD Ryzen 5 3500U, 16 GB RAM e SSD NVMe M.2**:

| Métrica de Desempenho | Instalação Padrão (Download WAN) | Com `zorin_corporate_configs` | Ganho / Economia Obtida |
| :---: | :---: | :---: | :---: |
| **Tempo de Deploy (Perfil Doméstico)** | 12 min 25 s | **7 min 40 s** | **38% mais rápido** ⚡ |
| **Tempo de Deploy (Perfil Corporativo/Saúde)** | 6 min 57 s | **3 min 50 s** | **45% mais rápido** ⚡ |
| **Consumo de Banda WAN por Máquina** | ~4,3 GB | **74 MB (1,7%)** | **98,3% de economia** 🌐 |

---

## 💡 Homologação em Ambientes Virtuais (KVM/QEMU)

Para testar e validar as configurações em uma máquina virtual **com até 97% do desempenho do hardware real**, utilize a seguinte especificação no **Virt-Manager**:

- **RAM**: 1/3 da memória física (ex.: 5120 MB para hosts com 16 GB).
- **Processador**: Metade dos núcleos/threads do processador hospedeiro (Habilite o modo `host-passthrough`).
- **Disco**: Controladora **VirtIO SCSI** | Modo de Cache: `none` | Otimização: `unmap` (Descarte/TRIM ativo).
- **Vídeo**: Driver **VirtIO** com Aceleração 3D ativa | Exibição Spice (selecionar: *Nenhum*).

---

## 🔄 Manutenção Autônoma

Após a conclusão da instalação, a estação de trabalho permanece auto-gerenciada através de scripts automatizados no `cron`:

- 🖨️ **Reativação de Impressoras (`/etc/enableprinter.sh`)**: script gerado em tempo de execução pelo módulo `14-security.sh` e executado periodicamente via `cron`. Detecta impressoras que sofreram pause/offline automático no CUPS por instabilidade de rede e as reativa automaticamente.
- 🧹 **Limpeza Automática (`/etc/clean.sh`)**: mantém o sistema enxuto removendo caches de navegadores, arquivos temporários e logs antigos.

> ⚠️ Os scripts `/etc/enableprinter.sh` e `/etc/clean.sh` **não residem em `scripts/`**; são gerados em tempo de execução pelo próprio pipeline.

---

## 📁 Estrutura do Repositório

```text
zorin_corporate_configs/
├── main.sh                              # Orquestrador principal
├── README.md                            # Este documento
├── LICENSE                              # Licença MIT + Adendo Jurisdicional
├── scripts-auxiliares.md                # Documentação dos scripts auxiliares
│
├── profiles/                            # Perfis de configuração
│   ├── perfis.md                        # Documentação dos perfis
│   ├── corporate.conf
│   ├── health.conf
│   └── domestic.conf
│
├── modules/                             # Pipeline de execução (00 a 15)
│   ├── modules.md                       # Documentação dos módulos
│   ├── 00-dependencies.sh
│   ├── 01-sync-scripts.sh
│   ├── 02-bulk-packages.sh
│   ├── 03-certificates.sh
│   ├── 04-browsers.sh
│   ├── 05-tokens.sh
│   ├── 06-icp-user-certs.sh
│   ├── 07-kaspersky.sh
│   ├── 08-wine.sh
│   ├── 09-signers.sh
│   ├── 10-backup.sh
│   ├── 11-flatpak-cache.sh
│   ├── 12-desktop-config.sh
│   ├── 13-desktop-config-user.sh
│   ├── 14-security.sh
│   └── 15-kvm-menu.sh
│
├── scripts/                             # Utilitários auxiliares
├── utils/                               # Funções compartilhadas
├── original_scripts/                    # Scripts legados invocados pelos módulos
│
└── Docs/                                # Documentação complementar
    ├── Arvore_de_recursos_ao_desenvolvedor.{md,pdf}
    ├── Guia_de_Configuração_do_Ambiente_de_Deploy_com_o_KVM_linux.{md,pdf}
    ├── Manual_Completo_do_Projeto_zorin_corporate_configs.{md,pdf}
    ├── Relatorios_ao_sysadmin.{md,pdf}
    ├── Proposta_Otimizacao_KVM_VMM.pdf
    ├── Relatorio_Migracao_Linux_2026.pdf
    └── Relatorios_Tecnico_SysAdmin_Desenvolvedor_2026.pdf
```

> Para a finalidade de cada arquivo em `scripts/`, `utils/` e `original_scripts/`, consulte [`scripts-auxiliares.md`](scripts-auxiliares.md). A documentação dos módulos está em [`modules/modules.md`](modules/modules.md) e a dos perfis em [`profiles/perfis.md`](profiles/perfis.md).

---

## ❓ Perguntas Frequentes

### 1. O projeto funciona em outras distribuições além do Zorin OS?

Sim. Embora otimizado para o **Zorin OS 18.1**, a suíte é totalmente compatível com **Ubuntu 24.04 LTS** e **Linux Mint 22**. Pode ser adaptado para distribuições derivadas do Debian x86_64 (não testado).

### 2. Os certificados A3 funcionam no Google Chrome e Microsoft Edge em Flatpak?

Sim. Os módulos `06-icp-user-certs.sh` e `05-tokens.sh` aplicam as regras do `p11-kit` e ajustam os privilégios do Flatpak (`--filesystem=/usr/lib:ro`), permitindo que navegadores conteinerizados acessem os módulos PKCS#11 nativos do sistema.

### 3. Preciso necessariamente de um servidor local de cache para usar o projeto?

Não. Se a rede não possuir o servidor de cache APT-Cacher-NG ou NFS, o script identificará a ausência e fará o download direto dos repositórios oficiais via internet (WAN). Use as flags `--no-apt-cacher` / `--no-nfs`, ou execute `main.sh` sem parâmetros para ver a ajuda.

### 4. Como altero o perfil ativo após a instalação?

Edite o arquivo `/etc/customization/active-profile.env` e reexecute `main.sh` informando a opção numérica correspondente (1 = Doméstico, 2 = Corporativo, 3 = Saúde/Clínicas, 9 = Servidor de Infraestrutura).

### 5. Onde ficam os logs?

- Log consolidado: `/var/log/customization-persist/main.log`
- Logs por módulo: `/var/log/customization-persist/<modulo>.log`

---

## 🤝 Como Contribuir

Contribuições são super bem-vindas! Se você deseja propor melhorias, novos módulos ou relatar correções:

1. Faça um **Fork** deste repositório.
2. Crie uma Branch para a sua funcionalidade: `git checkout -b feature/nova-funcionalidade`.
3. Commit suas alterações: `git commit -m 'Adiciona suporte a novo token A3'`.
4. Envie para o repositório remoto: `git push origin feature/nova-funcionalidade`.
5. Abra um **Pull Request**.

> **Nota estratégica:** a conversão desta suíte para **Ansible Roles** pode ser o vetor definitivo de adoção em ambientes governamentais. A suíte funciona como **prova de conceito (PoC)**; o Ansible Role é a linguagem utilizada por grandes órgãos (Ministérios, Tribunais, Prefeituras) para garantir compliance com a Estratégia de Governo Digital. A conversão do script `scripts/import-icp-brasil.sh` e do módulo `04-browsers.sh` (que gerencia o `firefox-manager.sh`) resolve cerca de **80% do atrito de adoção** pelo usuário final no funcionalismo público brasileiro.

---

## 📜 Licença e Autor

Este projeto está licenciado sob a licença **MIT** — veja o arquivo [LICENSE](LICENSE) para mais detalhes.

**Desenvolvido e mantido por:**

- **Arthur Mitsuharu Aida** — *Desenvolvedor*
- **Discussões comunitárias:** canais independentes como a [Comunidade Diolinux Plus](https://plus.diolinux.com.br/t/projeto-como-automatizar-o-zorin-os-para-empresas-com-suporte-icp-brasil/83864) e o [Viva o Linux](https://www.vivaolinux.com.br/dica/Migracao-do-Windows-para-o-Linux-com-sistemas-corporativos/). O autor **não presta suporte técnico comercial** e não se responsabiliza por soluções propostas por terceiros nesses fóruns.
- **Projeto Open Source** para o fortalecimento da tecnologia livre no Brasil.
- **Apoio ao projeto:** para realizar uma doação de caráter estritamente voluntário e espontâneo (sem direito a suporte contratual ou contraprestação de serviços), acesse o [QR-Code](https://nubank.com.br/cobrar/1jbqoi/6a817c80-a557-47cb-87fb-f186940931da).
