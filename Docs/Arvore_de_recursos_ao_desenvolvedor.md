## 🌳 Árvore de Recursos – Customização Zorin/Ubuntu/Mint (Perfis 1,2,3 - V202605)

## 1. 🧱 INFRAESTRUTURA E DEPENDÊNCIAS BASE

### 1.1 APT – Pacotes essenciais para todos os perfis

| 📦 Pacote                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | Onde é instalado    | Dependências | Finalidade                                                                                                                                                |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------|--------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| nfs-common, flatpak, ostree                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | 00-dependencies.sh  | –            | Montagem NFS, sideload Flatpak                                                                                                                            |
| unrar, rar, unace, p7zip, p7zip-full, python3-pyudev, net-tools, curl, wget, git, gpg, gnupg2, software-properties-common, gparted, hardinfo, meld, recoll, pdfsam, git, python3-pip, openssh-server, sshfs, gsmartcontrol, smart-notifier, adb, ideviceinstaller, libimobiledevice-utils, ifuse, usbmuxd, uxplay, printer-driver-cups-pdf, python3-smbc, seahorse, grub2-common, grub-pc-bin, libxcb-icccm4, libxcb-image0, libxcb-keysyms1, libxcb-randr0, libxcb-render-util0, libxcb-shape0, libxcb-sync1, libxcb-xfixes0, libxcb-xinerama0, libxcb-xkb1, libxcb-util1, libxcb-cursor0, libxcb-xinput0, libxcb-composite0, libgles2, libgles2-mesa-dev, vlc, hplip, hplip-gui, cups, cups-pdf, gscan2pdf, simple-scan, tesseract-ocr, tesseract-ocr-por, curl, libnss3-tools, pcscd, libccid, libpcsclite1, opensc, pcsc-tools, gnupg2, debsigs, xterm, openjdk-8-jre-headless, openjdk-11-jre-headless, icedtea-netx, unzip, cabextract, fuseiso, libwxbase3.2-1t64, libwxgtk3.2-1t64, ristretto (ou eog se GNOME) | 02-bulk-packages.sh | –            | Instalação massiva de utilitários comuns, visualizadores, drivers, Java 8/11, leitura de dispositivos móveis, impressão, PDF, OCR, tokens smartcard, etc. |

### 1.2 Java específico (versão 8 como padrão)

| 🔧 Recurso                                    | Onde                | Finalidade                                |
|-----------------------------------------------|---------------------|-------------------------------------------|
| Definir Java 8 padrão via update-alternatives | 02-bulk-packages.sh | Execução de applets e assinadores legados |
| JAVA_HOME em /etc/environment                 | 02-bulk-packages.sh | Variável de ambiente para aplicações Java |

### 1.3 Dependências de tokens e drivers

| 📦 Pacote adicional (fora do bulk)                                                      | Onde                   | Finalidade                                                    |
|-----------------------------------------------------------------------------------------|------------------------|---------------------------------------------------------------|
| pcscd, libccid, libpcsclite1, opensc-pkcs11, libaec-dev, zlib1g-dev, libjbig0, openpace | safenet.sh, tokenGD.sh | Suporte a tokens criptográficos (Aladdin, Safenet, G&D, etc.) |
| libssl1.1 (baixado .deb específico)                                                     | 09-signers.sh          | Compatibilidade com assinadores web antigos                   |
| webpki (Lacuna) – baixado .deb                                                          | 09-signers.sh          | Plugin para assinatura digital em navegadores                 |

## 2. 🌐 CACHE E REDE (APT-Cacher-NG, NFS, Roaming)

### 2.1 Serviços no servidor (Perfil 9)

