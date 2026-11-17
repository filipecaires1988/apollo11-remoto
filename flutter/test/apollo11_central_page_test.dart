import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/apollo11/central_data.dart';
import 'package:flutter_hbb/apollo11/central_page.dart';
import 'package:flutter_hbb/apollo11/central_runtime.dart';
import 'package:flutter_hbb/apollo11/central_store.dart';

class _Runtime implements CentralRuntime {
  final connectedIds = <String>[];
  final queriedIds = <String>[];
  void Function(List<String>, List<String>)? presence;
  @override
  bool get canConnect => true;
  @override
  String get platform => 'Windows';
  @override
  Future<String> ownPeerId() async => '123123123';
  @override
  Future<String> linkedEndpoint() async => '';
  @override
  Future<void> link(
      {required String url,
      required String token,
      required String deviceId,
      required String name}) async {}
  @override
  Future<void> unlink() async {}
  @override
  void listenPresence(void Function(List<String>, List<String>) listener) =>
      presence = listener;
  @override
  void queryPresence(List<String> ids) {
    queriedIds
      ..clear()
      ..addAll(ids);
  }

  @override
  Future<void> connectTo(BuildContext context, String id) async =>
      connectedIds.add(id);
  @override
  void dispose() {}
}

Future<void> _flushIo(WidgetTester tester) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(LinearProgressIndicator).evaluate().isEmpty) break;
  }
  expect(find.byType(LinearProgressIndicator), findsNothing);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  late Directory directory;
  late CentralStore store;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('apollo11-central-page-');
    store = CentralStore(file: File('${directory.path}/catalog.json'));
  });
  tearDown(() async => directory.delete(recursive: true));

  testWidgets('cliente agrupa PCs, busca filtra e conexão envia só o ID remoto',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() => store.save(CentralCatalog(
          groups: [CentralGroup(id: 'example', name: 'Cliente de exemplo')],
          devices: [
            CentralDevice(
                id: 'pc-a',
                groupId: 'example',
                name: 'Recepção',
                peerId: '123456789',
                platform: 'Windows'),
            CentralDevice(
                id: 'pc-b',
                groupId: 'example',
                name: 'Mac do escritório',
                peerId: '987654321',
                platform: 'macOS'),
          ],
        )));
    final runtime = _Runtime();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CentralPage(runtime: runtime, store: store))));
    await _flushIo(tester);
    expect(find.text('Cliente de exemplo'), findsOneWidget);
    expect(find.text('Recepção'), findsOneWidget);
    expect(find.text('Mac do escritório'), findsOneWidget);
    expect(runtime.queriedIds, ['123456789', '987654321']);
    runtime.presence!(['123456789'], ['987654321']);
    await tester.pump();
    expect(find.text('● Online'), findsOneWidget);
    expect(find.text('● Offline'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Recepção');
    await tester.pump();
    expect(find.text('Mac do escritório'), findsNothing);
    await tester.tap(find.text('Conectar'));
    await tester.pumpAndSettle();
    expect(runtime.connectedIds, ['123456789']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('novo cliente e computador persistem em janela de 700 por 550',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 550));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final runtime = _Runtime();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CentralPage(runtime: runtime, store: store))));
    await _flushIo(tester);
    await tester.tap(find.text('Novo cliente'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Nome do cliente'), 'Cliente de teste');
    await tester.tap(find.text('Salvar'));
    await _flushIo(tester);
    expect(find.text('Cliente de teste'), findsOneWidget);
    await tester.tap(find.text('Adicionar computador'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome do computador'),
        'Computador da recepção');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'ID do acesso remoto'), '654321987');
    await tester.tap(find.text('Salvar'));
    await _flushIo(tester);
    expect(find.text('Computador da recepção'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CentralPage(runtime: _Runtime(), store: store))));
    await _flushIo(tester);
    expect(find.text('Cliente de teste'), findsOneWidget);
    expect(find.text('Computador da recepção'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
