## **RELATÓRIO INTEGRADO DE MIGRAÇÃO E OTIMIZAÇÃO DE SISTEMAS**

**Apresentação Geral:** Este documento consolida três relatórios independentes, porém interligados por

referências cruzadas, cada um direcionado a um público especíﬁco dentro da organização: o **usuário**

**ﬁnal (leigo)**, o **administrador de sistemas (SysAdmin)** e os **gestores executivos (CIO/CTO, CFO,**

**CRO, CEO)**.

Os textos e as métricas foram atualizados com base nas melhorias reais homologadas e nos dados

coletados em **maio de 2026**, considerando o dinamismo dos pacotes de software e a variação de

infraestrutura (redes de 100 Mbps a 1 Gbps; armazenamento de HDD a SSD SATA e NVMe). Os

relatórios visam fundamentar e promover a migração de software proprietário pago para software livre,

destacando robustos ganhos de desempenho, facilidade de uso, conformidade legal e expressiva

redução de custos no cenário do mercado brasileiro.

**RELATÓRIO PARA O USUÁRIO FINAL (LEIGO)**

**Título: “Linux no seu dia a dia: mais rápido, gratuito e fácil como o Windows”**

**Público-alvo:** Pessoas sem conhecimento técnico que desejam utilizar o computador de forma ﬂuida para

tarefas corriqueiras (navegar na internet, escrever documentos, gerenciar e-mails, acessar redes sociais e

operar pequenos negócios) e que buscam uma alternativa moderna ao Windows, com foco em facilidade e

suporte nativo a certiﬁcados digitais e tokens.

**1**

**. Por que migrar do Windows para o Linux?**

•

•

**Gratuito para sempre:** Esqueça as preocupações com custos ou expiração de licenças do Windows ou

do pacote Microsoft Oﬃce. No Linux, o ecossistema é livre.

**Interface familiar e amigável:** A distribuição adotada, o **Zorin OS 18.1** (baseada no moderno Ubuntu

2

4.04 LTS), foi desenhada com um visual muito parecido com o do Windows 10/11. Os menus, botões e

atalhos estão nos mesmos lugares que você já conhece, eliminando qualquer complicação.

•

•

**Leve e extremamente rápido:** O sistema operacional devolve a agilidade a computadores mais antigos e

faz com que máquinas novas atinjam seu desempenho máximo.

**Seguro por natureza:** Vírus e malwares são extremamente raros no ecossistema Linux. Com isso, você

> ﬁca livre de antivírus pesados que travam o computador (necessários apenas em ambientes corporativos

> muito especíﬁcos).

Relatório Integrado - Migração Linux (Maio 2026)

Página 1 de 14

**2**

**. O que você ganha com esta otimização?**

O conjunto de automações implementado pela TI transforma o Linux em uma máquina pronta para uso

imediato, contendo todos os programas essenciais para o seu cotidiano:

**Programa no Windows**

**Microsoft Oﬃce**

**Equivalente no Linux (Gratuito)**

**O que ele faz**

**OnlyOﬃce** (Visual moderno e

totalmente compatível) ou

Edita e cria documentos de texto, planilhas

complexas e apresentações de slides de

forma idêntica ao Oﬃce.

**LibreOﬃce** (Foco corporativo/saúde)

**Adobe Reader**

**Leitor de PDFs integrado**

Abre, visualiza e permite assinar

documentos digitais em formato PDF de

forma leve.

**Google Chrome / Edge**

**Mozilla Firefox** (Navegador

Navegação rápida e protegida na internet,

com total compatibilidade com sites de

bancos e sistemas do governo.

corporativo seguro)

**Token / Certiﬁcado**

**Digital**

**Suporte Nativo Integrado** (G&D,

Permite assinar documentos eletrônicos e

acessar sistemas oﬁciais como PJe, e-CAC

e portais governamentais.

Safenet, DXSafe)

**Photoshop (Básico)**