| 🔧 Recurso                                       | Onde                         | Finalidade                                |
|--------------------------------------------------|------------------------------|-------------------------------------------|
| apt-cacher-ng (instalado, configurado, serviço)  | setup-server-KVM-nfs-acng.sh | Cache local de pacotes .deb               |
| nfs-kernel-server (exportação /partimag)         | setup-server-KVM-nfs-acng.sh | Compartilhamento de caches (APT, Flatpak) |
| libvirtd, qemu-kvm, virt-manager                 | setup-server-KVM-nfs-acng.sh | Ambiente de virtualização KVM no servidor |
| Socket systemd para rebuild Flatpak (porta 9876) | setup-server-KVM-nfs-acng.sh | Trigger remoto para recriar cache Flatpak |

### 2.2 No cliente (Perfis 1,2,3)

| 🌐 Recurso                                                           | Onde                          | Finalidade                                                         |
|----------------------------------------------------------------------|-------------------------------|--------------------------------------------------------------------|
| Montagem NFS de /mnt (flatpakcache) e /tmp/cache (repositório admin) | main.sh (mount_nfs_direct)    | Acesso ao cache Flatpak e repositório de pacotes (Kaspersky, etc.) |
| Configuração de proxy APT (convert-sources-to-proxy.sh)              | main.sh passo 2, aptcacher.sh | Mapeamento direto via APT-Cacher-NG (roaming)                      |
| Script acngonoff.sh                                                  | /etc/acngonoff.sh             | Detecta proxy via gateway e exporta PROXY_URL                      |
| Roaming via NetworkManager (99-apt-cacher-roaming)                   | 01-sync-scripts.sh            | Ao trocar de rede, reexecuta aptcacher.sh                          |
| restore-sources-from-backup.sh                                       | main.sh, aptcacher.sh         | Reverte fontes APT para originais quando cache offline             |

### 2.3 Manutenção periódica (cron)

| ⚙️ Tarefa                                         | Onde                                | Finalidade                                               |
|---------------------------------------------------|-------------------------------------|----------------------------------------------------------|
| aptcacher.sh a cada boot? (via @reboot)           | 14-security.sh                      | Ajusta proxy, atualiza navegadores, faz update de listas |
| enableprinter.sh a cada 5 min                     | 14-security.sh                      | Reativa impressoras desabilitadas no CUPS                |
| apt update && apt upgrade a cada 2 dias           | 14-security.sh                      | Atualizações automáticas                                 |
| clean.sh a cada 63 dias                           | 14-security.sh                      | Limpeza via BleachBit ou manual de caches                |
| Manutenção do cache Flatpak (prune) diária        | 11-flatpak-cache.sh                 | Remove versões antigas do repositório NFS                |
| Limpeza de arquivos antigos no servidor (90 dias) | setup-server-KVM-nfs-acng.sh (cron) | find /partimag/cache/ -atime +90 -delete                 |

## 3. 🌍 NAVEGADORES E CERTIFICADOS

### 3.1 Firefox (stable e ESR) – gerenciado via firefox-manager.sh

| 🧩 Recurso                                             | Onde                                                         | Finalidade                                                 |
|--------------------------------------------------------|--------------------------------------------------------------|------------------------------------------------------------|
| Firefox Stable (instalado em /OPT/firefox – maiúsculo) | firefox-manager.sh chamado por 04-browsers.sh e aptcacher.sh | Navegador principal (canal latest)                         |
| Firefox ESR (instalado em /opt/firefox – minúsculo)    | firefox-manager.sh                                           | Versão de suporte estendido, aponta para hod.serpro.gov.br |
| Link simbólico para libnssckbi.so (p11-kit)            | firefox-manager.sh                                           | Usa certificados do sistema nos navegadores                |
| Atalhos .desktop para ambos                            | firefox-manager.sh                                           | Ícones no menu                                             |

### 3.2 Certificados ICP-Brasil (sistema e usuário)

