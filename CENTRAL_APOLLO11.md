# Central Apollo11

A edição `1.5.3-apollo11.3-central` acrescenta o botão **Meus clientes** à janela principal do Apollo11 Remoto. O núcleo mantém a versão `1.5.3`.

## Lista neste computador

Use o modo local para começar sem servidor. Crie um cliente, cadastre os computadores com nome e ID do acesso remoto, marque os favoritos e use a busca. O botão **Conectar** abre a conexão normal do programa, com a senha ou aprovação já configurada no computador de destino.

A lista pertence ao usuário do sistema operacional. Exportar e importar permite transferir o cadastro entre computadores. O arquivo contém nomes e IDs dos seus clientes; guarde-o como um documento particular. A central não armazena senhas de acesso remoto.

Os favoritos locais são salvos com o cadastro. No modo online, os favoritos valem somente durante a sessão aberta.

O estado consultado no servidor de conexão indica a presença do aplicativo. Uma falha de rede também pode aparecer como Offline. Sem resposta recente, o estado volta a Sem informação. Esse estado não confirma se o computador está fisicamente ligado.

## Lista online

O modo online usa a API incluída em [`central-server`](central-server/README.md). Cadastros, grupos, convites e contatos ficam nesse serviço. A lista local e a lista online são independentes: entrar no serviço não envia automaticamente os cadastros locais.

1. Instale a API em um endereço HTTPS com PHP 8.1 ou mais recente e PDO SQLite. A hospedagem precisa permitir um diretório particular fora da pasta pública para a configuração e o banco. Veja as instruções do servidor antes de publicar arquivos.
2. Na central, informe o endereço completo de `api.php` e a senha de administração criada na instalação. A senha e a sessão administrativa ficam somente na memória do aplicativo; faça login novamente após sair.
3. Crie um grupo para o cliente e gere um convite. Cada convite vincula um único computador, expira em 24 horas e só serve para o cadastro. Ele não permite consultar os outros clientes nem iniciar uma conexão remota.
4. No computador do cliente, abra **Meus clientes** e a opção para vincular este computador. Informe o mesmo endereço da API, o convite e o nome do equipamento.
5. Após o vínculo, o serviço do acesso remoto envia seu ID e sistema operacional a cada 60 segundos, enquanto estiver em execução e habilitado. Isso funciona sem a janela principal aberta quando o serviço do acesso remoto está instalado e rodando. No uso portátil, o processo precisa permanecer em execução.

Os programas anteriores continuam conectando normalmente, mas só entram no cadastro automático após receberem esta edição e serem vinculados por convite. Nenhuma máquina de uma instalação antiga é descoberta por simples acesso ao servidor público RustDesk.

**Último contato** é o horário em que a API recebeu a identificação do equipamento. Não confirma que uma conexão de tela está disponível. A central consulta separadamente a presença no servidor de conexão para os IDs cadastrados.

Excluir um computador online revoga sua credencial de cadastro. Para voltar a cadastrá-lo, gere outro convite e faça um novo vínculo. Desvincular no computador apaga a configuração local de envio; a exclusão na central é a forma de revogar a credencial no servidor.

Para excluir um cliente online, remova ou mova os computadores desse grupo primeiro. No modo local, a confirmação de exclusão remove o grupo e seus computadores da lista local.

## O que precisa ser hospedado

A API é um catálogo de equipamentos e não transmite tela, teclado ou arquivos. Ela pode usar hospedagem PHP compatível, sem contratar RustDesk Server Pro. Não foi implantada automaticamente no domínio `apollo11.com.br`.

Não é preciso trocar o servidor de conexão para usar o catálogo. Um servidor próprio de conexão RustDesk, caso seja instalado depois, exige seus próprios processos e portas de rede. A hospedagem de um site WordPress não comprova que esses recursos estão disponíveis.

## Credenciais e dados

