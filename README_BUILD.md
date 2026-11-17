# Gerar Apollo11 Remoto para Windows e Mac

Esta edição aplica a identidade visual da Apollo11 ao RustDesk **1.5.3**. A parte de conexão continua sendo o RustDesk de código aberto. Não usa o gerador de clientes Pro, não requer uma chave Pro e não configura um servidor particular.

O nome mostrado na interface, a logo, os ícones e as cores podem mudar. Os nomes internos `RustDesk`, `rustdesk.exe`, `librustdesk.dll`, o serviço e o identificador do aplicativo Mac são preservados. Isso mantém os caminhos de configuração e a identidade da instalação existente. Esta edição não deve ser tratada como um segundo serviço para instalar ao lado do RustDesk oficial.

A edição apollo11.2 acrescenta os nomes Suporte Apollo11 nos atalhos Windows e Apollo11 no aviso da bandeja. A nova compilação ainda será executada. Os resultados abaixo pertencem à edição anterior, apollo11.1.

A [execução de compilação nativa](https://github.com/filipecaires1988/apollo11-remoto/actions/runs/44009980042) produziu o EXE Windows x64 e os DMGs Mac Intel e Mac Apple Silicon. Os três trabalhos nativos e a execução completa concluíram com sucesso. Os três arquivos nativos foram baixados e conferidos; os testes de interface, instalação e conexão real continuam pendentes.

## Arquivos de compilação

A pasta `.github/workflows/`, na raiz deste repositório, contém:

| Arquivo | Função |
|---|---|
| `apollo11-build.yml` | Início manual, geração Windows x64/Mac Intel/Mac Apple Silicon e pacote de fontes. |
| `bridge.yml` | Gera a ligação entre Rust e Flutter usada pelo aplicativo. |
| `third-party-RustDeskTempTopMostWindow.yml` | Compila o auxiliar Windows oficial, no commit fixado pelo projeto. |

Os três arquivos já estão em `.github/workflows/` **na raiz dos fontes completos preparados**, junto de `Cargo.toml`, `build.py`, `flutter/`, `libs/` e os demais arquivos do RustDesk. Use essa árvore completa para compilar.

O workflow foi reduzido a partir do arquivo oficial do tag `1.5.3`. Ele conserva os passos de compilação necessários e remove a publicação de releases, a criação de modelos Pro, a assinatura digital, a notarização e as outras plataformas. As Actions usadas nesses três arquivos estão fixadas por commit.

## Gerar usando GitHub Actions

1. Use a raiz do [repositório público Apollo11 Remoto](https://github.com/filipecaires1988/apollo11-remoto), que já contém os fontes completos do tag `1.5.3`, a personalização e a biblioteca `hbb_common` no commit registrado.
2. Mantenha `Cargo.toml` na raiz. Nesta cópia, `libs/hbb_common` é uma pasta normal, incluída integralmente. Não recrie `.gitmodules` nem a transforme em um gitlink vazio.
3. Para uma nova compilação, abra **Actions** e escolha **Apollo11 Remoto | Windows e Mac**.
4. Use uma URL HTTPS pública do ZIP completo dos fontes do commit que será compilado. O endereço precisa abrir o arquivo diretamente, sem login. O `README.md` indica o ZIP com commit fixado da compilação entregue.
5. Clique em **Run workflow** e preencha `source_url` com esse endereço real. A opção de executar os testes oficiais vem ligada por padrão.
6. Aguarde os trabalhos Windows e Mac terminarem. Eles precisam baixar e compilar várias dependências. O limite configurado para cada trabalho nativo é de três horas.
7. Ao terminar, abra a execução e baixe os arquivos em **Artifacts**.

O início da execução verifica que `source_url` usa HTTPS e responde com um arquivo ZIP público. Um campo vazio, link de login ou página HTML interrompe a rotina antes dos trabalhos nativos. Essa verificação não compara todos os arquivos do ZIP; quem distribui precisa conferir que são exatamente os fontes utilizados.

A rotina exporta `APOLLO11_SOURCE_URL` para `build.py`. A edição preparada encaminha esse valor ao Flutter por um arquivo JSON de definições de compilação, sem inserir a URL em um comando de shell. O endereço fica disponível na tela Sobre do aplicativo. Não há um endereço de demonstração configurado.

O workflow é exclusivamente manual. Não publica site, não cria release, não envia mensagens e não usa certificado ou segredo de assinatura. A execução atual foi iniciada manualmente, depois da publicação dos fontes. A execução pode consumir minutos e armazenamento da sua conta GitHub.

Se estiver usando uma cópia completa do repositório oficial, desative ou remova os outros workflows automáticos que não fazem parte desta edição antes de enviar o projeto. Isso evita disparar as rotinas de outras plataformas por push ou tag.

## Arquivos produzidos

| Artefato | Conteúdo |
|---|---|
| `Apollo11-Windows-x64-unsigned` | `Apollo11_Remoto-1.5.3-windows-x64.exe`, autoextraível, e `SHA256SUMS.txt`. |
| `Apollo11-Windows-x64-pasta-unsigned` | A pasta Windows completa, cujo executável interno continua `rustdesk.exe`. |
| `Apollo11-Mac-x86_64-unsigned` | `Apollo11_Remoto-1.5.3-macos-x86_64.dmg` para Mac Intel e seu SHA-256. |
| `Apollo11-Mac-aarch64-unsigned` | `Apollo11_Remoto-1.5.3-macos-aarch64.dmg` para Mac Apple Silicon e seu SHA-256. |
| `Apollo11-fontes-1.5.3` | ZIP dos fontes completos com os submódulos, manifesto de commits e SHA-256. |

O aplicativo dentro dos DMGs continua se chamando `RustDesk.app`. Os arquivos externos e a interface identificam a edição Apollo11. Não há MSI nesta primeira rotina reduzida.

Os ZIPs preparados para entrega incluem o EXE ou DMG, sua soma SHA-256, a licença integral `LICENCE` e `LEIA_PRIMEIRO.txt`. Eles preservam o arquivo nativo gerado pela compilação.

O ZIP dos fontes indicado em `source_url` precisa estar realmente hospedado antes de compilar e deve permanecer acessível a quem receber o programa. O artefato de fontes criado pela rotina é uma cópia adicional da árvore usada na execução; ele não publica o arquivo no seu site nem preenche a URL automaticamente.

Os artefatos gerados ficam disponíveis por 30 dias na execução. Guarde os binários e seus fontes correspondentes juntos antes de distribuir a edição a alguém. O RustDesk é distribuído sob **AGPLv3**; mantenha os avisos, a licença e o acesso ao código correspondente, incluindo as alterações desta edição.

## Versões e plataformas preservadas

| Parte | Versão ou plataforma usada |
|---|---|
| RustDesk | Tag `1.5.3`, com submódulos nos commits desse tag. |
| Windows | Runner `windows-2022`, destino `x86_64-pc-windows-msvc`. |
| Mac Intel | Runner `macos-15-intel`, destino `x86_64-apple-darwin`. |
| Mac Apple Silicon | Runner `macos-15`, destino `aarch64-apple-darwin`. |
| Rust no Windows | `1.75`. |
| Rust no Mac | `1.81`. |
| Flutter Windows/Mac Intel | `3.24.5`. |
| Flutter Mac Apple Silicon | `3.44.9`, com os ajustes de código oficiais para essa versão. |
| Ligação Rust/Flutter | `flutter_rust_bridge_codegen 1.80.1`; arquivos separados para Flutter 3.24 e 3.44. |
| vcpkg | Commit `9e593bb18ea69cc5095e012465dcd675a822ed0d`. |
| LLVM Windows | `15.0.6`. |
| NASM no Mac | `2.16.03`, conforme o workflow oficial. |

O projeto de origem usa versões diferentes do Flutter para manter a compatibilidade das plataformas. Trocar tudo por uma versão mais nova sem adaptar o código pode impedir a compilação.

## Testes da execução anterior (apollo11.1)

Na [execução registrada](https://github.com/filipecaires1988/apollo11-remoto/actions/runs/44009980042), foram conferidos os seguintes resultados:

| Plataforma | Resultado |
|---|---|
| Windows x64 | Build concluído com sucesso; 253 testes da biblioteca Rust e 2 testes de clipboard aprovados, sem falhas nem ignorados. Os testes de documentação tiveram 0 casos executados. |
| Mac Intel | Build concluído com sucesso; 173 testes Dart aprovados e 1 ignorado. |
| Mac Apple Silicon | Build concluído com sucesso; 173 testes Dart aprovados e 1 ignorado; 255 testes da biblioteca Rust aprovados, sem falhas nem ignorados; 22 testes de clipboard aprovados, sem falhas. Os testes de documentação não continham casos, com 0 executados. |
| As três plataformas | Executável nativo informou a versão `1.5.3` pela linha de comando. |

Após o download dos três artefatos, foram validados o digest do ZIP informado pelo GitHub, o CRC de suas entradas, o SHA-256 dos arquivos nativos e os formatos PE64 no Windows e DMG nos Macs. O pacote de fontes e os arquivos finais também recebem somas SHA-256.

Essas verificações comprovam a geração e a integridade dos arquivos. A interface gráfica, a instalação sobre RustDesk existente, a preservação efetiva de configurações, as permissões e uma conexão real entre os computadores de destino ainda precisam ser testadas.

## Uso com os clientes que já têm RustDesk

Os padrões de rede e o protocolo não são alterados. A edição pode tentar conectar aos IDs dos clientes que usam os mesmos servidores configurados no RustDesk original. O serviço público não pertence à Apollo11; a disponibilidade e as condições dele dependem do operador. Caso seu RustDesk já use outro servidor, a configuração existente precisa ser a mesma dos clientes.

Como a identidade interna continua RustDesk, IDs, senhas e endereços de servidor usam os caminhos existentes. Nenhum ID, senha permanente ou endereço de cliente foi colocado nos fontes. Uma atualização pelo programa oficial pode restaurar o visual original. Para manter a edição visual, será necessário recompilar as alterações sobre a versão desejada e validar a atualização.

## Assinatura e permissões

Os binários desta rotina não recebem assinatura de editor Windows nem certificado Developer ID ou notarização Apple. O sistema pode identificar que o editor não foi verificado. Para uma distribuição assinada, é preciso configurar certificados próprios em uma etapa separada.

No Mac, a pessoa continua autorizando a Gravação de Tela e a Acessibilidade nos ajustes do sistema. A rotina não altera essas permissões. O build mantém os arquivos de permissões do RustDesk original.

## Referências oficiais

- Fonte do RustDesk 1.5.3: https://github.com/rustdesk/rustdesk/tree/1.5.3
- Workflow original: https://github.com/rustdesk/rustdesk/blob/1.5.3/.github/workflows/flutter-build.yml
- Compilação RustDesk: https://rustdesk.com/docs/en/dev/build/
- Windows: https://rustdesk.com/docs/en/dev/build/windows/
- Mac: https://rustdesk.com/docs/en/dev/build/osx/

A geração nativa usa ferramentas do próprio sistema. O ambiente Linux que preparou este projeto não produz nem testa o aplicativo Windows ou Mac por meio desse workflow. São os runners nativos acima que realizam a compilação quando a execução é iniciada.