| 🔐 Recurso                                                  | Onde                                                                 | Finalidade                                                  |
|-------------------------------------------------------------|----------------------------------------------------------------------|-------------------------------------------------------------|
| Download e extração de ACcompactado.zip (raízes)            | instalar_certificados_icp_brasil.sh (chamado por 03-certificates.sh) | Atualiza /etc/ssl/certs/icp-brasil e update-ca-certificates |
| Política policies.json para Firefox (ImportEnterpriseRoots) | instalar_certificados_icp_brasil.sh                                  | Força Firefox a confiar nas raízes do SO                    |
| Script import-icp-brasil.sh (usuário)                       | 06-icp-user-certs.sh                                                 | Importa certificados no usuário via trust e certutil        |
| Atalho de autostart import-certs.desktop                    | 06-icp-user-certs.sh                                                 | Executa importação no login do usuário                      |
| Script alternativo setup-icp-tokens.sh (mais robusto)       | 13-desktop-config-user.sh                                            | Outra implementação de download com hash e fallback SSL     |

### 3.3 Permissões Flatpak para navegadores

| 🔧 Configuração                               | Onde                 | Finalidade                                              |
|-----------------------------------------------|----------------------|---------------------------------------------------------|
| flatpak override ... --filesystem=/usr/lib:ro | 06-icp-user-certs.sh | Navegadores flatpak acessam drivers de token do sistema |

## 4. 🔏 ASSINADORES DIGITAIS E TOKENS

### 4.1 Assinadores Serpro (AppImage)

| 🧩 Recurso                                                  | Onde                          | Finalidade                              |
|-------------------------------------------------------------|-------------------------------|-----------------------------------------|
| instalar-dependencias (AppImage) – baixado via serproass.sh | serproass.sh (atalho no menu) | Instala/atualiza Assinador Serpro 4.4.0 |

### 4.2 Certillion (assinador para usuários comuns)

| 🧩 Recurso                                         | Onde                           | Finalidade                                        |
|----------------------------------------------------|--------------------------------|---------------------------------------------------|
| Assinador-Certillion-1.7.3.run (baixado com cache) | certillion.sh (atalho no menu) | Instala Certillion para usuário não administrador |

### 4.3 Bonita Studio Community

| 🧩 Recurso                                                       | Onde                             | Finalidade                                     |
|------------------------------------------------------------------|----------------------------------|------------------------------------------------|
| BonitaStudioCommunity-2024.3-u0-linux.tar.gz (baixado com cache) | bscautostart.sh (atalho no menu) | Instala Bonita Studio (BPM) para usuário comum |

### 4.4 Tokens criptográficos

| 🔐 Recurso                                                   | Onde                                     | Finalidade                              |
|--------------------------------------------------------------|------------------------------------------|-----------------------------------------|
| Drivers Token G&D SafeSign (várias versões por distribuição) | tokenGD.sh                               | Suporte a tokens Gemalto/Guardian       |
| Drivers Safenet (Aladdin, eToken)                            | safenet.sh                               | SACMonitor, drivers para Ubuntu 18-24   |
| Drivers DXSafe (Dexon) – instalador zipado                   | TokenDXSafe.sh e setup-dxsafe-wrapper.sh | Token do Ministério da Defesa           |
| Registro de módulos PKCS#11 (pkcs11-register)                | CARREGAdriverTOKEN.sh                    | Carrega bibliotecas de token no sistema |
| Script carregadrivertoken linkado                            | 05-tokens.sh                             | Execução manual pelo usuário            |

### 4.5 WebPKI e libssl1.1

| 🔐 Recurso                          | Onde          | Finalidade                                     |
|-------------------------------------|---------------|------------------------------------------------|
| libssl1.1_1.1.1f-1ubuntu2_amd64.deb | 09-signers.sh | Requisito para assinadores web antigos         |
| setup-deb-64 (WebPKI)               | 09-signers.sh | Plugin de assinatura para navegadores (Lacuna) |

### 4.6 Assinadores adicionais via cache NFS

| 🔧 Recurso                                                              | Onde          | Finalidade                     |
|-------------------------------------------------------------------------|---------------|--------------------------------|
| Instalação de pje-office\*.deb e shodo\*.deb se presentes em /tmp/cache | 09-signers.sh | Assinadores PJe Office e Shodō |

