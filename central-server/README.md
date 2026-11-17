# Servidor da Central Apollo11

API para o catálogo de clientes e computadores da Apollo11. O programa de acesso remoto continua usando seus servidores e sua autenticação atuais. Este serviço guarda nomes, grupos, IDs de acesso e último contato. Não recebe senha de acesso remoto, tela, arquivos ou conteúdo da sessão.

Requer PHP 8.1 ou superior com PDO SQLite e um diretório privado gravável fora da pasta pública. Não há dependências de Composer. Antes de usar a hospedagem atual, confirme a disponibilidade de PDO SQLite, variáveis de ambiente do PHP, HTTPS e armazenamento privado persistente. A configuração da hospedagem Apollo11 ainda não foi verificada.

Esta edição tem uma conta administrativa para a Apollo11. Os grupos organizam clientes dentro dessa conta; não são contas separadas com login para cada empresa. O limite é de 500 clientes e 5.000 computadores ativos.

## Instalação

1. Coloque `central-server` fora da pasta pública e configure o domínio ou subdomínio para servir **somente** `central-server/public`.
2. Crie uma pasta privada fora da pasta pública para `config.json` e `central.sqlite`. O PHP deve conseguir ler e gravar essa pasta. Não coloque banco, configuração, `bin`, `src` ou testes sob `public_html`.
3. Em um terminal privado, gere o banco e a configuração. O exemplo abaixo pede a senha sem mostrá-la e a passa ao instalador pelo ambiente, sem gravá-la no histórico de comandos:

```bash
read -r -s -p 'Senha da Central: ' APOLLO11_ADMIN_PASSWORD
export APOLLO11_ADMIN_PASSWORD
export APOLLO11_SOURCE_URL='https://github.com/filipecaires1988/apollo11-remoto/tree/apollo11-central'
php central-server/bin/init.php /home/conta/apollo11-private
unset APOLLO11_ADMIN_PASSWORD
```

A senha aceita de 12 a 72 bytes UTF-8. Essa faixa evita o truncamento de senhas do bcrypt. O arquivo guarda somente o hash. O instalador não sobrescreve uma instalação existente. Para um pacote publicado, aponte `APOLLO11_SOURCE_URL` para o commit ou ZIP público exato dos fontes correspondentes.

4. Configure no servidor PHP a variável `APOLLO11_CENTRAL_CONFIG=/home/conta/apollo11-private/config.json`. Não forneça esse valor por query string ou formulário. Se o painel da hospedagem não permitir variáveis de ambiente, peça ao suporte para configurar esta variável no PHP-FPM ou VirtualHost.
5. Ative certificado HTTPS válido. Em um proxy que encerra TLS antes do PHP, configure `APOLLO11_TRUSTED_HTTPS=1` **no ambiente do servidor** somente se todo acesso externo já for obrigado a usar HTTPS. A API não confia em `X-Forwarded-Proto` nem `X-Forwarded-For` enviados pelo visitante.
6. No aplicativo Apollo11, informe a URL final, por exemplo `https://central.seudominio.com.br/api.php`. O endereço deve abrir diretamente a API, sem redirecionamento.

O Apache pode precisar da regra fornecida em `public/.htaccess` para preservar o cabeçalho Authorization. Em Nginx/PHP-FPM, preserve `HTTP_AUTHORIZATION`. A proteção dos arquivos privados depende de estarem fora da pasta pública; a API também recusa banco e configuração cujo caminho resolvido esteja sob o `DOCUMENT_ROOT`.

Mantenha permissões restritas ao usuário da aplicação, cópia de segurança consistente do SQLite e do `config.json`, e HTTPS obrigatório. Evite cópia direta do banco durante escritas: use a ferramenta de backup do SQLite ou pare as escritas temporariamente. Para várias instâncias de servidor, esta edição não oferece banco compartilhado; use uma única instância com disco local persistente.

## Uso

- Entre com a senha administrativa, crie um cliente e cadastre manualmente o ID de um computador ou gere um convite.
- Cada convite serve para um computador, vence em 24 horas e é consumido em uma transação. Um convite usado não pode cadastrar uma segunda máquina.
- O vínculo do computador recebe um token próprio, que só permite enviar contato desse computador. Ele não lê a lista, cria clientes nem altera o nome definido pelo técnico.
- Remover um computador revoga imediatamente seu token e o remove da listagem. O aplicativo de acesso remoto permanece instalado. Para cadastrar novamente, gere outro convite.
- A sessão administrativa vence em oito horas. O token é armazenado com hash no servidor. O aplicativo deve mantê-lo somente na memória.
- O último contato indica comunicação do aplicativo com esta API. Não confirma que uma conexão remota pode ser aberta, e ausência de contato não prova que o computador está desligado.

