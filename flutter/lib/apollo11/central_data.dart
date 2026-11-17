import 'dart:convert';

const centralMaxBytes = 2 * 1024 * 1024;

String centralText(dynamic value, String field, {int max = 120}) {
  if (value is! String ||
      value.trim().isEmpty ||
      value.length > max ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)) {
    throw FormatException('$field inválido.');
  }
  return value.trim();
}

String centralId(dynamic value) {
  final id = centralText(value, 'Identificador', max: 80);
  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
    throw const FormatException('Identificador inválido.');
  }
  return id;
}

String centralPeerId(dynamic value) {
  final id = centralText(value, 'ID remoto', max: 32).replaceAll(' ', '');
  if (!RegExp(r'^\d{6,16}$').hasMatch(id)) {
    throw const FormatException('Informe um ID remoto com 6 a 16 números.');
  }
  return id;
}

String centralPlatform(dynamic value) {
  final platform = centralText(value, 'Sistema operacional', max: 16);
  if (platform != 'Windows' && platform != 'macOS') {
    throw const FormatException('Selecione Windows ou macOS.');
  }
  return platform;
}

DateTime? centralDate(dynamic value) {
  if (value == null) return null;
  if (value is! String || value.length > 40 || !value.endsWith('Z')) {
    throw const FormatException('Data de contato inválida.');
  }
  final date = DateTime.tryParse(value);
  if (date == null) throw const FormatException('Data de contato inválida.');
  return date.toUtc();
}

class CentralGroup {
  final String id;
  final String name;

  CentralGroup({required String id, required String name})
      : id = centralId(id),
        name = centralText(name, 'Nome do cliente');

  factory CentralGroup.fromJson(Map<String, dynamic> json) => CentralGroup(
      id: centralId(json['id']),
      name: centralText(json['name'], 'Nome do cliente'));

  CentralGroup copyWith({String? name}) =>
      CentralGroup(id: id, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class CentralDevice {
  final String id;
  final String groupId;
  final String name;
  final String peerId;
  final String platform;
  final bool favorite;
  final DateTime? lastSeen;

  CentralDevice({
    required String id,
    required String groupId,
    required String name,
    required String peerId,
    required String platform,
    this.favorite = false,
    this.lastSeen,
  })  : id = centralId(id),
        groupId = centralId(groupId),
        name = centralText(name, 'Nome do computador'),
        peerId = centralPeerId(peerId),
        platform = centralPlatform(platform);

  factory CentralDevice.fromJson(Map<String, dynamic> json) {
    if (json['favorite'] != null && json['favorite'] is! bool) {
      throw const FormatException('Favorito inválido.');
    }
    return CentralDevice(
      id: centralId(json['id']),
      groupId: centralId(json['group_id']),
      name: centralText(json['name'], 'Nome do computador'),
      peerId: centralPeerId(json['peer_id']),
      platform: centralPlatform(json['platform']),
      favorite: json['favorite'] == true,
      lastSeen: centralDate(json['last_seen']),
    );
  }

  CentralDevice copyWith(
          {String? groupId,
          String? name,
          String? peerId,
          String? platform,
          bool? favorite,
          DateTime? lastSeen}) =>
      CentralDevice(
          id: id,
          groupId: groupId ?? this.groupId,
          name: name ?? this.name,
          peerId: peerId ?? this.peerId,
          platform: platform ?? this.platform,
          favorite: favorite ?? this.favorite,
          lastSeen: lastSeen ?? this.lastSeen);

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'name': name,
        'peer_id': peerId,
        'platform': platform,
        'favorite': favorite,
        if (lastSeen != null) 'last_seen': lastSeen!.toUtc().toIso8601String(),
      };
}

class CentralCatalog {
  final List<CentralGroup> groups;
  final List<CentralDevice> devices;

  CentralCatalog(
      {Iterable<CentralGroup> groups = const [],
      Iterable<CentralDevice> devices = const []})
      : groups = List.unmodifiable(groups),
        devices = List.unmodifiable(devices) {
    if (this.groups.length > 500 || this.devices.length > 5000) {
      throw const FormatException(
          'Limite de 500 clientes e 5.000 computadores excedido.');
    }
    final groupIds = this.groups.map((g) => g.id).toSet();
    if (groupIds.length != this.groups.length) {
      throw const FormatException('Há clientes repetidos.');
    }
    final deviceIds = <String>{};
    final peerIds = <String>{};
    for (final device in this.devices) {
      if (!groupIds.contains(device.groupId)) {
        throw const FormatException('Um computador está sem cliente válido.');
      }
      if (!deviceIds.add(device.id) || !peerIds.add(device.peerId)) {
        throw const FormatException(
            'Há computadores ou IDs remotos repetidos.');
      }
    }
  }

  factory CentralCatalog.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 ||
        json['groups'] is! List ||
        json['devices'] is! List) {
      throw const FormatException(
          'Arquivo da Central Apollo11 inválido ou de outra versão.');
    }
    try {
      return CentralCatalog(
        groups: (json['groups'] as List).map(
            (g) => CentralGroup.fromJson(Map<String, dynamic>.from(g as Map))),
        devices: (json['devices'] as List).map(
            (d) => CentralDevice.fromJson(Map<String, dynamic>.from(d as Map))),
      );
    } on TypeError {
      throw const FormatException('Arquivo da Central Apollo11 inválido.');
    }
  }

  factory CentralCatalog.fromText(String value) {
    if (utf8.encode(value).length > centralMaxBytes) {
      throw const FormatException('O arquivo deve ter no máximo 2 MB.');
    }
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Arquivo da Central Apollo11 inválido.');
    }
    return CentralCatalog.fromJson(decoded);
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'groups': groups.map((g) => g.toJson()).toList(),
        'devices': devices.map((d) => d.toJson()).toList(),
      };

  String toText() {
    final text = const JsonEncoder.withIndent('  ').convert(toJson());
    if (utf8.encode(text).length > centralMaxBytes) {
      throw const FormatException('O cadastro deve ter no máximo 2 MB.');
    }
    return text;
  }

  CentralCatalog withGroup(CentralGroup group) => CentralCatalog(
      groups: [...groups.where((g) => g.id != group.id), group],
      devices: devices);

  CentralCatalog withoutGroup(String id) => CentralCatalog(
      groups: groups.where((g) => g.id != id),
      devices: devices.where((d) => d.groupId != id));

  CentralCatalog withDevice(CentralDevice device) => CentralCatalog(
      groups: groups,
      devices: [...devices.where((d) => d.id != device.id), device]);

  CentralCatalog withoutDevice(String id) =>
      CentralCatalog(groups: groups, devices: devices.where((d) => d.id != id));
}
