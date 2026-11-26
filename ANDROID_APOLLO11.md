# Apollo11 Remoto para Android

Aplicativo para acessar os computadores dos clientes pelo celular, baseado no RustDesk 1.5.3 e com a identidade visual Apollo11. A tela usa o mesmo tema escuro da edição para computador.

## Instalar e conectar

1. Copie o APK assinado para o celular e abra o arquivo. Autorize a instalação por esse navegador ou gerenciador de arquivos se o Android solicitar.
2. Abra **Apollo11 Remoto**. Na tela de conexão, informe o ID do computador do cliente.
3. Toque em **Conectar** e use a senha do computador ou aguarde o cliente aceitar o pedido.
4. Use os controles da sessão para mover o mouse, clicar e abrir o teclado do celular.

O Apollo11 Remoto precisa estar aberto no computador, com internet. Se o computador usa um servidor próprio de ID/relay e chave pública, configure os mesmos dados no Android em **Configurações → Rede**. A instalação preserva os servidores padrão do projeto existente.

Não é preciso ativar o serviço de acessibilidade ou compartilhar a tela do celular para controlar um computador. Essas permissões pertencem ao modo de receber acesso no próprio telefone.

O Android guarda seus próprios recentes e favoritos. A lista local “Meus clientes” do computador não é copiada automaticamente para o celular. Esta edição não instala atualizações do aplicativo original; as próximas versões Apollo11 devem usar o mesmo certificado de assinatura.

## Pacote e compilação

- ID instalado: `com.apollo11.remoto`.
- Namespace Kotlin/JNI preservado: `com.carriez.flutter_hbb`.
- APK universal: ARM de 32 bits, ARM64 e x86_64.
- Versão Android: `1.5.3-apollo11.8`, código `15308`.
- Build dedicado: `.github/workflows/apollo11-android.yml`, branch `apollo11-android`.
- Não altera o protocolo, as credenciais ou a configuração dos computadores.

A compilação pública produz um APK sem assinatura e os fontes completos do mesmo commit. O APK final deve ser assinado fora da execução pública com a chave privada Apollo11. Nunca inclua a chave, sua senha ou `key.properties` no repositório, nos logs ou nos artefatos públicos.

Mantenha o backup privado da assinatura: ele é necessário para publicar atualizações que instalem sobre esta edição. O build Android não exige recompilar as versões Windows e macOS já aprovadas.

## Licença e fontes

O código é uma personalização do RustDesk, licenciado sob AGPL-3.0. O repositório público contém a licença e as alterações: https://github.com/filipecaires1988/apollo11-remoto/tree/apollo11-android. Cada APK deve acompanhar a identificação do commit e o endereço dos fontes correspondentes.