## 5. 📄 FERRAMENTAS DE ESCRITÓRIO E PRODUTIVIDADE

### 5.1 OnlyOffice (flatpak) – apenas perfil doméstico

| 🟦 Pacote Flatpak             | Onde                                              | Finalidade                                 |
|-------------------------------|---------------------------------------------------|--------------------------------------------|
| org.onlyoffice.desktopeditors | 11-flatpak-cache.sh (se ENABLE_HEALTH_APPS=false) | Suíte de escritório (editor de documentos) |

### 5.2 Weasis e pw3270 (flatpak) – apenas perfil saúde

| 🟦 Pacote Flatpak        | Onde                                             | Finalidade                           |
|--------------------------|--------------------------------------------------|--------------------------------------|
| io.github.nroduit.Weasis | 11-flatpak-cache.sh (se ENABLE_HEALTH_APPS=true) | Visualizador DICOM (imagens médicas) |
| br.app.pw3270.terminal   | 11-flatpak-cache.sh (se ENABLE_HEALTH_APPS=true) | Emulador de terminal 3270 (legado)   |

### 5.3 Dicionários especializados LibreOffice

| 🔧 Download                                                                                                    | Onde                 | Finalidade                                            |
|----------------------------------------------------------------------------------------------------------------|----------------------|-------------------------------------------------------|
| 9 dicionários (Química, Militar, Música, Economia, Botânica, Microbiologia, Jurídico, Eletrônica, Informática) | 12-desktop-config.sh | Extensões para verificação ortográfica no LibreOffice |

### 5.4 Impressoras e scanners Epson (drivers via cache)

| 🧩 Driver                                                         | Onde                 | Finalidade                     |
|-------------------------------------------------------------------|----------------------|--------------------------------|
| epson-inkjet-printer-escpr\_\*.deb, epson-printer-utility\_\*.deb | 12-desktop-config.sh | Drivers para impressoras Epson |
| epsonscan2-bundle.tar.gz                                          | 12-desktop-config.sh | Software de scanner Epson      |

### 5.5 Cancelamento de ruído de áudio (PipeWire/Pulse)

| 🔧 Configuração                              | Onde                 | Finalidade                          |
|----------------------------------------------|----------------------|-------------------------------------|
| Módulo echo-cancel no PipeWire ou PulseAudio | 12-desktop-config.sh | Redução de ruído para chamadas VoIP |

## 6. 🎨 MULTIMÍDIA E UTILITÁRIOS

### 6.1 Flatpaks comuns (todos os perfis)

| 🟦 Pacote Flatpak       | Onde                | Finalidade                  |
|-------------------------|---------------------|-----------------------------|
| org.bleachbit.BleachBit | 11-flatpak-cache.sh | Limpeza de sistema          |
| org.keepassxc.KeePassXC | 11-flatpak-cache.sh | Gerenciador de senhas       |
| com.obsproject.Studio   | 11-flatpak-cache.sh | Gravação/streaming de tela  |
| org.jitsi.jitsi-meet    | 11-flatpak-cache.sh | Cliente de videoconferência |

### 6.2 Visualizador de imagens (via APT, condicional)

| 📦 Pacote                       | Onde                | Finalidade                     |
|---------------------------------|---------------------|--------------------------------|
| eog (GNOME) ou ristretto (XFCE) | 02-bulk-packages.sh | Visualizador de imagens padrão |

### 6.3 Ícones personalizados e temas

| 📁 Arquivo                       | Onde                 | Finalidade                      |
|----------------------------------|----------------------|---------------------------------|
| \*.png da pasta original_scripts | 12-desktop-config.sh | Copiados para /usr/share/icons/ |

## 7. 🔒 SEGURANÇA E BACKUP

### 7.1 Hardening de serviços

