#!/bin/bash
# clean.sh - Limpeza periódica de arquivos temporários

source /etc/customization/utils/common.sh
source /etc/customization/utils/logging.sh

if command -v bleachbit >/dev/null 2>&1; then
	# Lista reduzida aos itens mais impactantes
	flatpak run --command=bleachbit org.bleachbit.BleachBit -c \
	firefox.cache firefox.cookies firefox.dom \
	chromium.cache chromium.cookies chromium.dom \
	google_chrome.cache google_chrome.cookies google_chrome.dom \
	microsoft_edge.cache microsoft_edge.cookies microsoft_edge.dom \
	system.tmp system.trash
else
	# Fallback manual caso bleachbit não esteja disponível
	rm -rf /root/.cache/* /var/tmp/* 2>/dev/null || true
	find /home -maxdepth 3 -type d -name ".cache" -exec rm -rf {} \; 2>/dev/null || true
fi
log_info "O crontab disparou a limpeza programada a cada 63 dias"

