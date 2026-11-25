# Apollo11 Remoto, edição do RustDesk 1.5.3

Esta preparação atende ao uso da Apollo11 no suporte aos seus próprios clientes. A base é o cliente aberto RustDesk 1.5.3, com identidade visual Apollo11. O cliente Server Pro e seu gerador pago não fazem parte desta preparação.

## Identidade visual: edição apollo11.4

O Suporte Apollo11 passa a usar a mesma identidade da Central de TI e da Central de Backups: nuvem branca, foguete verde, nome Apollo11 em branco e a identificação ACESSO REMOTO. O fundo usa azul-marinho `#0D1928`, os painéis `#101E2E`, os campos `#132234` e os botões e destaques `#0BB15E`.

A atualização aplica a marca à janela principal, às abas, aos botões e à Central de Clientes. A opção de tema claro continua disponível com os destaques verdes. Não altera o cadastro, os catálogos local e online, as credenciais, a autenticação remota nem os servidores configurados. A compilação nativa desta edição ainda precisa ser concluída e conferida; os resultados históricos abaixo pertencem às respectivas edições anteriores.

## Central Apollo11: edição apollo11.3-central

Esta edição acrescenta o cadastro de clientes e computadores à janela principal, com armazenamento local e catálogo online opcional. Veja o [guia de uso, instalação e limites](CENTRAL_APOLLO11.md). Os números e pacotes da seção seguinte continuam pertencendo exclusivamente à edição `.2`.

## Histórico: atualização apollo11.2

Na edição `1.5.3-apollo11.2`, os nomes visíveis passam a ser Suporte Apollo11 nos atalhos Windows e Apollo11 no aviso da bandeja. O EXE externo do pacote de entrega se chama `Suporte Apollo11.exe`. O núcleo RustDesk mantém a versão `1.5.3`.

