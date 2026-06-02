#!/bin/bash
#-------------------------------------------------------------------------------------------------------------------------------
# Este script instala o driver do token DXToken compilado pelo site acdefesa. O driver original de www.dexon.ind.br/downloads/ 
# é instável e pode não funcionar em certas condições e situações (snaps, flatpak e appimage pós atualizações).
# Este script considera a instalação do mozilla stable e ESR a partir dos binários obtidos no site da mozilla. Ver 04-browsers.sh 
#-------------------------------------------------------------------------------------------------------------------------------

# Desativar a Memória de video Compartilhada
export QT_X11_NO_MITSHM=1

source /etc/customization/utils/common.sh

bash /etc/acngonoff.sh
if [ ! -f /etc/Dexon/DXSafe/libDXSafePKCS11.x64.so ]; then 
	apt install net-tools cifs-utils curl git pcsc-tools pcscd cpuidtool libpcsclite-dev flex build-essential libusb-1.0-0-dev plocate -y -qq
	apt update -qq && apt full-upgrade -y -qq; apt --fix-broken install -y -qq

	apt-get install --reinstall pkg-config cmake-data --assume-yes -qq
	apt --fix-broken install -qq -y
download_with_cache "https://repositorio-acp.acdefesa.mil.br/Drivers_Token/Dexon/Ubuntu/Drive_Ubuntu_22_04_install.zip" "/tmp/DX_Ubuntu_22.04_LTS.zip"
	unzip -o -d /tmp /tmp/DX_Ubuntu_22.04_LTS.zip
	bash /tmp/instala_drive_DXSAFE_2_0_2.sh
	apt --fix-broken install
fi

# ajustes para que o driver do DXSafe da DXtoken carregue no ubuntu 24.04
if [ -f  /usr/lib/x86_64-linux-gnu/libcpuid.so.16 ] && [ ! -f /usr/lib/x86_64-linux-gnu/libcpuid.so.15 ]; then
	ln -s /usr/lib/x86_64-linux-gnu/libcpuid.so.16 /usr/lib/x86_64-linux-gnu/libcpuid.so.15
fi
cp -f /etc/Dexon/DXSafe/libDXSafePKCS11.x32.so /usr/lib/libDXSafePKCS11.x32.so
cp -f /etc/Dexon/DXSafe/libDXSafePKCS11.x64.so /usr/lib/libDXSafePKCS11.x64.so
if [ -d /etc/Dexon/DXSafe ]; then
	chattr -i /etc/Dexon/DXSafe/DXSafe.conf
	lsattr -d /etc/Dexon/DXSafe
	chattr -i /etc/Dexon/DXSafe
	chmod 644 /etc/Dexon/DXSafe/DXSafe.conf
	chmod 755 /etc/Dexon/DXSafe
fi

