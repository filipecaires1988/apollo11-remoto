import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/apollo11/branding.dart';

void main() {
  test('substitui a marca nas mensagens e mantém a pontuação', () {
    expect(apollo11DisplayText('Instale o RustDesk. Sobre Rustdesk: opções.'),
        'Instale o Apollo11 Remoto. Sobre Apollo11 Remoto: opções.');
  });

  test('preserva links, protocolos e caminhos reais nas instruções', () {
    const text = 'RustDesk: https://example.com/?app=RustDesk '
        'rustdesk://123456789 "C:\\Program Files\\RustDesk" '
        '"/Applications/Meu RustDesk.app" C:\\RustDesk\\RustDesk.exe '
        '/opt/RustDesk/RustDesk rustdesk.com';
    expect(apollo11DisplayText(text),
        text.replaceFirst('RustDesk:', 'Apollo11 Remoto:'));
  });

  test('mantém texto e identificadores que não são a marca', () {
    const text = 'Computador 123456789 · RUSTDESK_APPNAME · myRustDeskClient';
    expect(apollo11DisplayText(text), text);
  });
}
