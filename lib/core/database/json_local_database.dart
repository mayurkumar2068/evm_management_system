import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:evm_management_system/core/database/local_database.dart';
import 'package:evm_management_system/core/error/app_exception.dart';
import 'package:path_provider/path_provider.dart';

/// File-backed implementation of [LocalDatabase].
///
/// Each collection is persisted as a single JSON document under the app's
/// support directory and mirrored in an in-memory map for fast reads. This is
/// the zero-codegen default; replace with `IsarLocalDatabase` for large
/// datasets by swapping the provider binding only.
class JsonLocalDatabase implements LocalDatabase {
  final Map<String, Map<String, Map<String, dynamic>>> _cache =
      <String, Map<String, Map<String, dynamic>>>{};
  final Map<String, StreamController<List<Map<String, dynamic>>>> _watchers =
      <String, StreamController<List<Map<String, dynamic>>>>{};
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
      // Atomic write: serialise to a sibling temp file, then rename over the
      // target. A crash mid-write can only ever leave the old (valid) file or
      // an orphan ".tmp" — never a half-written, corrupt JSON document.
      final File target = _file(collection);
      final File tmp = File('${target.path}.tmp');
      await tmp.writeAsString(jsonEncode(_cache[collection]), flush: true);
      await tmp.rename(target.path);
      _emit(collection);
    } catch (e, s) {
      throw CacheException(
        'flush($collection) failed',
        cause: e,
        stackTrace: s,
      );
    }
  }

  void _emit(String collection) {
    // Borrowed reference to an existing controller; ownership/closing is
    // handled by [dispose], so this is not a leak.
    // ignore: close_sinks
    final StreamController<List<Map<String, dynamic>>>? controller =
        _watchers[collection];
    if (controller != null && !controller.isClosed) {
      controller.add(_cache[collection]!.values.toList(growable: false));
    }
  }

  @override
  Future<void> put(
    String collection,
    String id,
    Map<String, dynamic> value,
  ) async {
    final Map<String, Map<String, dynamic>> data = await _load(collection);
    data[id] = value;
    await _flush(collection);
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
  Future<void> delete(String collection, String id) async {
    final Map<String, Map<String, dynamic>> data = await _load(collection);
    data.remove(id);
    await _flush(collection);
  }

  @override
  Future<void> clear(String collection) async {
    final Map<String, Map<String, dynamic>> data = await _load(collection);
    data.clear();
    await _flush(collection);
  }

  @override
  Stream<List<Map<String, dynamic>>> watch(String collection) {
    final StreamController<List<Map<String, dynamic>>> controller = _watchers
        .putIfAbsent(
          collection,
          () => StreamController<List<Map<String, dynamic>>>.broadcast(),
        );
    unawaited(_load(collection).then((_) => _emit(collection)));
    return controller.stream;
  }

  /// Closes all watch controllers. Called on app teardown.
  Future<void> dispose() async {
    for (final StreamController<List<Map<String, dynamic>>> c
        in _watchers.values) {
      await c.close();
    }
    _watchers.clear();
  }
}
