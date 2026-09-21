import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Manages TTL and quota-based eviction of temporary cache files.
///
/// Policy:
/// - Files older than [_ttl] (default 48 hours) are deleted.
/// - If total cached files exceed [_maxQuotaBytes] (default 30 MB),
///   the oldest files are pruned first until under the quota.
///
/// Call [prune] at app startup and after every export operation to keep
/// the app's cache directory from accumulating exported PDFs and CSVs.
class CacheEvictionManager {
  CacheEvictionManager._();

  /// Files older than this duration are automatically evicted.
  static const Duration _ttl = Duration(hours: 48);

  /// Maximum total byte size of files in the cache directory before
  /// oldest-first eviction begins.
  static const int _maxQuotaBytes = 30 * 1024 * 1024; // 30 MB

  /// Runs the two-phase eviction strategy on the system temp directory.
  ///
  /// Phase 1 — TTL eviction: deletes files older than [_ttl].
  /// Phase 2 — Quota eviction: if total size still exceeds [_maxQuotaBytes],
  ///   sorts remaining files oldest-first and deletes until under quota.
  ///
  /// Returns a summary of how many bytes were reclaimed.
  static Future<int> prune() async {
    try {
      final dir = await getTemporaryDirectory();
      return await _pruneDirectory(dir);
    } catch (e, stack) {
      debugPrint('[CacheEvictionManager.prune] Error: $e\n$stack');
      return 0;
    }
  }

  static Future<int> _pruneDirectory(Directory dir) async {
    if (!dir.existsSync()) return 0;

    int reclaimedBytes = 0;
    final now = DateTime.now();

    final files = dir
        .listSync(recursive: false)
        .whereType<File>()
        .toList();

    // ── Phase 1: TTL eviction ─────────────────────────────────────────────
    final surviving = <File>[];
    for (final file in files) {
      try {
        final stat = file.statSync();
        final age = now.difference(stat.modified);
        if (age > _ttl) {
          reclaimedBytes += stat.size;
          file.deleteSync();
          debugPrint('[CacheEvictionManager] TTL evicted: ${file.path} (${stat.size} bytes)');
        } else {
          surviving.add(file);
        }
      } catch (e) {
        // If we can't stat/delete, skip gracefully.
        debugPrint('[CacheEvictionManager] Skipping file: ${file.path}: $e');
      }
    }

    // ── Phase 2: Quota eviction (oldest-first) ────────────────────────────
    int totalSize = 0;
    final withStats = <({File file, FileStat stat})>[];

    for (final file in surviving) {
      try {
        final stat = file.statSync();
        totalSize += stat.size;
        withStats.add((file: file, stat: stat));
      } catch (_) {}
    }

    if (totalSize > _maxQuotaBytes) {
      // Sort oldest modification time first.
      withStats.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));

      for (final entry in withStats) {
        if (totalSize <= _maxQuotaBytes) break;
        try {
          final size = entry.stat.size;
          entry.file.deleteSync();
          totalSize -= size;
          reclaimedBytes += size;
          debugPrint('[CacheEvictionManager] Quota evicted: ${entry.file.path} ($size bytes)');
        } catch (e) {
          debugPrint('[CacheEvictionManager] Could not delete: ${entry.file.path}: $e');
        }
      }
    }

    debugPrint(
      '[CacheEvictionManager] Prune complete. Reclaimed: '
      '${(reclaimedBytes / 1024).toStringAsFixed(1)} KB. '
      'Remaining cache: ${(totalSize / 1024).toStringAsFixed(1)} KB.',
    );
    return reclaimedBytes;
  }
}
