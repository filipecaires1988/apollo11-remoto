# Apollo11 Remoto

Edição visual da Apollo11 para atendimento aos seus próprios clientes, baseada no cliente aberto RustDesk 1.5.3.

Inclui logo original, cores azul escuro e amarelo, nome visual Apollo11 Remoto e ícones para Windows e Mac. A identidade interna do aplicativo, a configuração de rede e o protocolo do RustDesk foram preservados.

## Atualização apollo11.2

O atalho Windows passa a se chamar **Suporte Apollo11** e o aviso da bandeja usa **Apollo11**. A nova compilação está sendo preparada. Os resultados e fontes abaixo são da primeira edição, apollo11.1.

## Instaladores da edição anterior

O [repositório público](https://github.com/filipecaires1988/apollo11-remoto) já está disponível. A [execução de compilação Windows e Mac](https://github.com/filipecaires1988/apollo11-remoto/actions/runs/44009980042) produziu os arquivos nativos para Windows x64, Mac Intel e Mac Apple Silicon. Os três artefatos foram baixados e conferidos por integridade do ZIP, SHA-256 dos arquivos e estrutura dos formatos PE64/DMG. A versão `1.5.3` foi confirmada nos ambientes nativos de compilação.

Os ZIPs de entrega incluem o EXE ou DMG, sua soma SHA-256, a licença integral `LICENCE` e `LEIA_PRIMEIRO.txt`. Não confunda o pacote de fontes com um instalador.

Os arquivos não recebem assinatura de editor Windows nem Developer ID ou notarização Apple. A interface gráfica, a instalação sobre RustDesk existente e uma conexão real entre os computadores de destino ainda precisam ser testadas.

## Código-fonte e licença

Este repositório inclui o código completo correspondente, inclusive a biblioteca hbb_common no commit registrado em BUILD_BASE.txt. [Baixar fontes do commit usado nesta compilação](https://github.com/filipecaires1988/apollo11-remoto/archive/1c94292fd6a3ad2b7ec2cc0a9ecbb6c47053ee7a.zip).

O código continua sob [AGPL-3.0](LICENCE). A edição identifica as alterações e mantém os créditos do projeto RustDesk. Apollo11 não é afiliada ao projeto original.

## Documentação

- [Modificações e verificações](MODIFICACOES_APOLLO11.md)
- [Compilação Windows e Mac](README_BUILD.md)
- [Detalhes da edição](README_APOLLO11.md)
- [README original do RustDesk](README_RUSTDESK.md)

A personalização não cria um servidor de conexão da Apollo11. Os clientes precisam usar a mesma infraestrutura de conexão; a configuração existente deve ser conferida no teste. Atualizações oficiais podem restaurar a identidade visual original.

Base: RustDesk 1.5.3, commit 95cca3f661f635b3cc85c04935fe8d96d8f432ef.
