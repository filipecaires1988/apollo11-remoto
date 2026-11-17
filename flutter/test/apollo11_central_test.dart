import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/apollo11/central_api.dart';
import 'package:flutter_hbb/apollo11/central_data.dart';
import 'package:flutter_hbb/apollo11/central_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

CentralCatalog sampleCatalog() => CentralCatalog(
      groups: [CentralGroup(id: 'client-a', name: 'Cliente de exemplo')],
      devices: [
        CentralDevice(
            id: 'device-a',
            groupId: 'client-a',
            name: 'Recepção',
            peerId: '123456789',
            platform: 'Windows',
            favorite: true)
      ],
    );

void main() {
  test('cadastro exportado mantém clientes, favoritos e IDs após importar', () {
    final catalog = sampleCatalog();
    final restored = CentralCatalog.fromText(catalog.toText());
    expect(restored.toJson(), catalog.toJson());
    expect(restored.devices.single.favorite, isTrue);
    expect(() => restored.groups.clear(), throwsUnsupportedError);
  });

  test(
      'importação rejeita IDs repetidos e cliente ausente sem alterar cadastro',
      () {
    final original = sampleCatalog();
    final duplicate = original.toJson();
    (duplicate['devices'] as List)
        .add(original.devices.single.copyWith(name: 'Outro').toJson());
    expect(() => CentralCatalog.fromJson(duplicate), throwsFormatException);
    final orphan = original.toJson();
    ((orphan['devices'] as List).single as Map)['group_id'] = 'absent';
    expect(() => CentralCatalog.fromJson(orphan), throwsFormatException);
    expect(original.devices.single.name, 'Recepção');
    expect(original.groups.single.id, 'client-a');
  });

  test('excluir cliente remove só seus computadores e IDs remotos são únicos',
      () {
    final catalog = sampleCatalog()
        .withGroup(CentralGroup(id: 'client-b', name: 'Outro cliente'))
        .withDevice(CentralDevice(
            id: 'device-b',
            groupId: 'client-b',
            name: 'Mac',
            peerId: '987654321',
            platform: 'macOS'));
    expect(catalog.withoutGroup('client-a').devices.single.id, 'device-b');
    expect(
        () => catalog.withDevice(CentralDevice(
            id: 'device-c',
            groupId: 'client-b',
            name: 'Duplicado',
            peerId: '123456789',
            platform: 'Windows')),
        throwsFormatException);
    expect(
        () => CentralDevice(
            id: 'bad',
            groupId: 'client-a',
            name: 'Inválido',
            peerId: '123&password=secret',
            platform: 'Windows'),
        throwsFormatException);
  });

  test('arquivo inválido é preservado e gravação conserva cópia anterior',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('apollo11-central-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/catalog.json');
    final store = CentralStore(file: file);
    expect((await store.load()).groups, isEmpty);
    await store.save(sampleCatalog());
    await store.save(sampleCatalog()
        .withGroup(CentralGroup(id: 'client-b', name: 'Novo cliente')));
    expect((await store.load()).groups.length, 2);
    await file.delete();
    expect((await store.load()).groups.single.id, 'client-a');
    await file.writeAsString('{invalid');
    await expectLater(store.load(), throwsFormatException);
    expect(await file.readAsString(), '{invalid');
  });

  test('URL da central recusa HTTP, credenciais e parâmetros', () {
    for (final value in [
      'http://example.com/api.php',
      'https://user:secret@example.com/api.php',
      'https://example.com/api.php?token=secret',
      'https://example.com/api.php#secret',
      'https://example.com/'
    ]) {
      expect(() => CentralApi.validateUrl(value), throwsFormatException);
    }
    expect(CentralApi.validateUrl('https://example.com/central/api.php').host,
        'example.com');
  });

  test('login mantém token só na sessão e envio nunca segue redirecionamento',
      () async {
    final token = List.filled(64, 'a').join();
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.queryParameters['route'] == '/v1/admin/login') {
        expect(jsonDecode(request.body), {'password': 'test-password'});
        expect(request.headers.containsKey('authorization'), isFalse);
        return http.Response(
            jsonEncode({
              'token': token,
              'expires_at': DateTime.now()
                  .toUtc()
                  .add(const Duration(hours: 1))
                  .toIso8601String()
            }),
            200);
      }
      expect(request.headers['Authorization'], 'Bearer $token');
      if (request.url.queryParameters['route'] == '/v1/admin/logout') {
        return http.Response('{"ok":true}', 200);
      }
      return http.Response('{}', 302,
          headers: {'location': 'https://elsewhere.example/api.php'});
    });
    final api = CentralApi('https://example.com/api.php', client: client);
    await api.login('test-password');
    expect(api.loggedIn, isTrue);
    await expectLater(api.loadCatalog(), throwsA(isA<CentralApiException>()));
    expect(requests.every((request) => !request.followRedirects), isTrue);
    await api.endSession();
    expect(api.loggedIn, isFalse);
    expect(requests.last.url.queryParameters['route'], '/v1/admin/logout');
    final count = requests.length;
    await expectLater(api.loadCatalog(), throwsA(isA<CentralApiException>()));
    expect(requests.length, count);
    client.close();
  });
}
