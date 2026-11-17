import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'central_api.dart';
import 'central_data.dart';
import 'central_runtime.dart';
import 'central_store.dart';

const _navy = Color(0xFF020B15);
const _panel = Color(0xFF0B1B2B);
const _yellow = Color(0xFFFFBF16);
const _muted = Color(0xFF9BAFC1);

class CentralPage extends StatefulWidget {
  const CentralPage({super.key, required this.runtime, this.store});
  final CentralRuntime runtime;
  final CentralStore? store;

  @override
  State<CentralPage> createState() => _CentralPageState();
}

class _CentralPageState extends State<CentralPage> {
  late final CentralStore _store = widget.store ?? CentralStore();
  CentralCatalog _local = CentralCatalog();
  CentralCatalog _cloud = CentralCatalog();
  CentralApi? _api;
  final _search = TextEditingController();
  final _expanded = <String>{};
  final _cloudFavorites = <String>{};
  final _presence = <String, _Presence>{};
  Timer? _timer;
  bool _busy = false;
  bool _loaded = false;
  bool _online = false;
  bool _favoritesOnly = false;
  String? _error;
  DateTime? _cloudRefreshed;
  int _ticks = 0;

  CentralCatalog get _catalog => _online ? _cloud : _local;
  bool get _writable => !_busy && (_online || _loaded);

