# Contribuindo para o Zorin Corporate Configs 🐧

Primeiramente, obrigado por se interessar em melhorar este projeto! Este ecossistema de automação foi criado para simplificar a vida de administradores de sistemas e usuários corporativos no Linux (Zorin OS, Ubuntu e Linux Mint).

Este documento orienta sobre como contribuir de maneira eficiente, mantendo a estrutura modular do repositório organizada.

---

## 🛠️ Como o Projeto Funciona?

O repositório é estritamente modular. O script principal `main.sh` varre a pasta `modules/` e executa recursivamente os scripts em ordem numérica:
* Os módulos seguem o padrão de nomenclatura: `XX-nome-do-modulo.sh` (ex: `01-sync-scripts.sh`).
* Funções compartilhadas, cores de terminal e variáveis globais ficam centralizadas na pasta `utils/`.

---

## 🚀 Como Posso Contribuir?

### 1. Reportando Bugs ou Sugerindo Funcionalidades
Se você encontrou um erro de execução em alguma distribuição ou quer sugerir suporte a um novo token/certificado digital:
* Verifique se já não existe uma [Issue](https://github.com) aberta sobre o assunto.
* Abra uma nova Issue descrevendo detalhadamente o comportamento, a versão do sistema operacional utilizada (Zorin, Ubuntu ou Mint), seu respectivo kernel  e logs do terminal se houver.

### 2. Criando um Novo Módulo ou Corrigindo o Código
Se você quer meter a mão na massa e enviar código:

1. Faça um **Fork** deste repositório.
2. Crie uma **Branch** para a sua modificação:
   ```bash
   git checkout -b feature/novo-modulo-exemplo
   # ou para correções
   git checkout -b fix/correcao-modulo-token
   ```
3. Implemente as alterações seguindo os padrões de estilo (veja abaixo).
4. Faça o **Commit** com mensagens claras e semânticas:
   ```bash
   git commit -m "feat(modules): adiciona o instalador do assinador X"
   ```
5. Envie para o seu Fork (`git push origin feature/novo-modulo-exemplo`) e abra um **Pull Request**.

---

## 🎨 Padrões de Código (Style Guide)

Para garantir que os scripts permaneçam limpos e compatíveis com SEO e leitura humana, siga estas diretrizes:
#!/bin/bash
* **Padrão Shell:** Utilize sintaxe compatível com Bash (`#!/bin/env bash`). Evite recursos exclusivos do Zsh ou outras shells.
* **Mensagens no Terminal:** Utilize as funções de cores centralizadas na pasta `utils/` para manter a identidade visual do instalador (ex: `log_info`, `log_success`, `log_error`).
* **Modularidade:** Não adicione configurações gigantescas dentro do `main.sh`. Se for uma ferramenta nova, crie um script sequencial na pasta `modules/`.
* **Documentação interna:** Comente o topo do seu script explicando o que ele instala, as dependências necessárias de pacotes APT e as configurações criadas. Isso ajuda na indexação do código por motores de busca.

---

## ⚖️ Licença

Ao contribuir para este repositório, você concorda que seu código será disponibilizado sob a mesma licença pública adotada pelo projeto principal.
