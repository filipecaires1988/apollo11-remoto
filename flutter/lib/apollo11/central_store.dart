import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'central_data.dart';

class CentralStore {
  final File? file;
  CentralStore({this.file});

  Future<File> _target() async {
    if (file != null) return file!;
    final directory = await getApplicationSupportDirectory();
    return File(
        '${directory.path}${Platform.pathSeparator}apollo11-central${Platform.pathSeparator}catalog.json');
  }

  Future<CentralCatalog> load() async {
    final target = await _target();
    final backup = File('${target.path}.bak');
    if (!await target.exists()) {
      if (await backup.exists()) {
        return _read(backup);
      }
      return CentralCatalog();
    }
    return _read(target);
  }

  Future<CentralCatalog> _read(File source) async {
    if (await source.length() > centralMaxBytes) {
      throw const FormatException('O cadastro local excedeu o limite de 2 MB.');
    }
    return CentralCatalog.fromText(await source.readAsString());
  }

  Future<void> save(CentralCatalog catalog) async {
    final target = await _target();
    await target.parent.create(recursive: true);
    final text = catalog.toText();
    CentralCatalog.fromText(text);
    final temporary = File('${target.path}.tmp');
    final backup = File('${target.path}.bak');
    await temporary.writeAsString(text, flush: true);
    var moved = false;
    try {
      if (await target.exists()) {
        if (await backup.exists()) await backup.delete();
        await target.rename(backup.path);
        moved = true;
      }
      await temporary.rename(target.path);
    } catch (_) {
      if (moved && !await target.exists() && await backup.exists()) {
        await backup.rename(target.path);
      }
      rethrow;
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }
}