  @override
  void initState() {
    super.initState();
    widget.runtime.listenPresence(_onPresence);
    _perform(() async {
      final catalog = await _store.load();
      if (!mounted) return;
      setState(() {
        _local = catalog;
        _loaded = true;
        _expanded.addAll(catalog.groups.map((g) => g.id));
      });
      _queryPresence();
    });
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      setState(() {});
      _queryPresence();
      if (++_ticks % 3 == 0 &&
          _online &&
          !_busy &&
          ModalRoute.of(context)?.isCurrent == true) {
        _perform(_refreshCloud);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    final api = _api;
    if (api != null) {
      unawaited(api.endSession().catchError((_) {}).whenComplete(api.close));
    }
    _search.dispose();
    super.dispose();
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object error) =>
      error is FormatException ? error.message : error.toString();

  void _onPresence(List<String> onlines, List<String> offlines) {
    if (!mounted) return;
    final known = _catalog.devices.map((d) => d.peerId).toSet();
    final now = DateTime.now();
    setState(() {
      for (final id in onlines.where(known.contains)) {
        _presence[id] = _Presence(true, now);
      }
      for (final id in offlines.where(known.contains)) {
        _presence[id] = _Presence(false, now);
      }
    });
  }

  void _queryPresence() {
    widget.runtime.queryPresence(
        _catalog.devices.map((device) => device.peerId).take(200).toList());
  }

  Future<void> _saveLocal(CentralCatalog catalog) async {
    await _store.save(catalog);
    if (mounted)
      setState(() {
        _local = catalog;
        _loaded = true;
      });
  }

  Future<void> _refreshCloud() async {
    final api = _api;
    if (api == null) return;
    final catalog = await api.loadCatalog();
    if (!mounted || api != _api) return;
    setState(() {
      _cloud = catalog;
      _cloudRefreshed = DateTime.now();
    });
    _queryPresence();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: _navy,
      colorScheme: const ColorScheme.dark(
          primary: _yellow, secondary: _yellow, surface: _panel),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
        isDense: true,
      ),
    );
    return Theme(
      data: theme,
      child: Dialog(
        backgroundColor: _navy,
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 1000,
          height: 760,
          child: Column(children: [
            _header(),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
              child: Column(children: [
                _toolbar(),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Buscar cliente, computador ou ID',
                      prefixIcon: Icon(Icons.search),
                    ),
                  )),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Mostrar apenas favoritos',
                    isSelected: _favoritesOnly,
                    selectedIcon: const Icon(Icons.star, color: _yellow),
                    icon: const Icon(Icons.star_border),
                    onPressed: () =>
                        setState(() => _favoritesOnly = !_favoritesOnly),
                  ),
                  IconButton(
                    tooltip: 'Atualizar lista e presença',
                    onPressed: _busy
                        ? null
                        : () => _perform(() async {
                              if (_online) await _refreshCloud();
                              _queryPresence();
                            }),
                    icon: const Icon(Icons.refresh),
                  ),
                ]),
              ]),
            ),
            if (_error != null) _notice(_error!, error: true),
            if (_online &&
                _cloudRefreshed != null &&
                DateTime.now().difference(_cloudRefreshed!) >
                    const Duration(seconds: 90))
              _notice(
                  'A lista online está desatualizada. Confira a conexão e atualize.'),
            Expanded(child: _groups()),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Text(
                '${_catalog.groups.length} clientes · ${_catalog.devices.length} computadores. '
                'A conexão usa a autenticação já configurada no destino.'
                '${_catalog.devices.length > 200 ? ' Presença consultada nos primeiros 200 computadores.' : ''}',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 8, 8),
        child: Row(children: [
          Image.asset('assets/apollo11-logo.png', width: 120, height: 38),
          const SizedBox(width: 14),
          const Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Meus clientes',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
              Text('Central Apollo11',
                  style: TextStyle(color: _muted, fontSize: 12)),
            ],
          )),
          IconButton(
              tooltip: 'Fechar',
              icon: const Icon(Icons.close),
              onPressed: _busy ? null : () => Navigator.of(context).pop()),
        ]),
      );

  Widget _toolbar() => Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(
              avatar:
                  Icon(_online ? Icons.cloud_done : Icons.computer, size: 17),
              label: Text(_online ? 'Central online' : 'Neste computador')),
          FilledButton.icon(
              onPressed: _writable ? () => _editGroup() : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Novo cliente')),
          OutlinedButton.icon(
              onPressed: _busy ? null : (_online ? _logout : _login),
              icon:
                  Icon(_online ? Icons.logout : Icons.cloud_outlined, size: 18),
              label: Text(_online ? 'Sair da central' : 'Entrar na central')),
          OutlinedButton.icon(
              onPressed: _busy ? null : _enrollment,
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Vincular este computador')),
          if (!_online)
            PopupMenuButton<String>(
              tooltip: 'Cópia da lista local',
              enabled: !_busy,
              icon: const Icon(Icons.more_horiz),
              onSelected: (value) => value == 'import' ? _import() : _export(),
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'import', child: Text('Importar lista local')),
                PopupMenuItem(
                    value: 'export',
                    enabled: _loaded,
                    child: const Text('Exportar lista local')),
              ],
            ),
        ],
      );

  Widget _notice(String text, {bool error = false}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: error ? const Color(0xFF471F29) : _panel,
            borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      );

  Widget _groups() {
    final query = _search.text.trim().toLowerCase();
    final children = <Widget>[];
    for (final group in _catalog.groups) {
      final groupMatches = group.name.toLowerCase().contains(query);
      final devices = _catalog.devices
          .where((device) => device.groupId == group.id)
          .where((device) => !_favoritesOnly || _isFavorite(device))
          .where((device) =>
              groupMatches ||
              device.name.toLowerCase().contains(query) ||
              device.peerId.contains(query))
          .toList();
      if (devices.isEmpty && (_favoritesOnly || !groupMatches)) continue;
      final expanded = _expanded.contains(group.id) || query.isNotEmpty;
      children.add(Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Material(
            color: _panel,
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 8, right: 4),
                leading: Icon(
                    expanded ? Icons.expand_more : Icons.chevron_right,
                    color: _yellow),
                title: Text(group.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${devices.length} computadores',
                    style: const TextStyle(fontSize: 11, color: _muted)),
                onTap: () => setState(() => _expanded.contains(group.id)
                    ? _expanded.remove(group.id)
                    : _expanded.add(group.id)),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Opções do cliente',
                  enabled: _writable,
                  onSelected: (value) {
                    if (value == 'add') _editDevice(group: group);
                    if (value == 'rename') _editGroup(group);
                    if (value == 'delete') _deleteGroup(group);
                    if (value == 'invite') _invite(group);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'add', child: Text('Adicionar computador')),
                    if (_online)
                      const PopupMenuItem(
                          value: 'invite',
                          child: Text('Criar convite para vínculo automático')),
                    const PopupMenuItem(
                        value: 'rename', child: Text('Renomear cliente')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Excluir cliente')),
                  ],
                ),
              ),
              if (expanded) ...[
                const Divider(height: 1),
                if (devices.isEmpty)
                  Padding(
                      padding: const EdgeInsets.all(14),
                      child: TextButton.icon(
                          onPressed: _writable
                              ? () => _editDevice(group: group)
                              : null,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar computador'))),
                ...devices.map(_deviceRow),
              ],
            ]),
          )));
    }
    if (children.isEmpty) {
      return Center(
          child: SingleChildScrollView(
              child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.devices, color: _muted, size: 44),
          const SizedBox(height: 12),
          Text(
              _catalog.groups.isEmpty
                  ? 'Seus clientes vão aparecer aqui'
                  : 'Nenhum resultado para esta busca',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
              _online
                  ? 'Crie um cliente e gere um convite para vincular os computadores.'
                  : 'Crie um cliente e adicione os IDs dos computadores.\nA lista local fica salva neste computador.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12)),
        ]),
      )));
    }
    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: children);
  }

  bool _isFavorite(CentralDevice device) =>
      _online ? _cloudFavorites.contains(device.id) : device.favorite;

  Widget _deviceRow(CentralDevice device) {
    final presence = _presence[device.peerId];
    final known = presence != null &&
        DateTime.now().difference(presence.at) < const Duration(seconds: 90);
    final color = !known
        ? _muted
        : presence.online
            ? const Color(0xFF35C69B)
            : const Color(0xFFE88E66);
    final status = !known
        ? 'Sem informação'
        : presence.online
            ? 'Online'
            : 'Offline';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      child: Row(children: [
        IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: _online ? 'Favorito nesta sessão' : 'Favorito',
            onPressed: _writable ? () => _toggleFavorite(device) : null,
            icon: Icon(_isFavorite(device) ? Icons.star : Icons.star_border,
                color: _isFavorite(device) ? _yellow : _muted, size: 19)),
        Icon(
            device.platform == 'macOS'
                ? Icons.laptop_mac
                : Icons.desktop_windows,
            size: 22,
            color: _muted),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(device.name,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 3),
          Wrap(spacing: 12, runSpacing: 2, children: [
            Text('${device.platform} · ${device.peerId}',
                style: const TextStyle(color: _muted, fontSize: 11)),
            Tooltip(
                message: 'Disponibilidade no servidor de acesso remoto. '
                    'Offline também pode indicar falha de conexão.',
                child: Text('● $status',
                    style: TextStyle(color: color, fontSize: 11))),
            if (device.lastSeen != null)
              Text('Contato com a central: ${_date(device.lastSeen!)}',
                  style: const TextStyle(color: _muted, fontSize: 11)),
          ]),
        ])),
        const SizedBox(width: 6),
        if (widget.runtime.canConnect)
          TextButton(
              onPressed: _busy
                  ? null
                  : () => _perform(
                      () => widget.runtime.connectTo(context, device.peerId)),
              child: const Text('Conectar')),
        PopupMenuButton<String>(
            tooltip: 'Opções do computador',
            enabled: _writable,
            onSelected: (value) {
              if (value == 'copy')
                Clipboard.setData(ClipboardData(text: device.peerId));
              if (value == 'edit') _editDevice(device: device);
              if (value == 'delete') _deleteDevice(device);
            },
            itemBuilder: (_) => const [
                  PopupMenuItem(value: 'copy', child: Text('Copiar ID')),
                  PopupMenuItem(
                      value: 'edit', child: Text('Editar computador')),
                  PopupMenuItem(
                      value: 'delete', child: Text('Remover computador')),
                ]),
      ]),
    );
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _editGroup([CentralGroup? group]) async {
    final name = await _textPrompt(
        group == null ? 'Novo cliente' : 'Renomear cliente', 'Nome do cliente',
        initial: group?.name ?? '');
    if (name == null || !mounted) return;
    await _perform(() async {
      if (_online) {
        final saved = group == null
            ? await _api!.createGroup(name)
            : await _api!.updateGroup(group.id, name);
        _expanded.add(saved.id);
        await _refreshCloud();
      } else {
        final saved = CentralGroup(id: group?.id ?? _id(), name: name);
        await _saveLocal(_local.withGroup(saved));
        _expanded.add(saved.id);
      }
    });
  }

  Future<void> _deleteGroup(CentralGroup group) async {
    final count = _catalog.devices.where((d) => d.groupId == group.id).length;
    if (_online && count > 0) {
      setState(() => _error = 'Remova ou mova os computadores de ${group.name} '
          'antes de excluir este cliente.');
      return;
    }
    final confirmed = await _confirm(
        'Excluir ${group.name}?',
        'O cliente e seus $count computadores serão removidos desta lista.'
            '${_online ? ' Os convites pendentes desse cliente serão cancelados.' : ''} '
            'O acesso remoto não será desinstalado.');
    if (!confirmed || !mounted) return;
    await _perform(() async {
      if (_online) {
        await _api!.deleteGroup(group.id);
        await _refreshCloud();
      } else {
        await _saveLocal(_local.withoutGroup(group.id));
      }
    });
  }

  Future<void> _editDevice({CentralGroup? group, CentralDevice? device}) async {
    final result = await showDialog<CentralDevice>(
        context: context,
        builder: (_) => _DeviceEditor(
            groups: _catalog.groups, group: group, device: device));
    if (result == null || !mounted) return;
    await _perform(() async {
      if (_online) {
        if (device == null)
          await _api!.createDevice(result);
        else
          await _api!.updateDevice(result);
        await _refreshCloud();
      } else {
        await _saveLocal(_local.withDevice(result));
      }
      _expanded.add(result.groupId);
      _queryPresence();
    });
  }

  Future<void> _deleteDevice(CentralDevice device) async {
    if (!await _confirm(
        'Remover ${device.name}?',
        _online
            ? 'O computador sairá da central e seu vínculo automático será revogado. '
                'O acesso remoto não será desinstalado.'
            : 'O computador será removido da lista local. O acesso remoto continuará instalado.'))
      return;
    if (!mounted) return;
    await _perform(() async {
      if (_online) {
        await _api!.deleteDevice(device.id);
        await _refreshCloud();
      } else {
        await _saveLocal(_local.withoutDevice(device.id));
      }
    });
  }

  Future<void> _toggleFavorite(CentralDevice device) async {
    if (_online) {
      setState(() => _cloudFavorites.contains(device.id)
          ? _cloudFavorites.remove(device.id)
          : _cloudFavorites.add(device.id));
    } else {
      await _perform(() => _saveLocal(
          _local.withDevice(device.copyWith(favorite: !device.favorite))));
    }
  }

  Future<void> _login() async {
    final result = await showDialog<List<String>>(
        context: context, builder: (_) => const _CredentialsDialog());
    if (result == null || !mounted) return;
    await _perform(() async {
      final api = CentralApi(result[0]);
      try {
        await api.login(result[1]);
        final catalog = await api.loadCatalog();
        if (!mounted) {
          try {
            await api.endSession();
          } finally {
            api.close();
          }
          return;
        }
        setState(() {
          _api = api;
          _cloud = catalog;
          _online = true;
          _cloudRefreshed = DateTime.now();
          _presence.clear();
          _expanded.addAll(catalog.groups.map((g) => g.id));
        });
        _queryPresence();
      } catch (_) {
        try {
          await api.endSession();
        } catch (_) {}
        api.close();
        rethrow;
      }
    });
  }

  Future<void> _logout() async {
    await _perform(() async {
      final api = _api;
      try {
        await api?.endSession();
      } finally {
        api?.close();
        if (mounted)
          setState(() {
            _api = null;
            _online = false;
            _cloud = CentralCatalog();
            _cloudFavorites.clear();
            _presence.clear();
          });
      }
      _queryPresence();
    });
  }

  Future<void> _invite(CentralGroup group) async {
    await _perform(() async {
      final invite = await _api!.createInvite(group.id);
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('Vincular computador a ${group.name}'),
                content: SizedBox(
                    width: 430,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                              'No computador do cliente, abra Meus clientes, clique em '
                              'Vincular este computador e informe o endereço e o convite abaixo.'),
                          const SizedBox(height: 14),
                          SelectableText(_api!.url),
                          const SizedBox(height: 12),
                          SelectableText(invite['code'].toString(),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          Text(
                              'Uso único. Validade: ${_date(DateTime.parse(invite['expires_at']))}.'),
                          const SizedBox(height: 10),
                          const Text(
                              'O convite cadastra o computador na lista. Ele não autoriza '
                              'o controle remoto nem substitui a senha.',
                              style: TextStyle(fontSize: 12, color: _muted)),
                        ])),
                actions: [
                  TextButton(
                      onPressed: () => Clipboard.setData(ClipboardData(
                          text: '${_api!.url}\n${invite['code']}')),
                      child: const Text('Copiar')),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fechar')),
                ],
              ));
    });
  }

  Future<void> _enrollment() async {
    String current;
    try {
      current = await widget.runtime.linkedEndpoint();
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
      return;
    }
    if (!mounted) return;
    if (current.isNotEmpty) {
      if (await _confirm(
          'Este computador já está vinculado',
          'Central: $current\n\nDesvincular interrompe o envio do ID e da presença '
              'deste computador. O registro pode ser removido pelo administrador. '
              'Deseja desvincular?')) {
        if (mounted) await _perform(widget.runtime.unlink);
      }
      return;
    }
    final result = await showDialog<List<String>>(
        context: context, builder: (_) => const _EnrollmentDialog());
    if (result == null || !mounted) return;
    await _perform(() async {
      final api = CentralApi(result[0]);
      try {
        final peerId = (await widget.runtime.ownPeerId()).replaceAll(' ', '');
        final response = await api.enroll(
            code: result[1],
            name: result[2],
            peerId: peerId,
            platform: widget.runtime.platform);
        await widget.runtime.link(
            url: api.url,
            token: response['device_token'] as String,
            deviceId: response['device_id'] as String,
            name: result[2]);
        if (mounted) {
          await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('Computador vinculado'),
                    content: Text('Cliente: ${response['group_name']}\n\n'
                        'O serviço Apollo11 enviará o ID e a presença a cada minuto. '
                        'Mantenha o serviço de acesso remoto ativo. '
                        'Para interromper, volte em Vincular este computador.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Entendi'))
                    ],
                  ));
        }
      } finally {
        api.close();
      }
    });
  }

  Future<void> _import() async {
    await _perform(() async {
      final selected = await FilePicker.platform.pickFiles(
          dialogTitle: 'Importar lista Apollo11',
          type: FileType.custom,
          allowedExtensions: ['json']);
      final path = selected?.files.single.path;
      if (path == null || !mounted) return;
      final file = File(path);
      if (await file.length() > 2 * 1024 * 1024) {
        throw const FormatException('O arquivo deve ter até 2 MB.');
      }
      final catalog = CentralCatalog.fromText(await file.readAsString());
      if (!mounted ||
          !await _confirm(
              'Importar esta lista?',
              '${catalog.groups.length} clientes e ${catalog.devices.length} computadores. '
                  'Esta ação substitui a lista local. Exporte a lista atual antes se quiser guardá-la.'))
        return;
      await _saveLocal(catalog);
      _expanded.addAll(catalog.groups.map((g) => g.id));
      _presence.clear();
      _queryPresence();
    });
  }

  Future<void> _export() async {
    await _perform(() async {
      final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Exportar lista Apollo11',
          fileName: 'Apollo11-clientes.json',
          type: FileType.custom,
          allowedExtensions: ['json']);
      if (path == null || !mounted) return;
      await File(path).writeAsString(_local.toText(), flush: true);
    });
  }

  Future<String?> _textPrompt(String title, String label,
      {String initial = ''}) async {
    var value = initial;
    final form = GlobalKey<FormState>();
    return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: Form(
                  key: form,
                  child: SizedBox(
                      width: 360,
                      child: TextFormField(
                          initialValue: initial,
                          onChanged: (text) => value = text,
                          validator: _validateName,
                          autofocus: true,
                          maxLength: 100,
                          decoration: InputDecoration(labelText: label),
                          onFieldSubmitted: (text) {
                            if (form.currentState!.validate())
                              Navigator.pop(context, text.trim());
                          }))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                TextButton(
                    onPressed: () {
                      if (form.currentState!.validate())
                        Navigator.pop(context, value.trim());
                    },
                    child: const Text('Salvar')),
              ],
            ));
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(title),
                content: SizedBox(width: 430, child: Text(message)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Confirmar')),
                ],
              )) ??
      false;
}