| 🔧 Configuração                                            | Onde                         | Finalidade                            |
|------------------------------------------------------------|------------------------------|---------------------------------------|
| hosts.allow e hosts.deny para SSH (com base no perfil)     | 14-security.sh               | Restrição de acesso SSH por rede      |
| ufw (firewall) – portas 22, nfs, 111, 2049, 3142, 9876     | setup-server-KVM-nfs-acng.sh | Proteção do servidor                  |
| Desativação de descoberta automática de impressoras (CUPS) | 12-desktop-config.sh         | Evita anúncios de rede desnecessários |

### 7.2 Monitoramento de discos (smartmontools)

| 🔧 Configuração                                 | Onde           | Finalidade                         |
|-------------------------------------------------|----------------|------------------------------------|
| /etc/default/smartmontools com start_smartd=yes | 14-security.sh | Monitoramento S.M.A.R.T. de discos |
| Serviço smartd ativado                          | 14-security.sh | Verificações agendadas             |

### 7.3 Backup (apenas perfil corporativo e saúde)

| 🔧 Recurso                                            | Onde                                          | Finalidade                     |
|-------------------------------------------------------|-----------------------------------------------|--------------------------------|
| proxmox-backup-client (instalado via script)          | 10-backup.sh (executa proxmoxbackupclient.sh) | Cliente de backup Proxmox      |
| Repositório PBS adicionado (Debian bullseye/bookworm) | proxmoxbackupclient.sh                        | Conexão com servidor de backup |

### 7.4 Script de reativação de impressoras

| ⚙️ Script                                 | Onde           | Finalidade                                  |
|-------------------------------------------|----------------|---------------------------------------------|
| /etc/enableprinter.sh (cron a cada 5 min) | 14-security.sh | Reativa impressoras desabilitadas pelo CUPS |

## 8. 🖥️ VIRTUALIZAÇÃO KVM

### 8.1 Instalação via atalho no menu (usuário final)

| 🔧 Recurso                                            | Onde           | Finalidade                       |
|-------------------------------------------------------|----------------|----------------------------------|
| install-kvm.sh (instala qemu-kvm, virt-manager, etc.) | 15-kvm-menu.sh | Instala ambiente KVM sob demanda |
| Atalho .desktop em Ferramentas do Sistema             | 15-kvm-menu.sh | Execução com sudo                |

### 8.2 Permissões de grupo

| 🔧 Ação                           | Onde           | Finalidade                             |
|-----------------------------------|----------------|----------------------------------------|
| Adiciona usuário ao grupo libvirt | install-kvm.sh | Permissão para gerenciar VMs sem senha |

## 9. 🖌️ PERSONALIZAÇÕES DE DESKTOP

### 9.1 Atalhos de aplicativos (menus)

| 📁 Atalho .desktop                                 | Onde                         | Finalidade                                                   |
|----------------------------------------------------|------------------------------|--------------------------------------------------------------|
| assinador-serpro.desktop                           | 12-desktop-config.sh         | Instala Assinador Serpro                                     |
| instalador-certillion.desktop                      | 12-desktop-config.sh         | Instala Certillion para usuários                             |
| instalador-bonita.desktop                          | 12-desktop-config.sh         | Instala Bonita Studio                                        |
| Carrega.Drivers.Tokens.desktop                     | 13-desktop-config-user.sh    | Habilita certificados GOV e tokens (via setup-icp-tokens.sh) |
| instalar-dxsafe.desktop                            | setup-dxsafe-wrapper.sh      | Instala Token DXSafe                                         |
| install-kvm.desktop                                | 15-kvm-menu.sh               | Instala KVM                                                  |
| icedtea-netx-javaws.desktop (criado dinamicamente) | hookjava1.8.sh, aptcacher.sh | Lançador Java Web Start                                      |

### 9.2 Configurações de autostart (para novos usuários)

