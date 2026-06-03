#!/bin/bash

# Garante que o script pare imediatamente se algum comando falhar
set -e

# Verifica se o script está rodando como ROOT (substitui o 'sudo su')
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute este script como root ou usando sudo: sudo bash $0"
  exit 1
fi

# Cria as pastas necessárias antes de mover os arquivos
echo "Preparando o sistema..."
mkdir -p /etc/customization/
mkdir -p /var/log/customization-persist/

# Limpa instalações anteriores na pasta /tmp para evitar conflitos
rm -rf /tmp/customization.zip /tmp/customization/

cd /tmp/

echo "Baixando as configurações corporativas..."
wget -q https://github.com/arthur-aida/zorin_corporate_configs/archive/refs/heads/main.zip -O /tmp/customization.zip

echo "Extraindo os arquivos..."
unzip -q /tmp/customization.zip -d /tmp/customization/

echo "Copiando arquivos de configuração..."
# Copia tudo para a pasta final (incluindo arquivos ocultos, se houver)
cp -r /tmp/customization/zorin_corporate_configs-main/* /etc/customization/

cd /etc/customization/

# Garante que o script principal tenha permissão de execução
chmod +x main.sh

echo "Iniciando a customização principal..."
# Executa salvando o log direto na pasta final, sem necessidade de mover depois
bash main.sh 2>&1 | tee /var/log/customization-persist/main.log

echo "Processo concluído com sucesso!"
