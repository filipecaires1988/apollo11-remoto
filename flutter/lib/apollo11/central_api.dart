import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'central_data.dart';

class CentralApiException implements Exception {
  final String message;
  const CentralApiException(this.message);
  @override
  String toString() => message;
}

class CentralApi {
  final Uri _base;
  final http.Client _client;
  final bool _ownsClient;
  String? _token;
  DateTime? _expiresAt;

  CentralApi(String url, {http.Client? client})
      : _base = validateUrl(url),
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  static Uri validateUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !uri.path.endsWith('/api.php') ||
        uri.port < 1 ||
        uri.port > 65535) {
      throw const FormatException(
          'Informe a URL HTTPS da central terminada em /api.php, sem senha ou parâmetros.');
    }
    return uri;
  }

  String get url => _base.toString();
  bool get loggedIn =>
      _token != null &&
      _expiresAt != null &&
      DateTime.now().toUtc().isBefore(_expiresAt!);

  Future<void> login(String password) async {
    logout();
    final result = await _request('POST', '/v1/admin/login',
        body: {'password': password}, auth: false);
    final token = result['token'];
    final expiry = centralDate(result['expires_at']);
    if (token is! String ||
        token.length < 32 ||
        token.length > 512 ||
        !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(token) ||
        expiry == null ||
        !expiry.isAfter(DateTime.now().toUtc())) {
      throw const CentralApiException(
          'A central devolveu uma sessão inválida.');
    }
    _token = token;
    _expiresAt = expiry;
  }

  void logout() {
    _token = null;
    _expiresAt = null;
  }

  Future<void> endSession() async {
    try {
      if (loggedIn) {
        await _request('POST', '/v1/admin/logout', body: {});
      }
    } finally {
      logout();
    }
  }

  void close() {
    logout();
    if (_ownsClient) _client.close();
  }

  Future<CentralCatalog> loadCatalog() async {
    final groups = await _request('GET', '/v1/groups');
    final devices = await _request('GET', '/v1/devices');
    return CentralCatalog.fromJson({
      'version': 1,
      'groups': groups['groups'],
      'devices': devices['devices'],
    });
  }

  Future<CentralGroup> createGroup(String name) async {
    final result = await _request('POST', '/v1/groups',
        body: {'name': centralText(name, 'Nome do cliente')});
    return _group(result);
  }

  Future<CentralGroup> updateGroup(String id, String name) async {
    final result = await _request('PATCH', '/v1/groups/${centralId(id)}',
        body: {'name': centralText(name, 'Nome do cliente')});
    return _group(result);
  }

  CentralGroup _group(Map<String, dynamic> result) {
    if (result['group'] is! Map) {
      throw const CentralApiException(
          'A central devolveu um cliente inválido.');
    }
    return CentralGroup.fromJson(
        Map<String, dynamic>.from(result['group'] as Map));
  }

  Future<void> deleteGroup(String id) async {
    await _request('DELETE', '/v1/groups/${centralId(id)}');
  }

  Future<CentralDevice> createDevice(CentralDevice device) async {
    final result =
        await _request('POST', '/v1/devices', body: _deviceBody(device));
    return _device(result);
  }

  Future<CentralDevice> updateDevice(CentralDevice device) async {
    final result = await _request(
        'PATCH', '/v1/devices/${centralId(device.id)}',
        body: _deviceBody(device));
    return _device(result);
  }

  Map<String, dynamic> _deviceBody(CentralDevice device) => {
        'group_id': device.groupId,
        'name': device.name,
        'peer_id': device.peerId,
        'platform': device.platform,
      };

  CentralDevice _device(Map<String, dynamic> result) {
    if (result['device'] is! Map) {
      throw const CentralApiException(
          'A central devolveu um computador inválido.');
    }
    return CentralDevice.fromJson(
        Map<String, dynamic>.from(result['device'] as Map));
  }

  Future<void> deleteDevice(String id) async {
    await _request('DELETE', '/v1/devices/${centralId(id)}');
  }

  Future<Map<String, dynamic>> createInvite(String groupId) async {
    final result = await _request('POST', '/v1/invites',
        body: {'group_id': centralId(groupId)});
    final code = result['code'];
    if (code is! String ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(code) ||
        centralDate(result['expires_at']) == null) {
      throw const CentralApiException(
          'A central devolveu um convite inválido.');
    }
    return result;
  }

  Future<Map<String, dynamic>> enroll(
      {required String code,
      required String name,
      required String peerId,
      required String platform}) async {
    final result = await _request('POST', '/v1/enroll', auth: false, body: {
      'code': centralText(code, 'Convite', max: 128),
      'name': centralText(name, 'Nome do computador'),
      'peer_id': centralPeerId(peerId),
      'platform': centralPlatform(platform)
    });
    centralId(result['device_id']);
    centralText(result['group_name'], 'Nome do cliente');
    final token = result['device_token'];
    if (token is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(token)) {
      throw const CentralApiException(
          'A central devolveu um vínculo inválido.');
    }
    return result;
  }

  Future<Map<String, dynamic>> _request(String method, String route,
      {Map<String, dynamic>? body, bool auth = true}) async {
    if (auth && !loggedIn) {
      logout();
      throw const CentralApiException('Entre novamente na central.');
    }
    final request =
        http.Request(method, _base.replace(queryParameters: {'route': route}))
          ..followRedirects = false
          ..headers['Accept'] = 'application/json';
    if (auth) request.headers['Authorization'] = 'Bearer $_token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    try {
      final response =
          await _client.send(request).timeout(const Duration(seconds: 15));
      if (response.statusCode >= 300 && response.statusCode < 400) {
        throw const CentralApiException(
            'A central redirecionou o pedido. Confira a URL HTTPS.');
      }
      if ((response.contentLength ?? 0) > centralMaxBytes) {
        throw const CentralApiException('A resposta da central excedeu 2 MB.');
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk
          in response.stream.timeout(const Duration(seconds: 15))) {
        if (bytes.length + chunk.length > centralMaxBytes) {
          throw const CentralApiException(
              'A resposta da central excedeu 2 MB.');
        }
        bytes.add(chunk);
      }
      if (response.statusCode == 401 && auth) logout();
      dynamic decoded;
      try {
        decoded = jsonDecode(utf8.decode(bytes.takeBytes()));
      } on FormatException {
        throw const CentralApiException(
            'A central não devolveu uma resposta JSON válida.');
      }
      if (decoded is! Map<String, dynamic>) {
        throw const CentralApiException('Resposta inválida da central.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = decoded['error'];
        throw CentralApiException(error is String && error.length <= 300
            ? error
            : 'A central não conseguiu concluir o pedido (${response.statusCode}).');
      }
      return decoded;
    } on TimeoutException {
      throw const CentralApiException(
          'A central demorou para responder. Tente novamente.');
    } on http.ClientException {
      throw const CentralApiException(
          'Não foi possível acessar a central por HTTPS.');
    }
  }
}