**GIMP** (Disponível para instalação

Edição de imagens, recortes e retoques

fotográﬁcos com ferramentas completas.

rápida)

**Diferencial Importante:** Você poderá utilizar o seu **token ou smartcard** (emitidos nos padrões ICP-

Brasil) e os principais **assinadores digitais** (Serpro, Certillion, WebPKI) sem a necessidade de realizar

conﬁgurações técnicas complexas. Basta conectar o dispositivo e clicar no atalho **“Habilita**

**Certiﬁcados GOV e Tokens”** presente no menu do sistema para que tudo funcione perfeitamente.

**3**

**. Instalação rápida que não consome seu tempo**

A solução utiliza uma tecnologia de **cache inteligente**. Se você estiver em um escritório com vários

computadores, os programas baixados pela primeira vez ﬁcam salvos em um servidor local (NFS); as demais

máquinas realizam a instalação em segundos, sem a necessidade de gastar a internet da empresa. Mesmo

em um cenário doméstico ou em home oﬃce (sem cache local), a instalação completa da customização leva

apenas entre **10 e 12 minutos** (a depender do link de internet) — o tempo exato de tomar um café enquanto

o computador se prepara sozinho.

**4**

**. O que você precisa fazer?**

1

. Solicite ao setor de TI (ou a um proﬁssional técnico) a instalação da base do **Zorin OS 18.1** em seu

computador.

Relatório Integrado - Migração Linux (Maio 2026)

Página 2 de 14

2

3

. Execute o comando ou atalho automatizado de customização. Todo o restante do processo ocorre de

> forma 100% automática.

. Após a conclusão, os ícones (Firefox, OnlyOﬃce, Assinador Serpro, etc.) aparecerão diretamente no seu

> menu de aplicativos. Conecte seu token USB, clique em “Habilita Certiﬁcados GOV e Tokens” e o sistema

> estará pronto para uso.

**5**

**. Do que você NÃO vai sentir falta do Windows?**

•

•

•

**Atualizações que travam a máquina:** No Linux, as atualizações de segurança ocorrem de forma

silenciosa e em segundo plano. O computador nunca irá reiniciar sozinho no meio do seu trabalho.

**Antivírus consumindo memória e processamento:** Segurança nativa que dispensa softwares

adicionais pesados.

**Custos ocultos:** Sistema operacional e programas produtivos totalmente livres de taxas ou assinaturas.

**6**

**. Suporte e Resiliência**

Caso ocorra qualquer comportamento inesperado, a automação gera **logs detalhados de instalação**

automaticamente. O suporte técnico pode analisar esses arquivos em segundos para identiﬁcar e corrigir o

problema. Vale destacar que a solução foi exaustivamente homologada em máquinas físicas reais e em

centenas de ambientes virtuais, garantindo altíssima estabilidade.

*\**

*\**

*Para aprofundamento técnico da infraestrutura, consulte o **Relatório para o Administrador de Sistemas**.*

*Para avaliar os ganhos estratégicos e o retorno ﬁnanceiro detalhado, consulte o **Relatório para Gestores**.*

Relatório Integrado - Migração Linux (Maio 2026)

Página 3 de 14

> **RELATÓRIO PARA O ADMINISTRADOR DE SISTEMAS (SYSADMIN)**

**Título: “Automação, cache e resiliência – Guia técnico para implantação do Linux em escala”**

**Público-alvo:** Proﬁssionais de TI, administradores de rede e SysAdmins responsáveis pela gestão de

endpoints, conformidade de segurança e pela migração ágil de parques computacionais de Windows para

Linux.

**1**

**. Visão Geral da Solução**

A infraestrutura é baseada em um conjunto de scripts modulares e orquestrados (liderados pelo main.sh)

que customiza distribuições baseadas no ecossistema Ubuntu 24.04 LTS (Zorin OS 18.1, Linux Mint 22.x ou

Ubuntu nativo) de acordo com três perﬁs operacionais especíﬁcos:

•

•

•

•