Sem cadastro por convite, registros manuais têm `last_seen: null`. Computadores já instalados não entram sozinhos na central: precisam ser atualizados e vinculados por convite uma vez. O técnico deve ter autorização do cliente para esse vínculo e para a sessão remota.

## Contrato HTTP

Todas as rotas usam `api.php?route=/v1/...`. POST e PATCH recebem objeto JSON. DELETE aceita corpo vazio ou objeto JSON. Respostas são JSON com `Cache-Control: no-store`; erros usam `{ "error": "mensagem" }`. IDs internos são textos hexadecimais de 32 caracteres. O ID de acesso remoto aceita 6 a 16 dígitos, sem espaços. Os sistemas aceitos são `Windows` e `macOS`. IDs personalizados com letras ainda não são suportados nesta edição.

| Método e rota | Autorização | Resultado |
| --- | --- | --- |
| GET `/v1/source` | Pública | `source_url`, `license` |
| POST `/v1/admin/login` | Senha em JSON | `token`, `expires_at` |
| POST `/v1/admin/logout` | Bearer administrativo | `ok` |
| GET `/v1/groups` | Bearer administrativo | `groups: [{id,name}]` |
| POST `/v1/groups` | Bearer administrativo, `{name}` | `group` |
| PATCH `/v1/groups/{id}` | Bearer administrativo, `{name}` | `group` |
| DELETE `/v1/groups/{id}` | Bearer administrativo | `ok`; recusa cliente com máquinas ativas |
| GET `/v1/devices` | Bearer administrativo | `devices` |
| POST `/v1/devices` | Bearer administrativo, `{group_id,name,peer_id,platform}` | `device` |
| PATCH `/v1/devices/{id}` | Bearer administrativo, campos opcionais acima | `device` |
| DELETE `/v1/devices/{id}` | Bearer administrativo | `ok`; revoga vínculo |
| POST `/v1/invites` | Bearer administrativo, `{group_id}` | `code`, `expires_at` |
| POST `/v1/enroll` | Convite em JSON, `{code,name,peer_id,platform}` | `device_id`, `device_token`, `group_name` |
| POST `/v1/heartbeat` | Bearer do computador, `{peer_id,platform?}` | `ok` |

Dispositivos retornam `{id,group_id,name,peer_id,platform,last_seen,revoked:false}`. Datas são ISO 8601 UTC com `Z`. O heartbeat preserva o nome e grupo escolhidos pelo administrador. Tokens são 64 caracteres hexadecimais e não devem ser enviados em URLs. Códigos de convite têm 32 caracteres hexadecimais. Não publique esses valores em capturas de tela ou repositórios.

Credenciais administrativas e de computadores são independentes. Limites de tentativas são por endereço IP direto do servidor, 10 logins e 20 tentativas de cadastro por intervalo de 15 minutos. Em proxy, isso pode contar todos os clientes como um só IP. Cadastros inválidos retornam 422; autenticação inválida, 401; duplicidade e limites, 409; excesso de tentativas, 429. Não há credencial padrão ou chave administrativa embutida no aplicativo.

## Testes

```bash
python3 central-server/tests/integration.py
```

Os testes usam PHP real, servidor HTTP local com quatro processos e SQLite temporário. Verificam autenticação, dados inválidos, grupos, máquinas, isolamento do token de dispositivo, renomeação, revogação, convite de uso único sob concorrência, rollback de cadastro falho, expiração administrativa, HTTPS, limites e bloqueio de tentativas. O HTTP local é habilitado somente na configuração temporária do teste. A configuração de produção nasce com `allow_loopback_http: false`.

Para um executável PHP diferente, defina `PHP_BINARY`. Essa variável de teste também aceita argumentos de execução. Nenhum teste acessa clientes ou banco de produção.

Código sob AGPL-3.0, conforme o arquivo `LICENCE` da raiz. O endpoint público `/v1/source` oferece o endereço dos fontes correspondentes configurado na instalação.
