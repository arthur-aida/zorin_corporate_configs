Scripts Auxiliares

**1. Diretório scripts/**

_Arquivo	Finalidade_

```text
99-apt-cacher-roaming.sh	      Configuração de APT-Cacher para notebooks em roaming
convert-sources-to-proxy.sh       Converte fontes APT para usar proxy APT-Cacher
flatpak-cache-maintenance.sh	  Manutenção do cache Flatpak no servidor
import-certs.desktop	          Atalho de desktop para importação de certificados
import-icp-brasil.sh	          Importa certificados ICP-Brasil para usuários
install-kvm.sh	                  Instala KVM/libvirt
install-kvm.desktop	              Atalho de menu para instalação do KVM
restore-sources-from-backup.sh	  Restaura fontes APT originais (chamado pelo main.sh)

O main.sh faz referência explícita a scripts/restore-sources-from-backup.sh e scripts/convert-sources-to-proxy.sh.
```
**2. Diretório utils/**

_Arquivo	Finalidade_

```text

common.sh
Funções compartilhadas: check_root, load_om_ips, download_with_cache, wait_for_apt_unlock, etc.

fix-sources-list.sh
Correção de fontes APT (chamado no Passo 10)

logging.sh
Funções de log: log_info, log_error, log_warning, log_module_start, log_module_end

O main.sh chama utils/fix-sources-list.sh no final:

if [ -f "$SCRIPT_DIR/utils/fix-sources-list.sh" ]; then
    run_script "fix-sources-list" "$SCRIPT_DIR/utils/fix-sources-list.sh"
fi
```

**3. Diretório original_scripts/**

_Contém scripts legados que são invocados pelos módulos:_

```text
                                    Arquivo	Chamado por
CARREGAdriverTOKEN.sh	            05-tokens.sh (via links simbólicos)
TokenDXSafe.sh	                    Drivers Dexon
acngonoff.sh	                    main.sh (verificação de proxy APT)
aptcacher.sh	                    Configuração do APT-Cacher
bscautostart.sh	                    Autostart
instalar_certificados_icp_brasil.sh	03-certificates.sh
proxmoxbackupclient.sh	            10-backup.sh
safenet.sh	                        05-tokens.sh
tokenGD.sh	                        05-tokens.sh

O main.sh faz referência a /etc/acngonoff.sh para verificação do proxy.
```
