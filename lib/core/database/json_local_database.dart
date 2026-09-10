import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:evm_management_system/core/database/local_database.dart';
import 'package:evm_management_system/core/error/app_exception.dart';
import 'package:path_provider/path_provider.dart';

class JsonLocalDatabase implements LocalDatabase {
  final Map<String, Map<String, Map<String, dynamic>>> _cache =
      <String, Map<String, Map<String, dynamic>>>{};
  final Map<String, StreamController<List<Map<String, dynamic>>>> _watchers =
      <String, StreamController<List<Map<String, dynamic>>>>{};

  final Map<String, Future<void>> _writeChain = <String, Future<void>>{};

  late final Directory _dir;
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    final Directory base = await getApplicationSupportDirectory();
    _dir = Directory('${base.path}/evm_db');
    if (!_dir.existsSync()) {
      _dir.createSync(recursive: true);
    }
    _initialized = true;
  }

  File _file(String collection) => File('${_dir.path}/$collection.json');

  Future<void> _runExclusive(
    String collection,
    Future<void> Function() action,
  ) {
    final Future<void> previous =
        _writeChain[collection] ?? Future<void>.value();
    final Future<void> next = previous.catchError((Object _) {}).then((_) {
      return action();
    });
    _writeChain[collection] = next.catchError((Object _) {});
    return next;
  }

  Future<Map<String, Map<String, dynamic>>> _load(String collection) async {
    if (_cache.containsKey(collection)) return _cache[collection]!;
    final File file = _file(collection);
    final Map<String, Map<String, dynamic>> data =
        <String, Map<String, dynamic>>{};
    try {
      if (file.existsSync()) {
        final Object? decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) {
          decoded.forEach((String key, Object? value) {
            if (value is Map<String, dynamic>) data[key] = value;
          });
        }
      }
    } catch (e, s) {
      throw CacheException('load($collection) failed', cause: e, stackTrace: s);
    }
    _cache[collection] = data;
    return data;
  }

  Future<void> _flush(String collection) async {
    try {
      final File target = _file(collection);
      final File tmp = File('${target.path}.tmp');
      final Map<String, Map<String, dynamic>> snapshot =
          _cache[collection] ?? <String, Map<String, dynamic>>{};
      await tmp.writeAsString(jsonEncode(snapshot), flush: true);
      await _replaceAtomically(tmp: tmp, target: target);
      _emit(collection);
    } catch (e, s) {
      throw CacheException(
        'flush($collection) failed: $e',
        cause: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _replaceAtomically({
    required File tmp,
    required File target,
  }) async {
    try {
      if (await target.exists()) {
        await target.delete();
      }
      await tmp.rename(target.path);
    } on FileSystemException {
      if (await tmp.exists()) {
        await tmp.copy(target.path);
        try {
          await tmp.delete();
        } catch (_) {}
      } else {
        rethrow;
      }
    }
  }

  void _emit(String collection) {
    // ignore: close_sinks
    final StreamController<List<Map<String, dynamic>>>? controller =
        _watchers[collection];
    if (controller != null && !controller.isClosed) {
      controller.add(
        (_cache[collection] ?? <String, Map<String, dynamic>>{}).values.toList(
          growable: false,
        ),
      );
    }
  }

  @override
  Future<void> put(String collection, String id, Map<String, dynamic> value) {
    return _runExclusive(collection, () async {
      final Map<String, Map<String, dynamic>> data = await _load(collection);
      data[id] = value;
      await _flush(collection);
    });
  }

  @override
  Future<Map<String, dynamic>?> get(String collection, String id) async {
    final Map<String, Map<String, dynamic>> data = await _load(collection);
    return data[id];
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    final Map<String, Map<String, dynamic>> data = await _load(collection);
    return data.values.toList(growable: false);
  }

  @override
  Future<void> delete(String collection, String id) {
    return _runExclusive(collection, () async {
      final Map<String, Map<String, dynamic>> data = await _load(collection);
      data.remove(id);
      await _flush(collection);
    });
  }

  @override
  Future<void> clear(String collection) {
    return _runExclusive(collection, () async {
      final Map<String, Map<String, dynamic>> data = await _load(collection);
      data.clear();
      await _flush(collection);
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watch(String collection) {
    // ignore: close_sinks
    final StreamController<List<Map<String, dynamic>>> controller = _watchers
        .putIfAbsent(
          collection,
          () => StreamController<List<Map<String, dynamic>>>.broadcast(),
        );
    unawaited(_load(collection).then((_) => _emit(collection)));
    return controller.stream;
  }

  Future<void> dispose() async {
    for (final StreamController<List<Map<String, dynamic>>> c
        in _watchers.values) {
      await c.close();
    }
    _watchers.clear();
  }
}
