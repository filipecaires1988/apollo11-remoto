# Apollo11 Remoto, edição do RustDesk 1.5.3

Esta preparação atende ao uso da Apollo11 no suporte aos seus próprios clientes. A base é o cliente aberto RustDesk 1.5.3, com identidade visual Apollo11. O cliente Server Pro e seu gerador pago não fazem parte desta preparação.

## Estado desta entrega

O código personalizado e os arquivos de compilação estão preparados. **Não há um `.exe` ou `.dmg` personalizado já compilado neste pacote.** A compilação e o teste nativo de Windows/Mac ainda precisam ser realizados.

O pacote não contrata serviços, não publica servidores e não altera computadores dos seus clientes.

## Personalização

- Logo original da Apollo11, nome visual Apollo11 Remoto e cores azul escuro e amarelo.
- Ícones de Windows e Mac preparados a partir da logo original.
- Informações da edição Apollo11 na tela Sobre, preservando os créditos e a licença do RustDesk.
- Identidade interna, protocolo, autenticação e configurações de rede do RustDesk preservados.

A identidade interna foi mantida para conservar o caminho de configurações usado pelo RustDesk. Esta edição usa a mesma identidade de aplicativo e serviço; não foi projetada para operar como uma instalação independente lado a lado com o original. A preservação efetiva de configurações e a atualização sobre uma instalação existente precisam de teste em computadores de teste antes de instalar em clientes.

O executável e o serviço podem continuar aparecendo internamente como RustDesk. O visual Apollo11 não implica vínculo com o projeto RustDesk.

## Conexão dos clientes atuais

A personalização não troca os servidores configurados, nem cria um novo servidor Apollo11. Um computador só encontra os IDs registrados na infraestrutura de conexão que ele utiliza.

Se você usa os servidores públicos do RustDesk, a configuração padrão continua a apontar para essa infraestrutura. Esse acesso depende das regras e da disponibilidade do fornecedor, e não equivale a contratar uma infraestrutura permanente da Apollo11. Se já utiliza um servidor próprio, essa configuração deve ser conferida no teste da edição personalizada.

Para independência da infraestrutura pública, há o servidor OSS gratuito, com hospedagem por sua conta, ou uma conexão por IP dentro de uma VPN criptografada. Essas opções não foram configuradas nesta entrega.

## Gerar Windows e Mac

Na pasta `source` está a raiz completa do projeto personalizado, incluindo o código da biblioteca `hbb_common` no commit correspondente. A preparação usa uma cópia completa dos fontes, sem exigir um submódulo Git separado.

O workflow manual `source/.github/workflows/apollo11-build.yml` prepara as versões Windows x64, Mac Intel e Mac Apple Silicon nos ambientes correspondentes. Veja `README_BUILD.md`.

Antes de distribuir uma compilação, publique o pacote de fontes correspondente em um endereço HTTPS acessível aos usuários. Informe esse endereço no parâmetro `source_url` do workflow. Ele será incluído no botão **Código-fonte desta edição** na tela Sobre.

O GitHub precisa estar conectado e o projeto precisa ser colocado em um repositório para executar esse fluxo. Nenhum repositório foi criado, nenhuma compilação remota foi executada e nenhum código foi publicado por esta entrega. Confira as condições e os limites da sua conta antes de executar ambientes de compilação.

Os binários gerados por esse fluxo não têm assinatura digital da Apollo11 nem notarização Apple. Sua distribuição final exige conferir a execução e as permissões em Windows e Mac reais.

## Código aberto, uso próprio e atendimento a clientes

Atender os próprios clientes é compatível com a finalidade desta edição. Entregar uma versão modificada aos clientes continua sendo distribuição, mesmo sem vender o software.

O arquivo `source/LICENCE` contém a licença AGPL-3.0. Os créditos originais foram preservados. Entregue o código completo correspondente e as instruções de compilação junto da edição; o acesso remoto aos fontes também precisa ficar disponível pelo endereço informado na compilação. O arquivo `MODIFICACOES_APOLLO11.md` registra os arquivos e caminhos alterados.

## Atualizações

O comportamento de atualização oficial foi preservado. Uma atualização oficial pode restaurar a identidade visual do RustDesk. Para manter a edição Apollo11 em uma nova versão, reaplique as modificações na nova base, compile e teste novamente.

## Base e marca

- RustDesk: tag `1.5.3`, commit `95cca3f661f635b3cc85c04935fe8d96d8f432ef`.
- hbb_common: commit `fae47e024dd83cef6aaecde0aa7d11731df11649`.
- Código original: https://github.com/rustdesk/rustdesk
- Logo Apollo11: https://apollo11.com.br/wp-content/plugins/apollo11-sites-apps/assets/logo-apollo11.png
- Cores: azul `#020b15`, painel `#061522`, amarelo `#ffbf16`.