**Perﬁl 1 – Doméstico (Home Oﬃce):** Instalação limpa, sem a montagem de caches NFS, rotinas de

backup do Proxmox ou softwares hospitalares.

**Perﬁl 2 – Corporativo:** Ambiente completo com integração a cache NFS local, rotinas automatizadas de

backup via Proxmox e restrições granulares de acesso via SSH.

**Perﬁl 3 – Saúde:** Apresenta a mesma base do perﬁl corporativo, adicionando o visualizador de imagens

médicas DICOM (Weasis) e o emulador de terminal 3270 (pw3270).

**Perﬁl 9 – Servidor de Cache:** Conﬁguração automatizada para transformar um nó da rede local em um

servidor uniﬁcado de APT-Cacher-NG + Armazenamento NFS + Cache Flatpak.

A arquitetura do projeto é dividida em 16 módulos numéricos (de 00 a 15). Todas as saídas de erro e logs de

execução são persistidas de forma centralizada no diretório /var/log/customization-persist/ para

ﬁns de auditoria.

**2**

**. Infraestrutura de Cache e Otimização de Tráfego de Rede**

Os dados empíricos coletados em **maio de 2026** apontam uma eﬁciência extraordinária na retenção de

tráfego externo por meio do uso de caches locais na rede corporativa:

Relatório Integrado - Migração Linux (Maio 2026)

Página 4 de 14

**Ganho Observado**

**(Maio/2026)**

**Componente**

**Porta**

**Função Técnica**

**APT-Cacher-NG**

3142

Proxy reverso transparente para pacotes

Debian (conversão automática de fontes de

repositórios).

772 MB servidos

**91% de redução** de

tráfego externo.

**NFS (Cache Flatpak)**

2049

Repositório OSTree compartilhado e

centralizado (montado em /

mnt/.ostree/repo).

2,84 GB servidos

**66% do volume total**

pacotes.

de

**NFS (Cache Adm)**

2049

Distribuição de arquivos estáticos (drivers

de tokens, pacotes .deb avulsos e

624 MB servidos

**14,5% do tráfego**

**interno**.

AppImages) em /tmp/cache.

**Total de Tráfego Interno**

**—**

**Métrica consolidada de atendimento**

**local de requisições.**

**98,3% do tráfego**

**atendido localmente.**

*Nota: Os volumes absolutos ﬂutuam conforme o lançamento de atualizações de pacotes upstream, contudo, a taxa de eﬁciência*

*sistêmica mantém-se estavelmente acima de 95% em ambientes de produção com escala.*

**3**

**. Otimizações de I/O e Desempenho do Sistema**

Abaixo estão listadas as técnicas aplicadas no desenvolvimento dos scripts para minimizar gargalos de

escrita e otimizar o tempo de provisionamento. As medições foram validadas em um Laptop AMD Ryzen 5

3

500U, com NVMe de 500 GB e interface VirtIO em ambiente hypervisor:

Relatório Integrado - Migração Linux (Maio 2026)

Página 5 de 14

**Redução de**

**Tempo**

**Escritas Evitadas**

**(SSD)**

**Técnica Aplicada**

**Implementação Prática**

**Consolidação de**

**Transações APT**

Agrupamento de dependências em

Economia de 35 a

100s

~700 MB poupados

no ciclo de escrita.

um único comando apt install

contendo 446 pacotes.

**Uso de tmpfs para Logs**

**Dinâmicos**

Montagem de um volume de 50 MB

Economia de ~2s

Economia de 15s

~50 MB gravados

em RAM,

de RAM em /var/log/

estendendo a vida

útil do NVMe.

customization para logs

temporários.

**nice/ionice em**

Execução prioritária via nice -n 19

ionice -c 3 flatpak create-

usb para evitar concorrência de I/O.

Evita ~500 MB de

tráfego

**Operações Flatpak**

desnecessário no

NFS.

**Veriﬁcação de Hash de**

**Certiﬁcados**

Validação via SHA256 antes de

realizar a extração e sobrescrita de