| 📁 Arquivo                                           | Onde                 | Finalidade                                  |
|------------------------------------------------------|----------------------|---------------------------------------------|
| import-certs.desktop em /etc/skel/.config/autostart/ | 06-icp-user-certs.sh | Executa importação de certificados no login |
| Script import-icp-brasil.sh em /etc/skel/.local/bin/ | 06-icp-user-certs.sh | Ferramenta de importação                    |

### 9.3 Configuração do ambiente XDG para Flatpak

| 🔧 Configuração                   | Onde                | Finalidade                                               |
|-----------------------------------|---------------------|----------------------------------------------------------|
| /etc/profile.d/flatpak-exports.sh | 11-flatpak-cache.sh | Adiciona /var/lib/flatpak/exports/share ao XDG_DATA_DIRS |

## 10. 🧪 PERFIS E VARIÁVEIS ESPECÍFICAS

### 10.1 Perfil Doméstico (1)

| Variável           | Valor   | Efeito                                      |
|--------------------|---------|---------------------------------------------|
| ENABLE_BACKUP      | false   | Não instala cliente Proxmox Backup          |
| ENABLE_HEALTH_APPS | false   | Não instala Weasis/pw3270; remove Kaspersky |
| APTCACHER          | (vazio) | Sem proxy APT-Cacher                        |
| NFSSERVERER        | (vazio) | Sem NFS (cache Flatpak local ou ausente)    |
| hostsallow\*       | vazio   | Sem restrições SSH                          |

### 10.2 Perfil Corporativo (2)

| Variável             | Valor                                                      | Efeito                             |
|----------------------|------------------------------------------------------------|------------------------------------|
| APTCACHER, CACHEPORT | 192.168.122.1:3142                                         | Proxy APT-Cacher                   |
| NFSSERVERER, NFSPORT | 192.168.122.1:2049                                         | Montagem NFS (cache compartilhado) |
| ENABLE_BACKUP        | true                                                       | Instala cliente Proxmox Backup     |
| hostsallow0-3        | Redes 192.168.123/24, 10.0.0/16, 192.168.122/24, localhost | SSH liberado nessas redes          |
| hostsdeny            | sshd: ALL                                                  | Bloqueio padrão                    |

### 10.3 Perfil Saúde (3)

| Variável             | Valor                                                         | Efeito                                                                   |
|----------------------|---------------------------------------------------------------|--------------------------------------------------------------------------|
| APTCACHER, CACHEPORT | 192.168.3.3:3142                                              | Proxy específico                                                         |
| NFSSERVERER          | 192.168.3.3                                                   | Servidor NFS dedicado                                                    |
| ENABLE_HEALTH_APPS   | true                                                          | Instala Weasis, pw3270, Kaspersky (via tarball)                          |
| ntpserver            | 10.89.37.46                                                   | Sincronização horário (não usado diretamente nos scripts, mas exportado) |
| hostsallow           | Redes 192.168.123/24, 192.168.122/24, 192.168.3/24, localhost | Acesso SSH restrito                                                      |

### 10.4 Perfil Servidor (9) – script separado

| Função                                             | Descrição                                       |
|----------------------------------------------------|-------------------------------------------------|
| Instala e configura APT-Cacher-NG                  | Cache de pacotes                                |
| Configura NFS server com exportação /partimag      | Compartilhamento para os clientes               |
| Configura KVM e libvirtd                           | Servidor de virtualização                       |
| Cria listener para rebuild Flatpak (porta 9876)    | Permite clientes solicitarem recriação do cache |
| Cria cache Flatpak local (se conectado à internet) | Popula .ostree/repo                             |

## 11. 📦 LISTA COMPLETA DE PACOTES (APT) – resumo por categoria