A [compilação da edição .2 foi concluída](https://github.com/filipecaires1988/apollo11-remoto/actions/runs/44021193167), com sucesso nos três trabalhos nativos e na execução completa. No Windows, 255 testes foram aprovados, sem falhas nem ignorados. Mac Intel teve 173 testes aprovados e 1 ignorado; Mac Apple Silicon teve 450 aprovados e 1 ignorado, sem falhas. A versão `1.5.3` foi confirmada pela linha de comando nas três plataformas. Os três arquivos nativos foram baixados e conferidos por digest do ZIP informado pelo GitHub, CRC, SHA-256 e estrutura PE64/UDIF.

Os [fontes da edição .2 estão fixados no commit correspondente](https://github.com/filipecaires1988/apollo11-remoto/archive/020b2014ed3e8e8e7d573412fc7e7a5797fdb52d.zip). Os ZIPs de entrega foram preparados com quatro arquivos: EXE ou DMG, `SHA256SUMS.txt` com os hashes dos outros três arquivos, `LICENCE` integral e `LEIA_PRIMEIRO.txt`. Os bytes dos arquivos nativos foram preservados, inclusive o SHA-256 do EXE externo agora chamado `Suporte Apollo11.exe`. Os nomes dos artefatos do workflow continuam iguais aos anteriores; a execução identifica a edição. Os pacotes de entrega usam o padrão `Suporte_Apollo11_1.5.3_apollo11.2_<sistema>.zip`.

## Estado da edição anterior

O código personalizado está no [repositório público da Apollo11](https://github.com/filipecaires1988/apollo11-remoto). A [execução de compilação nativa de Windows e Mac](https://github.com/filipecaires1988/apollo11-remoto/actions/runs/44009980042) produziu um EXE para Windows x64 e DMGs para Mac Intel e Mac Apple Silicon. Os três artefatos foram baixados e conferidos por digest do ZIP informado pelo GitHub, CRC, SHA-256 dos arquivos nativos e estrutura PE64/DMG. A versão `1.5.3` foi confirmada pela linha de comando nos ambientes nativos de compilação.

Os ZIPs de entrega incluem o arquivo nativo, sua soma SHA-256, a licença integral `LICENCE` e `LEIA_PRIMEIRO.txt`. A interface gráfica, a instalação sobre RustDesk existente, as permissões e uma conexão real entre Windows e Mac ainda precisam ser testadas.

O pacote não contrata serviços, não publica servidores e não altera computadores dos seus clientes.

## Personalização

- Logo Apollo11 com nuvem branca e foguete verde, identificação ACESSO REMOTO e cores azul-marinho, verde e branco.
- Ícones de Windows e Mac preparados a partir da identidade Apollo11.
- Informações da edição Apollo11 na tela Sobre, preservando os créditos e a licença do RustDesk.
- Identidade interna, protocolo, autenticação e configurações de rede do RustDesk preservados.

A identidade interna foi mantida para conservar o caminho de configurações usado pelo RustDesk. Esta edição usa a mesma identidade de aplicativo e serviço; não foi projetada para operar como uma instalação independente lado a lado com o original. A preservação efetiva de configurações e a atualização sobre uma instalação existente precisam de teste em computadores de teste antes de instalar em clientes.

O executável e o serviço podem continuar aparecendo internamente como RustDesk. O visual Apollo11 não implica vínculo com o projeto RustDesk.

## Conexão dos clientes atuais

A personalização não troca os servidores configurados, nem cria um novo servidor Apollo11. Um computador só encontra os IDs registrados na infraestrutura de conexão que ele utiliza.

Se você usa os servidores públicos do RustDesk, a configuração padrão continua a apontar para essa infraestrutura. Esse acesso depende das regras e da disponibilidade do fornecedor, e não equivale a contratar uma infraestrutura permanente da Apollo11. Se já utiliza um servidor próprio, essa configuração deve ser conferida no teste da edição personalizada.

Para independência da infraestrutura pública, há o servidor OSS gratuito, com hospedagem por sua conta, ou uma conexão por IP dentro de uma VPN criptografada. Essas opções não foram configuradas nesta entrega.

## Gerar Windows e Mac

Na raiz deste repositório está o projeto personalizado completo, incluindo o código da biblioteca `libs/hbb_common` no commit correspondente. A preparação usa uma cópia completa dos fontes, sem exigir um submódulo Git separado.

O workflow manual `.github/workflows/apollo11-build.yml` prepara as versões Windows x64, Mac Intel e Mac Apple Silicon nos ambientes correspondentes. Veja `README_BUILD.md`.

O ZIP público dos fontes desta compilação está indicado em `README.md`, com o commit fixado. O endereço informado em `source_url` é incluído no botão **Código-fonte desta edição** na tela Sobre. Em uma nova compilação, use os fontes do commit realmente compilado e mantenha esse endereço acessível aos usuários.

O repositório foi publicado e as execuções das edições .1 e .2 concluíram com sucesso. Os resultados de cada edição estão separados em `README_BUILD.md`. Novas execuções podem consumir minutos e armazenamento da conta GitHub.

Os binários gerados por esse fluxo não recebem assinatura de editor Windows nem Developer ID ou notarização Apple. Sua distribuição final exige conferir a execução e as permissões em Windows e Mac reais.

## Código aberto, uso próprio e atendimento a clientes

Atender os próprios clientes é compatível com a finalidade desta edição. Entregar uma versão modificada aos clientes continua sendo distribuição, mesmo sem vender o software.

O arquivo `LICENCE`, na raiz deste repositório, contém a licença AGPL-3.0. Os créditos originais foram preservados. Entregue o código completo correspondente e as instruções de compilação junto da edição; o acesso remoto aos fontes também precisa ficar disponível pelo endereço informado na compilação. O arquivo `MODIFICACOES_APOLLO11.md` registra os arquivos e caminhos alterados.

## Atualizações

No Windows, abra `Suporte Apollo11.exe` e instale o programa ou use **Clique para atualizar**, quando esse botão aparecer. Encerre e abra o aplicativo novamente para carregar o novo nome na bandeja.

Os atalhos criados na Área de Trabalho e no Menu Iniciar usam **Suporte Apollo11**. A atualização renomeia atalhos antigos existentes nos caminhos padrão somente quando a instalação é reconhecida como EXE. Atalhos removidos não são recriados. Instalações MSI ou de tipo incerto e atalhos manuais, fixados ou de outros perfis não são migrados. A instalação EXE sobre uma instalação MSI continua bloqueada pelo fluxo original.

No Mac, o pacote continua sendo um DMG com `RustDesk.app`. As permissões de Gravação de Tela e Acessibilidade continuam necessárias, e a identificação da bandeja usa Apollo11.

O comportamento de atualização oficial foi preservado. Uma atualização oficial pode restaurar a identidade visual do RustDesk. Para manter a edição Apollo11 em uma nova versão, reaplique as modificações na nova base, compile e teste novamente.

## Base e marca

- RustDesk: tag `1.5.3`, commit `95cca3f661f635b3cc85c04935fe8d96d8f432ef`.
- hbb_common: commit `fae47e024dd83cef6aaecde0aa7d11731df11649`.
- Código original: https://github.com/rustdesk/rustdesk
- Logo Apollo11 desta edição: `flutter/assets/apollo11-logo.png`.
- Cores: azul-marinho `#0D1928`, painel `#101E2E`, campos `#132234`, bordas `#293D52`, verde `#0BB15E`, branco `#FFFFFF` e texto secundário `#A9B9CB`.
