# zorin_corporate_configs
By arthur-aida: A set of scripts to optimize Zorin OS 18.1 for corporate use.

MIT License

Copyright (c) 2026 [arthur.aida@gmail.com]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

====RECOMENDA-SE LER A DOCUMENTAÇÃO NA PASTA Docs ANTES DE PROSSEGUIR====

1-Abra um terminal e digite <cd /tmp/>. Faça o download dos scripts com:
<wget https://github.com/arthur-aida/zorin_corporate_configs/archive/refs/heads/main.zip -O /tmp/customization.zip>

2-Descompate-o com o comando <unzip -q /tmp/customization.zip -d /tmp/customization/> 

3-Mude o caminho para /tmp/customization/zorin_corporate_configs-main com <cd /tmp/customization/zorin_corporate_configs-main>

4-Eleve-se ao sudo com <sudo su> e forneça a senha do administrador

5-Crie o diretorio /etc/customization com o comando <mkdir /etc/customization/>

6-Execute <cp -r /tmp/customization/zorin_corporate_configs-main/* /etc/customization/>

7-Mude o caminho com <cd /etc/customization/>

8-Inicie a customização com o comando: <bash main.sh 2 2>&1 | tee /tmp/main.log; mv /tmp/main.log /var/log/customization-persist/main.log>

9-O comando acima realiza a customização conforme a documentação e copia o log para persistencia e auditoria.  

10-Os comandos dentro de < > devem ser digitados ou copiados e colados no terminal.

11-Opcionalmente para otimitizar o processo, abra o terminal, copie e cole o texto abaixo para executar os processos acima de forma automatizada:

sudo bash -c "mkdir -p /etc/customization/ /var/log/customization-persist/ && rm -rf /tmp/customization* && wget https://github.com/arthur-aida/zorin_corporate_configs/archive/refs/heads/main.zip -O /tmp/customization.zip && unzip -q /tmp/customization.zip -d /tmp/customization/ && cp -r /tmp/customization/zorin_corporate_configs-main/* /etc/customization/ && cd /etc/customization/ && chmod +x main.sh && ./main.sh 2 2>&1 | tee /var/log/customization-persist/main.log"

12-POR SEGURANÇA INSPECIONE O CONTEÚDO DE TODOS OS SCRIPTS ANTES DE EXECUTAR QUAISQUER DOS COMANDOS ACIMA.