class _Presence {
  const _Presence(this.online, this.at);
  final bool online;
  final DateTime at;
}

String _id() => const Uuid().v4().replaceAll('-', '');

class _DeviceEditor extends StatefulWidget {
  const _DeviceEditor({required this.groups, this.group, this.device});
  final List<CentralGroup> groups;
  final CentralGroup? group;
  final CentralDevice? device;
  @override
  State<_DeviceEditor> createState() => _DeviceEditorState();
}

class _DeviceEditorState extends State<_DeviceEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.device?.name ?? '');
  late final _peerId = TextEditingController(text: widget.device?.peerId ?? '');
  late String _group = widget.device?.groupId ?? widget.group!.id;
  late String _platform = widget.device?.platform ?? 'Windows';
  @override
  void dispose() {
    _name.dispose();
    _peerId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.device == null
            ? 'Adicionar computador'
            : 'Editar computador'),
        content: SizedBox(
            width: 400,
            child: Form(
              key: _form,
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                    controller: _name,
                    autofocus: true,
                    maxLength: 100,
                    decoration:
                        const InputDecoration(labelText: 'Nome do computador'),
                    validator: _validateName),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _peerId,
                    decoration:
                        const InputDecoration(labelText: 'ID do acesso remoto'),
                    keyboardType: TextInputType.number,
                    validator: _validatePeerId),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                    value: _group,
                    decoration: const InputDecoration(labelText: 'Cliente'),
                    items: widget.groups
                        .map((g) =>
                            DropdownMenuItem(value: g.id, child: Text(g.name)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _group = value);
                    }),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                    value: _platform,
                    decoration: const InputDecoration(labelText: 'Sistema'),
                    items: const [
                      DropdownMenuItem(
                          value: 'Windows', child: Text('Windows')),
                      DropdownMenuItem(value: 'macOS', child: Text('macOS'))
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _platform = value);
                    }),
              ])),
            )),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () {
                if (_form.currentState!.validate()) {
                  Navigator.pop(
                      context,
                      CentralDevice(
                          id: widget.device?.id ?? _id(),
                          groupId: _group,
                          name: _name.text.trim(),
                          peerId: _peerId.text.replaceAll(' ', ''),
                          platform: _platform,
                          favorite: widget.device?.favorite ?? false,
                          lastSeen: widget.device?.lastSeen));
                }
              },
              child: const Text('Salvar')),
        ],
      );
}