arquivos ZIP de emissores ICP.

Economia de 2s

por execução

~400 KB mitigados

por ciclo.

**Pré-veriﬁcação de**

**Repositórios**

Veriﬁcação de cabeçalhos via curl

Economia de 20 a

95s

Evita falhas e

timeouts repetitivos

-

I --max-time 2 para desabilitar

no apt update.

PPAs oﬄine antes do update.

**Roaming de Proxy APT**

Script dispatcher acoplado ao

Economia de 30s

N/A (Evita quebras

de pacotes).

NetworkManager para

reconﬁguração automatizada do

proxy em trânsito.

**Atualizações**

**Espaçadas**

Cron job executando apt full-

upgrade a cada 2 dias utilizando

uma janela aleatória de sleep de até

Distribuição de

carga na rede

N/A (Mitiga picos

de consumo de I/

O).

1

h.

Relatório Integrado - Migração Linux (Maio 2026)

Página 6 de 14

**4**

**. Scripts, Serviços Críticos e Agendamentos**

**Script / Serviço**

**main.sh**

**Localização no Sistema**

**Função Principal**

**Agendamento**

Orquestrador master do

provisionamento.

Execução única

manual

/

/

etc/customization/

etc/

**aptcacher.sh**

**enableprinter.sh**

**clean.sh**

Conﬁguração dinâmica de

proxy e checagem do

Firefox.

@reboot (atraso

de 600s)

Varredura e reativação de

impressoras retidas pelo

CUPS.

/

etc/

\*/5 \* \* \* \*

(A cada 5 min)

Limpeza profunda de lixo e

caches via BleachBit.

/

/

etc/

40 12 \*/63 \*

\*

**ﬂatpak-cache-**

Execução de prune no

repositório Flatpak

Diário (Systemd

Timer)

usr/local/bin/

**maintenance.sh**

hospedado no NFS.

**9**

**9-apt-cacher-roaming**

Garante a comutação de

proxy conforme a

conectividade.

Gatilho do

/

etc/NetworkManager/

NetworkManager

dispatcher.d/

**update\_apt\_keys\_no\_proxy**

Validação prévia de chaves

criptográﬁcas em modo

isolado.

Fase de Preﬂight

utils/

**5**

**. Resiliência e Tratamento de Exceções**

•

**Lock de Execução Atômico:** Cada script crítico faz uso do comando nativo mkdir para estabelecer um

diretório de lock de maneira atômica, associado a instruções de trap que asseguram a remoção do lock

mesmo em cenários de interrupção forçada do processo (SIGINT/SIGTERM).

•

**Fallback de Cache de Três Níveis:** A rotina centralizada download\_with\_cache opera em cascata

lógica: (1) Busca no compartilhamento persistente em /tmp/cache (via NFS); (2) Busca na camada de

memória RAM local em /tmp/cache/ (tmpfs); (3) Download direto via WAN, seguido do salvamento

imediato do artefato no cache local para provisionar os próximos nós.

•

**Recuperação Automatizada do APT:** O script complementar restore-sources-from-backup.sh

realiza o rollback imediato do arquivo sources.list para o estado original de fábrica caso o proxy local

ﬁque inacessível.

Relatório Integrado - Migração Linux (Maio 2026)

Página 7 de 14

•

**Sanidade do Compartilhamento NFS:** A função mount\_nfs\_if\_available executa testes prévios de

handshake através de comandos como showmount -e ou ping direcionados ao IP do servidor antes de

realizar a chamada de montagem, evitando o congelamento de processos do sistema por montagens

órfãs.

**6**

**. Guia Rápido de Implantação**

1

. **Conﬁgurar o Servidor de Cache (Perﬁl 9):** Em uma máquina dedicada ou VM com armazenamento

disponível, execute o script setup-server-KVM-nfs-acng.sh. Ele automatiza a instalação do APT-

Cacher-NG, exportações NFS e repositórios OSTree Flatpak.

2

