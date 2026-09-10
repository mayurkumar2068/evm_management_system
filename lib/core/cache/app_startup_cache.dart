import 'dart:io';

import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';

abstract final class AppStartupCache {
  static Future<void> clearOnLaunch() => clearDisposableCaches();

  static Future<void> clearDisposableCaches() async {
    await _clearImageCache();
    await _clearWebViewCache();
    await _clearDirectory(await _safeTempDir(), label: 'temp');
    await _clearDirectory(await _safeCacheDir(), label: 'app_cache');
    AppLogger.i('Disposable caches cleared');
  }

  static Future<void> clearGeneratedExports() async {
    final Directory? dir = await _safeTempDir();
    if (dir == null) return;
    await _deleteMatching(
      dir,
      (String name) =>
          name.startsWith('po_report_') && name.endsWith('.pdf') ||
          name.startsWith('voter_slip_') && name.endsWith('.png'),
    );
  }

  static Future<void> _clearImageCache() async {
    try {
      imageCache.clear();
      imageCache.clearLiveImages();
    } catch (e) {
      AppLogger.w('Image cache clear failed: $e');
    }
  }

  static Future<void> _clearWebViewCache() async {
    try {
      await InAppWebViewController.clearAllCache();
    } catch (e) {
      AppLogger.w('WebView cache clear failed: $e');
    }
  }

  static Future<Directory?> _safeTempDir() async {
    try {
      return await getTemporaryDirectory();
    } catch (e) {
      AppLogger.w('Temp directory unavailable: $e');
      return null;
    }
  }

  static Future<Directory?> _safeCacheDir() async {
    try {
      return await getApplicationCacheDirectory();
    } catch (e) {
      AppLogger.w('App cache directory unavailable: $e');
      return null;
    }
  }

  static Future<void> _clearDirectory(
    Directory? dir, {
    required String label,
  }) async {
    if (dir == null || !dir.existsSync()) return;
    try {
      for (final FileSystemEntity entity in dir.listSync()) {
        await _deleteEntity(entity);
      }
    } catch (e) {
      AppLogger.w('$label directory clear failed: $e');
    }
  }

  static Future<void> _deleteMatching(
    Directory dir,
    bool Function(String fileName) test,
  ) async {
    if (!dir.existsSync()) return;
    try {
      for (final FileSystemEntity entity in dir.listSync()) {
        if (entity is! File) continue;
        if (test(entity.uri.pathSegments.last)) {
          await _deleteEntity(entity);
        }
      }
    } catch (e) {
      AppLogger.w('Generated export cleanup failed: $e');
    }
  }

  static Future<void> _deleteEntity(FileSystemEntity entity) async {
    try {
      if (entity is File) {
        await entity.delete();
      } else if (entity is Directory) {
        await entity.delete(recursive: true);
      }
    } catch (_) {}
  }
}