class _CredentialsDialog extends StatefulWidget {
  const _CredentialsDialog();
  @override
  State<_CredentialsDialog> createState() => _CredentialsDialogState();
}

class _CredentialsDialogState extends State<_CredentialsDialog> {
  final _form = GlobalKey<FormState>();
  final _url = TextEditingController();
  final _password = TextEditingController();
  @override
  void dispose() {
    _url.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Entrar na Central Apollo11'),
        content: SizedBox(
            width: 430,
            child: Form(
              key: _form,
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Informe o endereço da sua central já instalada. '
                    'A lista local fica separada e continua salva neste computador.'),
                const SizedBox(height: 18),
                TextFormField(
                    controller: _url,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: 'Endereço da central (HTTPS)',
                        hintText: 'https://central.exemplo.com/api.php'),
                    validator: _validateUrl),
                const SizedBox(height: 14),
                TextFormField(
                    controller: _password,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(
                        labelText: 'Senha do administrador'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Informe a senha.'
                        : null),
                const SizedBox(height: 12),
                const Text(
                    'A senha e a sessão de administrador ficam apenas na memória '
                    'enquanto esta janela estiver aberta.',
                    style: TextStyle(fontSize: 12, color: _muted)),
              ])),
            )),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () {
                if (_form.currentState!.validate())
                  Navigator.pop(context, [_url.text.trim(), _password.text]);
              },
              child: const Text('Entrar')),
        ],
      );
}

