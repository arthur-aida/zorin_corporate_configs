Módulos do Pipeline

_1. Visão Geral_

O diretório modules/ contém 16 scripts (00 a 15), executados pelo main.sh em etapas sequenciais e paralelas. A lista real de arquivos é:

Arquivo	Execução
00-dependencies.sh	            Sequencial (Preflight)

01-sync-scripts.sh	            Sequencial

02-bulk-packages.sh	            Sequencial

03-certificates.sh	            Paralelo (Passo 6)

04-browsers.sh	                Paralelo (Passo 6)

05-tokens.sh	                Sequencial (Passo 7)

06-icp-user-certs.sh	        Paralelo (Passo 6)

07-kaspersky.sh	                Paralelo (Passo 6)

08-wine.sh	                Sequencial (Passo 7)

09-signers.sh	                Sequencial (Passo 7)

10-backup.sh	                Sequencial (Passo 7)

11-flatpak-cache.sh	        Paralelo (Passo 8)

12-desktop-config.sh	        Paralelo (Passo 8)

13-desktop-config-user.sh       Paralelo (Passo 8)

14-security.sh	                Paralelo (Passo 9)

15-kvm-menu.sh	                Paralelo (Passo 9)


**A ordem de execução é definida no main.sh:**

Passo 6 (paralelo): 03-certificates, 04-browsers, 06-icp-user-certs, 07-kaspersky

Passo 7 (sequencial): 05-tokens, 08-wine, 09-signers, 10-backup

Passo 8 (paralelo): 11-flatpak-cache, 12-desktop-config, 13-desktop-config-user

Passo 9 (paralelo): 14-security, 15-kvm-menu


_2. Descrição Individual dos Módulos_

00-dependencies.sh
Finalidade: Verificação e instalação de dependências base. Executado como parte do preflight.
Dependências: apt, yad, conectividade com a internet.

01-sync-scripts.sh
Finalidade: Sincronização de scripts auxiliares para o diretório de deploy.
Dependências: git, rsync.

02-bulk-packages.sh
Finalidade: Instalação em massa de pacotes APT (etapa mais pesada do pipeline).
Dependências: APT-Cacher-NG ativo (se configurado no perfil), lock do dpkg liberado.

03-certificates.sh
Finalidade: Instala certificados ICP-Brasil (primeira execução) executando o script original_scripts/instalar_certificados_icp_brasil.sh, seguido de update-ca-certificates.
Dependências: original_scripts/instalar_certificados_icp_brasil.sh, update-ca-certificates.
Execução: Paralela (Passo 6).

04-browsers.sh
Finalidade: Configura navegadores Firefox (stable e ESR) via /etc/firefox-manager.sh.
Dependências: /etc/firefox-manager.sh (deve existir no sistema).
Execução: Paralela (Passo 6).

05-tokens.sh
Finalidade: Configura drivers proprietários de tokens (G&D SafeSign via tokenGD.sh e Safenet via safenet.sh), cria links simbólicos para CARREGAdriverTOKEN.sh.
Dependências: /etc/tokenGD.sh, /etc/safenet.sh; wait_for_apt_unlock.
Execução: Sequencial (Passo 7).

06-icp-user-certs.sh
Finalidade: Prepara a importação de certificados ICP para usuários existentes e futuros (via /etc/skel), copiando scripts/import-icp-brasil.sh e scripts/import-certs.desktop. Configura também permissões Flatpak para Chromium, Firefox, Chrome, Edge e Brave.
Dependências: scripts/import-icp-brasil.sh, scripts/import-certs.desktop, flatpak.
Execução: Paralela (Passo 6).

07-kaspersky.sh
Finalidade: Instalação/Configuração do antivírus Kaspersky.
Dependências: APT lock liberado.
Execução: Paralela (Passo 6).

08-wine.sh
Finalidade: Instalação do Wine (repositório WineHQ configurado pelo main.sh).
Dependências: Chave GPG do WineHQ (/usr/share/keyrings/winehq.gpg), repositório WineHQ.
Execução: Sequencial (Passo 7).

09-signers.sh
Finalidade: Instala libssl1.1 (obrigatória para assinadores legados) e WebPKI. Instala também assinadores Shodō e PJe Office a partir de /tmp/cache/ (se disponíveis). Falhas em libssl1.1 e WebPKI abortam o módulo; falhas nos demais geram apenas aviso.
Dependências: download_with_cache, dpkg, apt-get --fix-broken, /tmp/cache/pje-office*.deb, /tmp/cache/shodo*.deb.
Execução: Sequencial (Passo 7).

10-backup.sh
Finalidade: Instala a ferramenta de backup Proxmox, executando original_scripts/proxmoxbackupclient.sh. Só executa se ENABLE_BACKUP=true no perfil.
Dependências: original_scripts/proxmoxbackupclient.sh, load_om_ips, wait_for_apt_unlock.
Execução: Sequencial (Passo 7).

11-flatpak-cache.sh
Finalidade: Instala pacotes Flatpak usando cache NFS montado pelo main.sh. Só executa se ENABLE_FLATPAK_CACHE=true. Adiciona repositório Flathub se ausente; usa --sideload-repo quando cache disponível.
Pacotes base: org.bleachbit.BleachBit, org.keepassxc.KeePassXC, com.obsproject.Studio, org.jitsi.jitsi-meet.
Se ENABLE_HEALTH_APPS=true: adiciona io.github.nroduit.Weasis e br.app.pw3270.terminal.
Se ENABLE_HEALTH_APPS=false: adiciona org.onlyoffice.desktopeditors.
Dependências: Cache NFS montado em /mnt com FLATPAK_MAINT_REPO_PATH; flatpak; load_om_ips.
Execução: Paralela (Passo 8).

12-desktop-config.sh
Finalidade: Configurações de desktop (tema, wallpaper, atalhos) para o sistema.
Dependências: Ambiente gráfico.
Execução: Paralela (Passo 8).

13-desktop-config-user.sh
Finalidade: Configurações de desktop específicas do usuário (perfil de aparência, extensões).
Dependências: $HOME do usuário, ambiente gráfico.
Execução: Paralela (Passo 8).

14-security.sh
Finalidade: Configurações de segurança: cria /etc/enableprinter.sh (reativação de impressoras), configura /etc/default/smartmontools, aplica regras hosts.allow/hosts.deny a partir das variáveis hostsallow0-3 e hostsdeny do perfil (carregadas de /etc/om.ips).
Dependências: cupsenable, lpstat, smartmontools, /etc/om.ips.
Execução: Paralela (Passo 9).

15-kvm-menu.sh
Finalidade: Cria atalho no menu de aplicações para instalação manual do KVM, copiando scripts/install-kvm.sh para /usr/local/bin/ e scripts/install-kvm.desktop para /usr/share/applications/.
Dependências: scripts/install-kvm.sh, scripts/install-kvm.desktop.
Execução: Paralela (Passo 9).


_3. Tratamento de Erros_

O main.sh executa módulos com set +e para capturar falhas sem interromper o fluxo, registrando os módulos falhos no array FAILED_MODULES:

```bash
run_script() {
    ...
    set +e
    bash "$script_path" >> "$log_file" 2>&1
    local ret=$?
    set -e
    if [ $ret -ne 0 ]; then
        log_error "MÓDULO $script_name FALHOU (código $ret)"
        FAILED_MODULES+=("$script_name")
    fi
    ...
}
```

Ao final, se houver falhas e --skip-errors não estiver ativo, o script aborta com código 1.
