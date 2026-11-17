# Apollo11 Remoto

Edição visual da Apollo11 para atendimento aos seus próprios clientes, baseada no cliente aberto RustDesk 1.5.3.

Inclui logo original, cores azul escuro e amarelo, nome visual Apollo11 Remoto e ícones para Windows e Mac. A identidade interna do aplicativo, a configuração de rede e o protocolo do RustDesk foram preservados.

## Atualização apollo11.2

Na edição `1.5.3-apollo11.2`, o atalho Windows passa a se chamar **Suporte Apollo11** e o aviso da bandeja usa **Apollo11**. O EXE externo do pacote de entrega se chama **Suporte Apollo11.exe**. O núcleo RustDesk continua na versão `1.5.3`.

A [compilação desta edição foi concluída](https://github.com/filipecaires1988/apollo11-remoto/actions/runs/44021193167), com sucesso nos três trabalhos nativos e na execução completa. No Windows, 255 testes foram aprovados, sem falhas nem ignorados. No Mac Intel, foram 173 testes aprovados e 1 ignorado; no Mac Apple Silicon, 450 aprovados e 1 ignorado, sem falhas. A versão `1.5.3` foi confirmada pela linha de comando nas três plataformas. Os três arquivos nativos foram baixados e conferidos por digest do ZIP informado pelo GitHub, CRC, SHA-256 e estrutura PE64/UDIF.

Os ZIPs da edição .2 foram preparados com quatro arquivos: EXE ou DMG, `SHA256SUMS.txt`, `LICENCE` integral e `LEIA_PRIMEIRO.txt`. O manifesto contém os hashes do arquivo nativo, da licença e das instruções. O nome externo do EXE Windows foi alterado para `Suporte Apollo11.exe`, mantendo seus bytes e SHA-256 originais. Os artefatos do workflow mantêm os nomes anteriores; confira a execução e o commit da edição ao baixar.

| Plataforma | Pacote de entrega |
|---|---|
| Windows x64 | `Suporte_Apollo11_1.5.3_apollo11.2_Windows_x64.zip` |
| Mac Intel | `Suporte_Apollo11_1.5.3_apollo11.2_Mac_Intel.zip` |
| Mac Apple Silicon | `Suporte_Apollo11_1.5.3_apollo11.2_Mac_Apple_Silicon.zip` |

## Instaladores da edição anterior

O [repositório público](https://github.com/filipecaires1988/apollo11-remoto) já está disponível. A [execução de compilação Windows e Mac](https://github.com/filipecaires1988/apollo11-remoto/actions/runs/44009980042) produziu os arquivos nativos para Windows x64, Mac Intel e Mac Apple Silicon. Os três artefatos foram baixados e conferidos por integridade do ZIP, SHA-256 dos arquivos e estrutura dos formatos PE64/DMG. A versão `1.5.3` foi confirmada nos ambientes nativos de compilação.

As verificações dessa seção pertencem à edição .1. Os resultados da edição atual aparecem acima e em `README_BUILD.md`. Não confunda o pacote de fontes com um instalador.

Os arquivos não recebem assinatura de editor Windows nem Developer ID ou notarização Apple. A interface gráfica, a instalação sobre RustDesk existente e uma conexão real entre os computadores de destino ainda precisam ser testadas.

## Código-fonte e licença

Este repositório inclui o código completo correspondente, inclusive a biblioteca hbb_common no commit registrado em BUILD_BASE.txt. [Baixar fontes da edição 1.5.3-apollo11.2](https://github.com/filipecaires1988/apollo11-remoto/archive/020b2014ed3e8e8e7d573412fc7e7a5797fdb52d.zip).

O código continua sob [AGPL-3.0](LICENCE). A edição identifica as alterações e mantém os créditos do projeto RustDesk. Apollo11 não é afiliada ao projeto original.

## Documentação

- [Modificações e verificações](MODIFICACOES_APOLLO11.md)
- [Compilação Windows e Mac](README_BUILD.md)
- [Detalhes da edição](README_APOLLO11.md)
- [README original do RustDesk](README_RUSTDESK.md)

A personalização não cria um servidor de conexão da Apollo11. Os clientes precisam usar a mesma infraestrutura de conexão; a configuração existente deve ser conferida no teste. Atualizações oficiais podem restaurar a identidade visual original.

Base: RustDesk 1.5.3, commit 95cca3f661f635b3cc85c04935fe8d96d8f432ef.
