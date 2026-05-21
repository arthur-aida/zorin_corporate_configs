#!/bin/bash
# The contents of this file are released under the GNU General Public License.
# Feel free to reuse the contents of this work, as long as the resultant works give proper
# attribution and are made publicly available under the GNU General Public License.
# https://www.gnu.org/licenses/gpl-faq.en.html#GPLRequireSourcePostedPublic
#-------------------------------------------------------------------------------------------------------------------------------
# Este script é um software livre; você pode redistribuí-lo e/ou
#  modificá-lo dentro dos termos da Licença Pública Geral GNU como
#  publicada pela Free Software Foundation (FSF); na versão 3 da
#  Licença, ou (a seu critério) qualquer versão posterior.
# Este programa é distribuído na esperança de que possa ser útil,
#  mas SEM NENHUMA GARANTIA; sem uma garantia implícita de ADEQUAÇÃO
#  a qualquer MERCADO ou APLICAÇÃO EM PARTICULAR. Veja a
#  Licença Pública Geral GNU para maiores detalhes.
#-------------------------------------------------------------------------------------------------------------------------------
# Este script instala o driver do token DXToken compilado pelo site acdefesa. O driver original de www.dexon.ind.br/downloads/ não funciona. 
# #-------------------------------------------------------------------------------------------------------------------------------
# 
# Partes deste script são adaptações de fontes disponíveis na internet. Objetivo preparar S.O. sabores ?BUNTU e DEBIAN para uso corporativo
# Compilado por arthur.aida@gmail.com
# Arquivos correlacionados em https://drive.google.com/drive/folders/1JU3TpAYm3-7nUWTZ0rGMWjidQbHo_jak?usp=sharing
# https://drive.google.com/drive/folders/187bEL4f0feeYIpuYWtGfd2QIl8orTylp

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
#	wget https://repositorio-acp.acdefesa.mil.br/Drivers_Token/Dexon/Ubuntu/Drive_Ubuntu_22_04_install.zip -O /tmp/DX_Ubuntu_22.04_LTS.zip
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

