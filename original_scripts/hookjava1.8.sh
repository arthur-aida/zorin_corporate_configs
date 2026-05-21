#!/bin/bash
# Este script cria um gancho para que APPLETS JAVA sejam executados pela versão específica do java em /usr/local/jre1.8.0_221/ 
# echo "Chamada do script: "$(basename $0) "-----------------------------------------------------------------------------------------------------------"

if [ ! -f /usr/share/applications/icedtea-netx-javaws.desktop ]; then
    cat > /usr/share/applications/icedtea-netx-javaws.desktop << 'EOF3'
[Desktop Entry]
Name=IcedTea Web Start
GenericName=Java Web Start
Comment=IcedTea Application Launcher
Exec=/usr/local/jre1.8.0_221/bin/javaws %u
Icon=javaws
Terminal=false
Type=Application
NoDisplay=true
Categories=Application;Network;
MimeType=application/x-java-jnlp-file;x-scheme-handler/jnlp;x-scheme-handler/jnlps
EOF3
    chmod 644 /usr/share/applications/icedtea-netx-javaws.desktop
    chmod +x /usr/share/applications/icedtea-netx-javaws.desktop
fi

