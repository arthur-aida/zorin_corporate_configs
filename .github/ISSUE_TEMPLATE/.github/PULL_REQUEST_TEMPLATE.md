## 📄 Tipo de Alteração
*   [ ] **Fix:** Correção de bug em script existente.
*   [ ] **Feat:** Novo módulo ou automação (Adição na pasta `modules/`, `scripts/` ou `utils/`).
*   [ ] **Docs:** Melhoria na documentação ou comentários do código para SEO.
*   [ ] **Refactor:** Otimização de performance ou I/O (ex: melhorias em `tmpfs`, logs ou comandos APT).

## 🎯 Descrição do Pull Request
*(Explique brevemente o que este código faz e qual problema ele resolve dentro do ecossistema corporativo Linux)*

## 🛠️ Lista de Mudanças Técnicas
*   [ ] Criou/Modificou o arquivo: `modules/XX-nome-do-script.sh`
*   [ ] Utilizou as funções de cores e logs padronizadas da pasta `lib/`/`utils/`.
*   [ ] Adicionou comentários no cabeçalho do script para indexação em motores de busca.
*   [ ] O script foi testado e não quebra a retrocompatibilidade com Zorin, Ubuntu e Mint / kernels.

## 🧪 Como este código foi homologado?
*   [ ] Testado em ambiente virtualizado (KVM/QEMU / Virt-Manager ) conforme requisitos do README.
*   [ ] Testado em hardware real.
*   *Distribuições validadas com este patch:* [ ] Zorin OS | [ ] Ubuntu | [ ] Linux Mint e  Kernel [        ] 

## 🚨 Checklist de Pós-Instalação e Sandbox
*   [ ] Se altera permissões do Flatpak (ex: drivers PKCS#11 para tokens A3), a flag `--filesystem=/usr/lib:ro` foi mantida segura?
*   [ ] O script gerencia corretamente travas de pacotes (`packagekit.service` / `apt-daily.timer`) se necessário?

---
*Ao submeter este PR, confirmo que meu código segue a licença principal do projeto.*