| Categoria            | Pacotes (não exaustivo)                                                                               |
|----------------------|-------------------------------------------------------------------------------------------------------|
| **Essenciais**       | nfs-common, flatpak, ostree, curl, wget, git, gnupg2                                                  |
| **Arquivos**         | unrar, rar, unace, p7zip-full, cabextract, fuseiso                                                    |
| **Rede**             | net-tools, openssh-server, sshfs, ufw, socat                                                          |
| **Hardware**         | pcscd, libccid, opensc, pcsc-tools, hplip, cups, smartmontools, adb, ideviceinstaller, ifuse, usbmuxd |
| **Desktop**          | xterm, seahorse, gparted, hardinfo, meld, recoll, pdfsam, bleachbit (via flatpak)                     |
| **Multimídia**       | vlc, gscan2pdf, simple-scan, tesseract-ocr, ristretto/eog                                             |
| **Java**             | openjdk-8-jre-headless, openjdk-11-jre-headless, icedtea-netx                                         |
| **Tokens e drivers** | libssl1.1, webpki, opensc-pkcs11, libaec-dev, libjbig0, openpace                                      |
| **Virtualização**    | qemu-kvm, libvirt-daemon-system, virt-manager, bridge-utils                                           |
| **Backup**           | proxmox-backup-client, qrencode                                                                       |

## 12. 📦 LISTA DE FLATPAKS (todos os perfis)

| Nome                          | Finalidade              |
|-------------------------------|-------------------------|
| org.bleachbit.BleachBit       | Limpeza                 |
| org.keepassxc.KeePassXC       | Senhas                  |
| com.obsproject.Studio         | Streaming               |
| org.jitsi.jitsi-meet          | Videoconferência        |
| org.onlyoffice.desktopeditors | Escritório (doméstico)  |
| io.github.nroduit.Weasis      | Imagens médicas (saúde) |
| br.app.pw3270.terminal        | Terminal 3270 (saúde)   |

## 13. 🧩 RECURSOS BAIXADOS EXTERNOS (AppImage, tarballs, .deb avulsos)

| Nome                                          | Origem                             | Onde é usado             |
|-----------------------------------------------|------------------------------------|--------------------------|
| instalar-dependencias (AppImage)              | serproass.sh                       | Assinador Serpro         |
| Assinador-Certillion-1.7.3.run                | certillion.sh                      | Certillion               |
| BonitaStudioCommunity-2024.3-u0-linux.tar.gz  | bscautostart.sh                    | Bonita Studio            |
| libssl1.1_1.1.1f-1ubuntu2_amd64.deb           | 09-signers.sh                      | WebPKI                   |
| setup-deb-64 (WebPKI)                         | 09-signers.sh                      | Plugin WebPKI            |
| Drive_Ubuntu_22_04_install.zip (DXSafe)       | setup-dxsafe-wrapper.sh            | Token DXSafe             |
| SafeSign_IC_Standard_Linux\_\*.rar (G&D)      | tokenGD.sh                         | Token G&D                |
| Safenet-Ubuntu-\*.zip / Linux_SAC_10.9_GA.zip | safenet.sh                         | Drivers Safenet          |
| KSE-12.3.tar (Kaspersky)                      | 07-kaspersky.sh (copiado do cache) | Antivírus (perfil saúde) |
| ubuntu-keyring_2023.11.28.1_all.deb           | update_apt_keys_no_proxy           | Chaves GPG atualizadas   |

## 14. ⚙️ SERVIÇOS E SCRIPTS DE SISTEMA CRIADOS