. **Deﬁnir Arquivos de Perﬁl:** Ajuste as conﬁgurações de rede e os IPs dos servidores nos arquivos

contidos em

/etc/customization/profiles/

(domestic.conf,

corporate.conf,

health.conf).

3

. **Instalação do SO Base:** Formate as estações cliente com o Zorin OS 18.1 LTS padrão.

4. **Cópia da Árvore de Scripts:** Implante o diretório de customização em /etc/customization/ via Git

ou armazenamento USB.

5

6

. **Execução:** Como root, dispare o comando:

cd /etc/customization && ./main.sh --profile 2 (para Perﬁl Corporativo).

. **Monitoramento:** Acompanhe a evolução em tempo real executando:

tail -f /var/log/customization-persist/\*.log

**7**

**. Checklist Pós-Instalação para Homologação**

**☐**

systemctl status ssh pcscd smartd → Veriﬁcar se todos os daemons estão ativos e em

execução.

**☐**

**☐**

crontab -l → Validar a presença e a sintaxe das cinco tarefas agendadas cronógrafas.

mount | grep NFS → Conﬁrmar se os pontos de montagem /mnt e /tmp/cache estão operantes

(perﬁs 2 e 3).

**☐**

**☐**

**☐**

pkcs11-tool --module /usr/lib/libeToken.so --list-slots → Certiﬁcar-se de que a

camada de abstração criptográﬁca reconhece o token conectado.