- A senha de administração é definida pelo responsável pela instalação. Não existe senha padrão.
- Sessões administrativas e convites têm prazo de validade; o servidor guarda os tokens somente como hashes.
- Cada equipamento recebe uma credencial própria, limitada a atualizar sua identificação e último contato. Ela não permite listar clientes, gerar convites nem abrir sessões remotas.
- O cliente usa HTTPS com validação normal do certificado e não segue redirecionamentos nos pedidos da central.
- A credencial do equipamento fica na configuração existente do serviço RustDesk, sob as permissões de arquivos do sistema. Ela não usa o cofre de senhas do Windows/macOS. Proteja a conta e o diretório de configuração.
- O catálogo não recebe a senha de acesso remoto, capturas de tela, arquivos pessoais ou comandos de controle.
- Nenhum endereço de servidor, credencial ou cadastro real de cliente vem incluído nos fontes ou nos pacotes.

## Superfície de alteração

A interface nova fica em `flutter/lib/apollo11/`. O gancho em `desktop_home_page.dart` acrescenta o botão de abertura. Os cadastros não substituem os contatos recentes, favoritos ou grupos originais do RustDesk.

O módulo `src/apollo11_central.rs` cuida exclusivamente dos contatos periódicos. Sua declaração em `src/lib.rs` e uma chamada no início do mediador permitem executá-lo no processo do serviço. Sem endereço e credencial de vínculo, ele não envia pedidos à central. As rotinas existentes de autenticação, aprovação, transmissão de tela, arquivos e configuração de servidores de conexão não foram alteradas.

`central-server/` contém o serviço opcional de cadastro. O workflow nativo mantém o acionamento manual e também compila a branch `apollo11-central`, usando o ZIP público do commit da própria execução como fonte correspondente. Os testes continuam habilitados nessas compilações.

## Verificação e limites

Na preparação desta edição, passaram cinco testes de integração com PHP 8.2 real, SQLite temporário e quatro processos do servidor HTTP. Eles verificaram cadastro, autenticação, revogação, isolamento de tokens, convites concorrentes, expiração, HTTPS, limites e bloqueio de tentativas. Os três arquivos PHP passaram na verificação de sintaxe.

Passaram também oito testes novos com Flutter 3.24.5 e Dart 3.5.4: seis de dados, arquivos e API e dois da janela. A janela foi exercitada em 700 × 550, com criação e persistência de cliente/computador, reabertura, busca, presença e encaminhamento do ID correto para conectar. A validação local usou um projeto temporário com as dependências da central e os mesmos arquivos do recurso; o adaptador nativo e o aplicativo completo dependem da compilação oficial nas plataformas de destino.

Os números de testes das edições anteriores nos demais documentos não validam a Central Apollo11. A compilação nativa e seus resultados devem ser registrados separadamente.

Antes de colocar o catálogo online em uso, confirme a compatibilidade da hospedagem e teste o vínculo e a conexão com um Windows e um Mac de teste. Instalação e atualização, permissões do serviço, funcionamento com a janela fechada, certificados HTTPS e backup do banco precisam ser conferidos no ambiente de destino.

O catálogo admite até 500 clientes e 5.000 computadores. Nesta versão, a consulta de presença remota é limitada aos primeiros 200 computadores da lista; os demais continuam listados, podem receber atualização de último contato pelo catálogo online e aceitam o botão Conectar. Os IDs cadastrados precisam ter de 6 a 16 dígitos, com Windows ou macOS como sistema.

Os binários continuam sem assinatura de editor Windows e sem Developer ID/notarização Apple. Esta edição não faz uma avaliação nova do executável pelo antivírus.

## Licença

Esta extensão acompanha a licença AGPL-3.0 dos fontes deste repositório. Preserve os créditos e disponibilize o código correspondente ao distribuir o programa ou oferecer o serviço modificado pela rede, conforme a licença. O servidor inclui um caminho para configurar o endereço público dos seus fontes correspondentes.
