## Guia de Configuração do Ambiente do Deploy no KVM

**Notas explicativas da configuração inicial do ambiente de deploy com o Zorin OS 18.1 em laptop Ryzen 5 3500U, 16GB RAM, SSD 512GB NVMe.**

Este processo provisionará um ambiente de desenvolvimento que acelera os testes para desenvolvimento em máquinas virtuais com o KVM linux e caches em 3 níveis: **primeiro o cache via proxy** apt-cacher-NG, **segundo o cache de arquivos** **estáticos** (via NFS em /tmp/cache) e **terceiro o pseudo-cache do flatpak** (via NFS em /mnt/.ostree/repo/).

Abaixo a sequência de instruções que provisiona o proposto acima.

1-No laptop foi instalado o S.O. Zorin OS 18.1 e após o reinício foi realizado a atualização padrão;

2-Leia o README em [https://github.com/arthur-aida/zorin\_corporate\_configs](https://github.com/arthur-aida/zorin_corporate_configs);

3-Baixe e descompacte o conjunto de scripts;

4-Selecione a área destacada, copie e cole no terminal o comando abaixo para preparar o servidor:

sudo bash -c "mkdir -p /etc/customization/ /var/log/customization-persist/ && rm -rf /tmp/customization\* && wget [https://github.com/arthur-aida/zorin\_corporate\_configs/archive/refs/heads/main.zip](https://github.com/arthur-aida/zorin_corporate_configs/archive/refs/heads/main.zip) -O /tmp/customization.zip && unzip -q /tmp/customization.zip -d /tmp/customization/ && cp -r /tmp/customization/zorin\_corporate\_configs-main/\* /etc/customization/ && cd /etc/customization/ && chmod +x main.sh && ./main.sh 9 2\>&1 | tee /var/log/customization-persist/main.log”

5-Reinicie o laptop. Após o reboot, o KVM e os recursos de cache estarão ativos;

6-Abra o navegador Brave Web Browser e digite na barra de endereços “baixar o arquivo ISO do Zorin 18.1” e confirme com a tecla ENTER;

7-Nas páginas pesquisadas selecione o ícone Z em azul e branco e role a página até o frame “Zorin OS 18.1 **CORE**” e clique no **botão azul (Download)** dentro do mesmo frame;

8-Na próxima janela, clique na opção “Skip to download” que apresenta a janela de confirmação do nome do arquivo ISO a ser baixado na pasta Downloads do usuário atual;

9-Aguarde finalizar o download e feche o navegador Brave;

10-Localize no menu de Ferramentas a aplicação VMM ou clique no ícone Z e digite na barra de pesquisa (na lupa próximo ao ícone Z) a palavra “vmm” para filtrar a localização do aplicativo;

11-Passe o mouse sobre o ícone “VMM” e apresentar-se-á uma caixa explicativa preta com os dizeres “Gerenciador de máquinas virtuais” e clique sobre a opção do menu para abrir o VMM;

12-Clique no ícone para criar uma nova máquina virtual (é o monitor com uma estrela na parte superior direita, logo abaixo da palavra “Arquivo”);

13-Apresentar-se-á uma nova caixa com o título “Nova VM”. Este é o **Passo 1 de 5.** Clique em Avançar;

14-Na caixa “Nova VM”, **Passo 2 de 5**, clique no botão “Navegar”, “Navegar localmente”, clique na pasta “Downloads”, clique sobre o arquivo “Zorin-OS-18.1-Core-64-bit.iso” e sobre o ícone “Abrir”;

15-Desmarque a opção “Detectar automaticamente a partir da mídia/fonte de instalação”;

16-Na lupa acima digite “ubuntu” e selecione “Ubuntu 24.04 LTS” e em “Avançar”;

17-No **Passo 3 de 5**, em “Memória”, digite o valor referente a 1/3 da memória RAM total (por exemplo, se laptop possui 16 GB de RAM e video com memória compartilhada, digite “5120” ) e em “CPU”, digite a metade de X (considere o máximo de CPUs sob o valor sugerido “Até X disponíveis no laptop) e em “Avançar”;

18-Prosseguindo no **Passo 4 de 5**, substitua o valor de 25,0 por 79,0 e clique em “Avançar” (contempla o espaço para os snapshots. Nunca reutilize um drive virtual previamente instalado já com snapshots);

19-No **Passo 5 de 5**, marque a opção “Personalizar a configuração antes de instalar” e clique em “Concluir”;

*Na janela de gerenciamento do hardware da nova VM **não clique em “Iniciar a instalação”** ainda;*

*OS PRÓXIMOS PROCEDIMENTOS SÃO ESSENCIAIS PARA QUE A VM SEJA CONFIGURADA EM SEU POTENCIAL MÁXIMO (EM TORNO DE 97%) DO DESEMPENHO BRUTO DO LAPTOP E SEM MICROTRAVAMENTOS OU LAGS.*

*Clique em “**Adicionar hardware**” (na parte inferior a esquerda) e na janela “Adicionar um novo hardware virtual” em “**Controlador**” que dever ser configurado para “**SCSI**” e “**SCSI VirtIO**” e em “**Concluir**”;*

*Selecione o disco, provavelmente “Disco VirtIO” e altere o barramento do disco para “SCSI”, clique sobre “**Opções avançadas**”, nas opções para “**Modo de cache**” selecione “**none**”, para “**Modo de descarte**”, selecione a opção “**unmap**” e clique em **Aplicar** (na lateral direita na parte inferior) e o Disco será renomeado automaticamente para “Disco SCSI 1”;*

*Ainda na lista de hardware, selecione a opção “Exibição Spice” e em “Tipo de escuta” selecione a opção “Nenhum”. Marque a opção OpenGL e deverá habilitar a placa de video do laptop;*

*A seguir selecione o hardware “Video VirtIO” que deverá estar preselecionado em “VirtIO”. Clique sobre “Aceleração 3D” para remover a barra horizontal e deixar o marcado com o check “v” e por último clique em “Aplicar” (na lateral direita na parte inferior).*

Os números de desempenho levantados (8 a 10 min para o processo de customização completo) foram coletados **após** a configuração otimizada da VM acima descrita. As configurações acima permitem que a VM tenha o desempenho similiar ao LAPTOP com a benesse de manter SNAPSHOTS.

O processo de gerar snapshots é disponibilizado na t**erceira opção** do menu da VM: “Arquivo”,  
“Maquina Virtual”, “**Exibir**” e na terceira opção do menu dropdown “Snapshots” e clicar no sinal “+” para criar um novo snapshot (na parte inferior esquerda).

É recomendado fazer o **primeiro snapshot** logo ao reiniciar e desligar a VM **após a instalação** do S.O. via ISO. O **segundo snapshot após aplicar todas as atualizações** \[ abra o terminal com CTRL+ALT+T e digite: sudo apt update && sudo apt full-upgrade -y \], fechar o terminal e desligar. O **terceiro snapshot** **após deixar configurado no histórico do terminal,** todos os comandos a serem executados nas futuras restaurações deste snapshot, o que facilita a pesquisa no histórico do terminal e minimiza as digitações futuras quando o uso do terminal for intensivo.

20-Continuação pós instalação do Zorin OS 18.1 na VM (maquina virtual) criada no VMM até o passo 19;

21- Inicie a VM. Os próximos passos aproveitam-se do ambiente de desenvolvimento acelerado para testes com máquinas virtuais com os caches nos 3 níveis;

22- Abra o navegador e acesse o site do github.com, clique na barra da lupa sobre "SEARCH OR JUMP TO …" e digite os termos "desktop token a3" e tecle ENTER, no resultado clique no link zorin\_corporate\_configs. Copie o parágrafo iniciado por sudo até o caracter de aspas duplas. Cole no terminal e forneça a senha do administrador que executará os seguintes processos:

> Para iniciar a customização no perfil corporativo (2), a execução deste script pelo administrador cria pastas; baixa os scripts compactados em /tmp/customization.zip; descompacta-o na pasta /tmp/; cria a pasta /tmp/customization; copia o conteudo de “/tmp/customization\* para /etc/customization/”; muda o caminho para “/etc/customization/”; autoriza o script main.sh como executável; executa “bash main.sh 2 2\>&1 | tee /tmp/main.log; move o arquivo de log /tmp/main.log para /var/log/customization-persist/main.log”.

Ou, se o S.O. não possuir o unzip (copie como uma única linha):

> sudo apt install git -y && rm -rf /tmp/customization\* && git clone [https://github.com/arthur-aida/zorin\_corporate\_configs.git](https://github.com/arthur-aida/zorin_corporate_configs.git) /tmp/zorin\_corporate\_configs/ && sudo bash -c "mkdir -p /etc/customization/ /var/log/customization-persist/ && cp -r /tmp/zorin\_corporate\_configs/\* /etc/customization/ && cd /etc/customization/ && chmod +x main.sh && ./main.sh 2 2\>&1 | tee /var/log/customization-persist/main.log"

23-Os ambientes de desenvolvimento e da VM estão provisionados (laptop/desktop e VM do deploy).

*Os números de tráfego e tempo de instalação foram medidos em maio de 2026. Com a evolução dos pacotes e versões, os valores absolutos podem variar, mas a eficiência relativa do cache (superior a 95%) e os ganhos percentuais de tempo (38–45%) se mantêm estáveis.*

