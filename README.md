# Apollo11 Remoto

Edição visual da Apollo11 para atendimento aos seus próprios clientes, baseada no cliente aberto RustDesk 1.5.3.

Inclui logo original, cores azul escuro e amarelo, nome visual Apollo11 Remoto e ícones para Windows e Mac. A identidade interna do aplicativo, a configuração de rede e o protocolo do RustDesk foram preservados.

## Instaladores

As compilações personalizadas ficam nas execuções da aba [Actions](https://github.com/filipecaires1988/apollo11-remoto/actions). Os arquivos são disponibilizados após uma execução concluir com sucesso. Não confunda o pacote de fontes com um instalador.

O fluxo manual produz Windows x64, Mac Intel e Mac Apple Silicon. Os arquivos são inicialmente sem assinatura digital da Apollo11 e sem notarização Apple; precisam ser testados nos computadores de destino antes da distribuição.

## Código-fonte e licença

Este repositório inclui o código completo correspondente, inclusive a biblioteca hbb_common no commit registrado em BUILD_BASE.txt. [Baixar fontes](https://github.com/filipecaires1988/apollo11-remoto/archive/refs/heads/main.zip).

O código continua sob [AGPL-3.0](LICENCE). A edição identifica as alterações e mantém os créditos do projeto RustDesk. Apollo11 não é afiliada ao projeto original.

## Documentação

- [Modificações e verificações](MODIFICACOES_APOLLO11.md)
- [Compilação Windows e Mac](README_BUILD.md)
- [Detalhes da edição](README_APOLLO11.md)
- [README original do RustDesk](README_RUSTDESK.md)

A personalização não cria um servidor de conexão da Apollo11. Os clientes precisam usar a mesma infraestrutura de conexão; a configuração existente deve ser conferida no teste. Atualizações oficiais podem restaurar a identidade visual original.

Base: RustDesk 1.5.3, commit 95cca3f661f635b3cc85c04935fe8d96d8f432ef.