Acessar [https://hod.serpro.gov.br](https://hod.serpro.gov.br/) via Firefox → Garantir a validação da cadeia de certiﬁcados

ICP-Brasil.

Executar sudo -u user /usr/local/bin/setup-icp-tokens.sh → Validar a importação

automatizada dos certiﬁcados para a sandbox de usuário ﬁnal.

**8**

**. Manutenção Preventiva Automatizada**

A rotina de atualização de pacotes (apt update && apt upgrade -y) é acionada via cron a cada 2 dias,

especiﬁcamente às 12:20, com distribuição de carga. A limpeza física do sistema é delegada ao script

clean.sh que roda a cada 63 dias removendo caches obsoletos de navegadores e lixo residual. No servidor

Relatório Integrado - Migração Linux (Maio 2026)

Página 8 de 14

de cache, uma rotina automatizada executa varreduras diárias de poda no repositório Flatpak, além de

eliminar via comando find /partimag/cache/ -atime +90 -delete qualquer arquivo estático não

acessado nos últimos 90 dias.

Relatório Integrado - Migração Linux (Maio 2026)

Página 9 de 14

**RELATÓRIO PARA GESTORES (CIO, CTO, CFO, CRO, CEO)**

**Título: “Migração do Windows para Linux: ROI, redução de custos e aumento de produtividade”**

**Público-alvo:** Executivos de C-Level responsáveis por decisões estratégicas de tecnologia, alocação de

capital (CapEx/OpEx), governança, gestão de risco corporativo e eﬁciência operacional.

**1**

**. Sumário Executivo**

A migração estratégica das estações de trabalho do ecossistema proprietário Microsoft Windows para a

distribuição Linux otimizada (Zorin OS 18.1 / Ubuntu 24.04 LTS), amparada pela arquitetura de deploy

automatizada proposta, entrega resultados ﬁnanceiros e operacionais imediatos para a organização:

•

•

•

•

**Eliminação integral de custos com licenças** de sistemas operacionais, suítes de escritório e soluções

complementares de antivírus de endpoint.

**Redução drástica de 98% no consumo de banda de internet WAN** dedicada a atualizações e

downloads de softwares, blindando o link principal da empresa contra gargalos.

**Aceleração de 45% na velocidade de provisionamento** e entrega de novas máquinas prontas para uso

devido ao mecanismo de duplo cache local (NFS e APT-Cacher-NG).

**Maximização do ciclo de vida útil do hardware (ativos de TI):** Expressiva diminuição do volume de

> escritas nos SSDs e otimização do agendamento de I/O, postergando a necessidade de reinvestimento

> em hardware (CapEx).

•

**Minimização de chamados de suporte técnico de TI:** Automações preventivas em segundo plano que

mitigam falhas operacionais humanas e técnicas.

Todas as métricas ﬁnanceiras e de infraestrutura foram revisadas de forma precisa para reﬂetir os valores

reais praticados no mercado de tecnologia brasileiro em **maio de 2026**.

**2**

**. Análise de Custo Total de Propriedade (TCO) – Comparativo para 50 Estações**

O levantamento detalha os custos consolidados para a sustentação de um parque tecnológico contendo 50

endpoints corporativos, confrontando o modelo proprietário atual com o modelo em Software Livre proposto.

Relatório Integrado - Migração Linux (Maio 2026)

Página 10 de 14

**Cenário Proprietário**

**(Windows)**

**Cenário Otimizado**

**(Linux)**

**Item de Custo / Investimento**

**Economia Direta**

**Licenciamento de Sistema**

**Operacional**

R$ 40.000,00 (1)

R$ 75.600,00 (2)

R$ 7.500,00 (4)

R$ 1.500,00 (6)

R$ 1.666,66

R$ 0,00

R$ 40.000,00 (No 1º

ano)

**Suíte de Produtividade**

**(Oﬃce)**

R$ 0,00 (3)

R$ 0,00 (5)

R$ 0,00 (7)

R$ 1.000,00

R$ 18.000,00 (9)

R$ 75.600,00

(Recorrente)

**Segurança (Antivírus**

**Corporativo)**

R$ 7.500,00

(Recorrente)

**Banda de Internet**

**(Excedente WAN)**

R$ 1.500,00

(Recorrente)

**Mão de Obra de Implantação**

**(Técnica)**

R$ 666,66 (No 1º

ano)

**Suporte Operacional**

**Contínuo**

R$ 48.000,00 (8)

R$ 30.000,00

(Recorrente)

**CUSTO TOTAL NO 1º ANO**

**R$ 174.266,66**

**R$ 132.600,00**

**R$ 19.000,00**

**R$ 18.000,00**

**R$ 155.266,66**

**CUSTO OPERACIONAL**

**ANUAL RECORRENTE**

**R$ 114.600,00**

**Premissas de Cálculo de Mercado (Brasil, 2026):**

(1) Licenças corporativas COEM/OEM do Windows 11 Pro cotadas a R$ 800,00/máquina (investimento de pagamento único).

(2) Assinatura do plano Microsoft 365 Business Premium com faturamento anual cotado a R$ 126,00 por usuário/mês (totalizando R$

1

.512,00 por estação ao ano).

(3) Adoção do OnlyOﬃce/LibreOﬃce com custo zero de licença e total compatibilidade de arquivos nativos (DOCX, XLSX, PPTX).

(4) Proteção de Endpoint corporativa com gerenciamento centralizado em nuvem a R$ 150,00 por estação/ano.

(5) Segurança robusta em nível de kernel Linux que elimina o custo ﬁxo com licenças de antivírus de prateleira comerciais tradicionais.

(6) Despesa com consumo excedente de pacotes de dados decorrentes de atualizações individuais e tráfego massivo de telemetria

corporativa Microsoft.

(7) Mitigação de tráfego WAN externa via proxy reverso local, eliminando custos de infraestrutura excedente.

(8) Janela média real de 40 horas mensais absorvidas em chamados complexos, instabilidades e manutenções manuais no Windows à

taxa de R$ 100,00/hora (***40h × 12 meses × R$100,00***).

(9) Otimização para apenas 15 horas técnicas mensais devido à drástica estabilização proporcionada pelos scripts de autocorreção

automática (***15h × 12 meses × R$100,00***).

**Retorno sobre o Investimento (ROI):** O investimento necessário para o desenho e homologação da

transição técnica equivale a 40 horas técnicas focadas (R$ 4.000,00). Face à interrupção imediata das

despesas operacionais recorrentes e do licenciamento de software, **o projeto atinge seu ponto de**

**equilíbrio (payback) em menos de 15 dias de operação**. O ROI nominal consolidado para o primeiro

ano atinge a expressiva marca de **3.781%**, gerando uma preservação recorrente de ﬂuxo de caixa de

**R$ 114.600,00 ao ano** a partir do segundo ano.

Relatório Integrado - Migração Linux (Maio 2026)

Página 11 de 14

**3**

**. Produtividade, Disponibilidade e Eﬁciência Operacional**

**Cenário Windows**

**(Média)**

**Cenário Linux**

**Otimizado**

**Impacto Real no**

**Negócio**

**Métrica Operacional**

**Inatividade por**

De 2 a 3 reinicializações

mensais obrigatórias

(gerando cerca de 15

minutos de parada por

nó).

Atualizações em

Ganho líquido de **+5**

**horas produtivas**

**Atualizações Forçadas**

background e em

segundo plano. Zero

reinicializações forçadas.

**anuais** por colaborador.

**Falhas Críticas de**

Incidência de suporte em

cerca de 5% da base de

estações todos os

meses.

Módulo de varredura

ativa inteligente reativa

serviços pendentes a

cada 5 minutos.

**Redução de 80%** no

volume total de

chamados de suporte de

TI.

**Impressão e Tokens**

**Estabilidade de**

Quebras rotineiras em

Java Web Start e drivers

causadas por

Ambiente ﬁxado de forma

estável (Java 8 ﬁxado e

navegadores estáveis

ESR).

Garantia de

**Aplicações Legadas**

conformidade e

**continuidade do**

**faturamento**

operacional.

atualizações do SO.

**Taxa de Sucesso em**

**Atualizações**

Instabilidades comuns e

falhas de rede no

**100% de sucesso**

através do isolamento

temporário automático de

PPAs oﬄine.

Manutenção ininterrupta

das estações sem

indisponibilidade.

Windows Update.

**4**

**. Vantagens Estratégicas Corporativas**

•

•

**Mitigação do Risco de Vendor Lock-in:** Independência total frente à política de reajustes tarifários

unilaterais ou alterações súbitas nos contratos de licenciamento corporativos das Big Techs.

**Segurança Jurídica, LGPD e Auditoria:** O uso de Software Livre garante total transparência de código-

> fonte e ausência de backdoors de telemetria invasiva, assegurando total conformidade com os preceitos

> da Lei Geral de Proteção de Dados (LGPD) no tratamento de dados sensíveis e contábeis.

•

•

**Elasticidade de Escala de Expansão:** Abertura de novos escritórios, ﬁliais ou postos de trabalho com

> custo marginal zero de software. A infraestrutura de cache (NFS + APT-Cacher-NG) é resiliente e executa

> com excelência mesmo em servidores reaproveitados.

**ESG e Sustentabilidade de Ativos:** Ao otimizar o I/O e demandar menor poder de processamento bruto,

> estende-se o ciclo de depreciação do hardware, minimizando o descarte de resíduos eletrônicos e o

> consumo elétrico.

Relatório Integrado - Migração Linux (Maio 2026)

Página 12 de 14

**5**

**. Gerenciamento de Riscos e Estratégias de Mitigação**

**Risco Mapeado**

**Estratégia de Mitigação Implementada na Solução**

**Curva de Aprendizado dos**

**Colaboradores**

Interface visual do Zorin OS customizada de forma análoga ao Windows.

Aplicação de um micro-treinamento prático objetivo de 30 minutos via

guia impresso de apoio.

**Compatibilidade com Certiﬁcados**

**Criptográﬁcos**

Provisionamento automatizado de drivers proprietários e scripts para

registro PKCS\#11 em nível de sistema. Homologado com os principais

emissores nacionais (G&D, Safenet, DXSafe).

**Dependência de Aplicações**

**Exclusivas Windows**

Uso focado de camadas de compatibilidade Wine (gerenciadas

centralizadamente pelo SysAdmin) ou adoção de alternativas nativas

estáveis, como o OnlyOﬃce.

**Sustentabilidade do Suporte a**

**Longo Prazo**

Solução ancorada na distribuição comercial Ubuntu 24.04 LTS, possuindo

suporte corporativo e correções de segurança garantidos nativamente até

meados de 2029.

**Heterogeneidade do Parque de**

**Hardware**

Os ganhos relativos de desempenho se provam ainda maiores em

equipamentos dotados de HDDs mecânicos e conexões saturadas. A

solução escala perfeitamente em infraestruturas de 100 Mbps a 10 Gbps.

**6**

**. Cenário de Aplicação Prática (Caso de Uso Simulado)**

Análise focada em um escritório contábil dotado de 50 estações operacionais:

**Cenário Prévio:** Custos ﬁxos anuais de R$ 75.600,00 direcionados para o ecossistema Microsoft 365, R$

7

.500,00 em soluções de antivírus adicionais e demanda de mais de 40 horas mensais da equipe técnica em

intervenções corretivas em tokens ICP-Brasil e impressoras de rede, gerando uma despesa anual invisível de

R$ 48.000,00 em suporte operacional.

**Cenário Posterior:** Investimento inicial focado de 40 horas técnicas para estruturar o servidor de

provisionamento, conﬁgurar repositórios e perﬁs. Após essa fase, o tempo médio de customização de cada

estação é reduzido para apenas 6 minutos de processamento automático. O resultado prático consolida uma

economia ﬁnanceira direta de **R$ 155.266,66 logo no primeiro ano** e uma eliminação de despesas de R$

1

14.600,00 nos anos subsequentes, gerando um ROI de primeiro ano superior a 3.700%.

**7**

**. Cronograma Técnico e Recomendações de Próximos Passos**

•

**Fase 1 – Projeto-Piloto (Duração: 30 dias):** Seleção minuciosa de um departamento focado em alta

> densidade de uso de certiﬁcados (ex: Financeiro ou Jurídico) composto por até 10 estações cliente.

> Implantação do Zorin OS Otimizado (Perﬁl 2 Corporativo). Monitoramento da volumetria de abertura de

> chamados e índice de aceitação interna.

Relatório Integrado - Migração Linux (Maio 2026)

Página 13 de 14

•

**Fase 2 – Rollout Progressivo (Duração: 4 semanas):** Homologada a fase piloto, avançar com a

> migração gradual dos demais setores da empresa em lotes programados de 20 computadores por

> semana, minimizando impactos no faturamento do negócio.

•

•

**Fase 3 – Capacitação Produtiva:** Distribuição eletrônica do guia rápido de usabilidade de página única

detalhando atalhos do teclado, acesso rápido a tokens e localização dos aplicativos nativos.

**Fase 4 – Monitoramento Contínuo:** Auditoria centralizada através de análise de logs em /var/log/

> customization-persist/ e garantia de estabilidade do cache através do script dinâmico

> acngonoff.sh.

**Conclusão Uniﬁcada dos Relatórios Integrados**

Com base nas medições realizadas em maio de 2026, a migração do parque tecnológico corporativo

Windows para o ecossistema Linux Otimizado ratiﬁca-se como uma decisão de negócios altamente sólida sob

a ótica ﬁnanceira, perfeitamente viável em termos de infraestrutura técnica e de altíssima simplicidade

operacional para o usuário ﬁnal. Embora os valores absolutos de downloads e tamanho de pacotes sofram

leves ﬂutuações sazonais conforme a evolução upstream das distribuições, a eﬁciência relativa das

tecnologias de cache implementadas (superior a 95%) e os ganhos percentuais de tempo e redução de

custos operacionais permanecem perfeitamente estáveis e garantidos para a organização — do colaborador

operacional ao comitê de decisões executivas (CEO).

Relatório Integrado - Migração Linux (Maio 2026)

Página 14 de 14