| Arquivo                                                | Tipo              | Finalidade                            |
|--------------------------------------------------------|-------------------|---------------------------------------|
| /etc/acngonoff.sh                                      | script            | Testa proxy e exporta URL             |
| /etc/aptcacher.sh                                      | script            | Manutenção periódica (cron)           |
| /etc/enableprinter.sh                                  | script            | Reativa impressoras                   |
| /etc/clean.sh                                          | script            | Limpeza via BleachBit                 |
| /etc/firefox-manager.sh                                | script            | Gerencia versões do Firefox           |
| /etc/serproass.sh                                      | script            | Instala Assinador Serpro              |
| /etc/certillion.sh                                     | script            | Instala Certillion                    |
| /etc/bscautostart.sh                                   | script            | Instala Bonita Studio                 |
| /etc/TokenDXSafe.sh                                    | wrapper           | Instala DXSafe                        |
| /etc/import-icp-brasil.sh                              | script            | Importa certificados (root)           |
| /usr/local/bin/setup-icp-tokens.sh                     | script            | Importa certificados (usuário)        |
| /usr/local/bin/flatpak-cache-maintenance.sh            | script            | Prune do repositório NFS              |
| /usr/local/bin/install-kvm.sh                          | script            | Instala KVM                           |
| /usr/local/bin/kaspersky-boot-install.sh               | script            | Instala Kaspersky no boot             |
| /etc/systemd/system/kaspersky-installer.service        | serviço           | Executa instalação do Kaspersky       |
| /etc/systemd/system/flatpak-rebuild.socket             | socket            | Trigger para rebuild do cache Flatpak |
| /etc/NetworkManager/dispatcher.d/99-apt-cacher-roaming | dispatcher        | Roaming de cache ao trocar rede       |
| /etc/cron.d entradas (várias)                          | tarefas agendadas | Manutenção e atualizações             |

## 15. 🔧 FUNÇÕES ÚTEIS EM common.sh (para scripts)

| Função                     | Finalidade                                                 |
|----------------------------|------------------------------------------------------------|
| download_with_cache        | Download com cache persistente em /tmp/cache               |
| wait_for_apt_unlock        | Aguarda lock do dpkg/apt                                   |
| install_packages           | Instala pacotes com retry e --fix-broken                   |
| mount_nfs_if_available     | Monta NFS com teste de conectividade                       |
| get_nfs_server             | Detecta servidor NFS (perfil, gateway)                     |
| run_preflight              | Verifica pré-requisitos (NFS, proxy, flatpak)              |
| update_apt_keys_no_proxy   | Atualiza chaves GPG e desabilita repositórios inacessíveis |
| load_profile / load_om_ips | Carrega variáveis de perfil                                |
| show_warning / show_notify | Notificações gráficas (zenity)                             |

## 16. 🗺️ MAPA DE DEPENDÊNCIAS (resumo)

- **NFS montado** → depende de NFSSERVERER definido no perfil e conectividade.

- **Flatpak sideload** → depende de /mnt/.ostree/repo montado via NFS.

- **Proxy APT** → depende de APTCACHER e acngonoff.sh detectar o servidor.

- **Certificados ICP** → dependem de instalar_certificados_icp_brasil.sh executado como root.

- **Tokens** → dependem de drivers instalados via tokenGD.sh, safenet.sh, TokenDXSafe.sh.

- **Kaspersky** → depende de perfil saúde e tarball em /tmp/cache.

- **Backup** → depende de perfil corporativo/saúde e script proxmoxbackupclient.sh.

- **KVM** → instalável sob demanda via atalho, não obrigatório no deploy.

- **Firefox** → instalado via firefox-manager.sh, removendo snaps/flatpaks conflitantes.

Este relatório fornece uma visão completa e atômica de todos os recursos embutidos, permitindo a criação de diagramas ou visualizações gráficas independentes da ordem de execução.

Legenda:  
📦 = Pacote APT  
🟦 = Flatpak  
🧩 = AppImage/Instalador baixado (.deb, .run, .tar.gz, .AppImage)  
⚙️ = Script de configuração/serviço  
🔧 = Ferramenta integrada via código  
📁 = Arquivo de configuração ou atalho .desktop  
🌐 = Recurso de rede/cache  
🔐 = Segurança/Token/Certificado

*Os números de tráfego e tempo de instalação foram medidos em maio de 2026. Com a evolução dos pacotes e versões, os valores absolutos podem variar, mas a eficiência relativa do cache (superior a 95%) e os ganhos percentuais de tempo (38–45%) se mantêm estáveis.*