class _EnrollmentDialog extends StatefulWidget {
  const _EnrollmentDialog();
  @override
  State<_EnrollmentDialog> createState() => _EnrollmentDialogState();
}

class _EnrollmentDialogState extends State<_EnrollmentDialog> {
  final _form = GlobalKey<FormState>();
  final _url = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController(text: Platform.localHostname);
  @override
  void dispose() {
    _url.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Vincular este computador'),
        content: SizedBox(
            width: 430,
            child: Form(
              key: _form,
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text(
                    'O vínculo envia o nome, o ID, o sistema e o último contato '
                    'deste computador à central informada. A senha de acesso remoto não é enviada.'),
                const SizedBox(height: 18),
                TextFormField(
                    controller: _url,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: 'Endereço da central (HTTPS)',
                        hintText: 'https://central.exemplo.com/api.php'),
                    validator: _validateUrl),
                const SizedBox(height: 14),
                TextFormField(
                    controller: _code,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                        labelText: 'Convite de uso único'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe o convite.'
                        : null),
                const SizedBox(height: 14),
                TextFormField(
                    controller: _name,
                    maxLength: 100,
                    decoration:
                        const InputDecoration(labelText: 'Nome do computador'),
                    validator: _validateName),
                const SizedBox(height: 12),
                const Text(
                    'O serviço de acesso remoto deve estar ativo para atualizar a '
                    'presença após fechar a janela.',
                    style: TextStyle(fontSize: 12, color: _muted)),
              ])),
            )),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () {
                if (_form.currentState!.validate())
                  Navigator.pop(context,
                      [_url.text.trim(), _code.text.trim(), _name.text.trim()]);
              },
              child: const Text('Vincular')),
        ],
      );
}

String? _validateUrl(String? value) {
  try {
    CentralApi.validateUrl((value ?? '').trim());
    return null;
  } catch (_) {
    return 'Informe uma URL HTTPS sem parâmetros ou credenciais.';
  }
}

String? _validateName(String? value) {
  try {
    centralText(value ?? '', 'Nome');
    return null;
  } on FormatException catch (error) {
    return error.message;
  }
}

String? _validatePeerId(String? value) {
  try {
    centralPeerId(value ?? '');
    return null;
  } on FormatException catch (error) {
    return error.message;
  }
}
