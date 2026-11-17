# Modificações desta edição

Edição `1.5.3-apollo11.2`, preparada em 17/11/2026, com base em RustDesk 1.5.3. A identidade visual pertence à Apollo11. O código RustDesk e seus avisos originais continuam sob AGPL-3.0.

## Arquivos existentes com comportamento alterado

| Arquivo na raiz deste repositório | Caminho alterado | Motivo |
| --- | --- | --- |
| `flutter/lib/common.dart` | Paleta, constantes de marca e URL de fontes | Aplicar azul escuro e amarelo, preservar leitura no tema claro e fornecer identidade visual compartilhada. |
| `flutter/lib/desktop/pages/desktop_home_page.dart` | Cabeçalho do painel lateral | Mostrar a logo original e Apollo11 Remoto. |
| `flutter/lib/desktop/pages/desktop_setting_page.dart` | Tela Sobre | Identificar a edição modificada e oferecer o acesso aos fontes correspondentes, mantendo os créditos e links originais. |
| `flutter/lib/desktop/widgets/button.dart` | Cores visíveis de botões preenchidos e pressionados | Garantir contraste com o amarelo. Os callbacks não foram alterados. |
| `flutter/lib/desktop/widgets/tabbar_widget.dart` | Nome mostrado na aba e cores no tema escuro | Exibir Apollo11 Remoto e manter as cores da marca. |
| `flutter/windows/runner/Runner.rc` | FileDescription e ProductName | Identificar visualmente a edição Apollo11 nas propriedades do Windows. Os nomes internos e os avisos de autoria permanecem. |
| `src/tray.rs` | Nome visível no aviso da bandeja, com ou sem sessões | Exibir Apollo11 mantendo as traduções, a contagem de sessões e a identidade interna. |
| `src/platform/windows.rs` | Nomes dos atalhos de Desktop e Menu Iniciar, migração no update e limpeza ao desinstalar | Exibir Suporte Apollo11 sem alterar executável, serviço, registro, configuração ou atalho interno de inicialização. |
| `build.py` | Comandos de compilação Flutter Windows e Mac | Incluir a URL HTTPS dos fontes por arquivo JSON de definições, sem inserir a URL em comandos do shell. |

Os ícones em `res`, `flutter/windows/runner/resources` e `flutter/macos/Runner` foram substituídos por versões produzidas com a logo original. Novas imagens da marca estão em `flutter/assets`.

## Preparação de repositório e build

- `.github/workflows/apollo11-build.yml` é manual, não publica releases e não usa credenciais de assinatura. Reaproveita os passos nativos da base 1.5.3 e os workflows auxiliares originais.
- Os outros workflows automáticos foram excluídos desta cópia para não executar publicações ou compilações fora do fluxo manual solicitado.
- A árvore de `hbb_common` foi incluída completa no commit documentado. A cópia pronta não usa um gitlink ou `.gitmodules`.
- `.gitignore` foi ajustado para permitir que os arquivos de imagem sejam incluídos ao criar um repositório a partir desta cópia completa e para ignorar o JSON temporário das definições de build.
- `README_APOLLO11.md`, `README_BUILD.md`, `BRAND.json` e `BUILD_BASE.txt` registram origem, preparação e distribuição.

## Verificação da edição anterior (apollo11.1)

- Contextos exatos da base 1.5.3 conferidos antes da aplicação do script.
- Segunda aplicação sem alterações, verificando a repetibilidade.
- Os cinco arquivos Dart alterados foram analisados pelo parser do formatador Dart 3.5.4, sem erros de sintaxe. O formatador não gravou reformatação nos arquivos.
- Sintaxe Python do script de aplicação e de `build.py` validada.
- Inclusão da URL por JSON exercitada com endereço contendo parâmetros; HTTP, credenciais, fragmentos e espaços foram rejeitados.
- YAML, dependências de jobs, referências de Actions e trechos Bash dos workflows verificados localmente.
- Na edição apollo11.1, a comparação de bytes confirmou a preservação de `src/lib.rs`, `src/server/connection.rs`, `src/rendezvous_mediator.rs`, `src/platform/windows.rs`, `src/platform/macos.rs`, `libs/hbb_common/src/config.rs`, `Cargo.toml` e `Cargo.lock`.
- O [repositório público](https://github.com/filipecaires1988/apollo11-remoto) foi publicado. A [execução de compilação nativa](https://github.com/filipecaires1988/apollo11-remoto/actions/runs/44009980042) gerou os três arquivos nativos. Os três trabalhos nativos e a execução completa concluíram com sucesso.
- No Windows, 253 testes da biblioteca Rust e 2 testes de clipboard foram aprovados, sem falhas nem ignorados; os testes de documentação tiveram 0 casos executados.
- Em cada Mac, 173 testes Dart foram aprovados e 1 foi ignorado. No Mac Apple Silicon, 255 testes da biblioteca Rust foram aprovados, sem falhas nem ignorados, e 22 testes de clipboard passaram sem falhas; os testes de documentação tiveram 0 casos executados.
- Nos três ambientes nativos, a versão informada pela linha de comando foi `1.5.3`.
- Os três artefatos foram baixados e validados por digest do ZIP informado pelo GitHub, CRC, SHA-256 dos arquivos nativos e estrutura dos formatos PE64/DMG.
- Os ZIPs de entrega incluem o EXE ou DMG, sua soma SHA-256, a licença integral `LICENCE` e `LEIA_PRIMEIRO.txt`.

## Atualização apollo11.2

Esta atualização muda somente os nomes visíveis solicitados. No Windows, o instalador cria Suporte Apollo11.lnk no Desktop e no Menu Iniciar. Nas instalações EXE confirmadas, a atualização renomeia os atalhos antigos que ainda existirem; atalhos removidos pelo usuário não são recriados. Instalações MSI e estado incerto mantêm os atalhos anteriores. A limpeza remove o atalho novo e o antigo. O aviso da bandeja passa a iniciar com Apollo11, inclusive quando existem sessões em andamento.

A nova compilação nativa ainda precisa ser concluída. Os resultados da seção anterior pertencem à edição apollo11.1. Atalhos manuais, fixados ou de outros perfis não são procurados. A identidade interna RustDesk e o protocolo permanecem.

## O que ainda falta validar

A compilação e a integridade dos três arquivos nativos foram verificadas. A aparência real da interface, a instalação sobre RustDesk existente, a preservação efetiva de configurações, as permissões e as sessões entre Windows e Mac ainda precisam ser testadas em computadores de destino.

O ZIP público dos fontes do commit usado nesta compilação está indicado em `README.md`. Esse endereço precisa continuar disponível aos usuários. Os binários gerados pelo workflow não recebem assinatura de editor Windows nem Developer ID ou notarização Apple.
