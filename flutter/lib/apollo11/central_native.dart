import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart' as app;
import 'package:flutter_hbb/models/platform_model.dart';

import 'central_page.dart';
import 'central_runtime.dart';

bool _centralOpen = false;

Future<void> openApollo11Central(BuildContext context) async {
  if (_centralOpen) return;
  _centralOpen = true;
  final runtime = _NativeCentralRuntime();
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CentralPage(runtime: runtime),
    );
  } finally {
    runtime.dispose();
    _centralOpen = false;
  }
}

class _NativeCentralRuntime implements CentralRuntime {
  static const _handler = 'apollo11-central';

  @override
  bool get canConnect => !bind.isIncomingOnly();
  @override
  String get platform => app.isWindows ? 'Windows' : 'macOS';
  @override
  Future<String> ownPeerId() => bind.mainGetMyId();
  @override
  Future<String> linkedEndpoint() async {
    final token = await bind.mainGetOption(key: 'apollo11-central-token');
    return token.isEmpty ? '' : bind.mainGetOption(key: 'apollo11-central-url');
  }

  @override
  Future<void> link(
      {required String url,
      required String token,
      required String deviceId,
      required String name}) async {
    await bind.mainSetOption(key: 'apollo11-central-token', value: '');
    await bind.mainSetOption(key: 'apollo11-central-url', value: url);
    await bind.mainSetOption(
        key: 'apollo11-central-device-id', value: deviceId);
    await bind.mainSetOption(key: 'apollo11-central-name', value: name);
    await bind.mainSetOption(key: 'apollo11-central-token', value: token);
  }

  @override
  Future<void> unlink() async {
    await bind.mainSetOption(key: 'apollo11-central-token', value: '');
    await bind.mainSetOption(key: 'apollo11-central-url', value: '');
    await bind.mainSetOption(key: 'apollo11-central-device-id', value: '');
    await bind.mainSetOption(key: 'apollo11-central-name', value: '');
  }

  @override
  void listenPresence(void Function(List<String>, List<String>) listener) {
    platformFFI.registerEventHandler('callback_query_onlines', _handler,
        (event) async {
      List<String> ids(dynamic value) =>
          (value is String ? value.split(',') : <String>[])
              .where((id) => id.isNotEmpty)
              .toList();
      listener(ids(event['onlines']), ids(event['offlines']));
    });
  }

  @override
  void queryPresence(List<String> ids) {
    if (ids.isNotEmpty) bind.queryOnlines(ids: ids);
  }

  @override
  Future<void> connectTo(BuildContext context, String id) async {
    if (canConnect) await app.connect(context, id);
  }

  @override
  void dispose() =>
      platformFFI.unregisterEventHandler('callback_query_onlines', _handler);
}
