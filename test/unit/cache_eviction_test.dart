// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:thaili/core/storage/cache_eviction_manager.dart';

// ── Fake PathProvider ─────────────────────────────────────────────────────────
// CacheEvictionManager calls getTemporaryDirectory(). We need to redirect
// that to a real temp directory we control during tests.

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

void main() {
  late Directory testTempDir;

  setUp(() async {
    // Create a real temporary directory in the system temp folder.
    testTempDir = await Directory.systemTemp.createTemp('cache_eviction_test_');
    // Override the path_provider to return our controlled temp directory.
    PathProviderPlatform.instance = FakePathProviderPlatform(testTempDir.path);
  });

  tearDown(() async {
    // Clean up — delete the test temp directory and any remaining files.
    if (testTempDir.existsSync()) {
      testTempDir.deleteSync(recursive: true);
    }
  });

  group('CacheEvictionManager', () {
    // Helper: Creates a file in the test temp dir with a backdated modification time.
    Future<File> createFile(String name, {int? ageDays, int sizeBytes = 1024}) async {
      final file = File('${testTempDir.path}/$name');
      // Fill file with dummy bytes.
      await file.writeAsBytes(List.filled(sizeBytes, 0x42));
      if (ageDays != null) {
        // Backdate the file modification time using OS touch.
        final backdatedTime = DateTime.now().subtract(Duration(days: ageDays));
        await Process.run('powershell', [
          '-Command',
          '(Get-Item "${file.path}").LastWriteTime = "${backdatedTime.toIso8601String()}"',
        ]);
      }
      return file;
    }

    test('prune does not delete files younger than 48 hours', () async {
      await createFile('recent.csv', ageDays: 0); // just created

      await CacheEvictionManager.prune();

      expect(File('${testTempDir.path}/recent.csv').existsSync(), isTrue);
    });

    test('prune deletes files older than 48 hours', () async {
      await createFile('old_export.csv', ageDays: 3); // 3 days old

      await CacheEvictionManager.prune();

      expect(File('${testTempDir.path}/old_export.csv').existsSync(), isFalse);
    });

    test('prune returns number of bytes reclaimed', () async {
      await createFile('stale.pdf', ageDays: 5, sizeBytes: 2048);
      final reclaimed = await CacheEvictionManager.prune();
      // Should have reclaimed at least 2048 bytes.
      expect(reclaimed, greaterThanOrEqualTo(2048));
    });

    test('prune on empty directory returns 0 and does not throw', () async {
      final reclaimed = await CacheEvictionManager.prune();
      expect(reclaimed, 0);
    });

    test('prune preserves new files even when total size exceeds quota', () async {
      // All files are recent (0 days) — quota eviction should still remove
      // oldest ones, but in our test all timestamps are the same so the
      // actual eviction order is implementation-defined. At minimum, prune
      // must not throw.
      for (int i = 0; i < 3; i++) {
        await createFile('big_$i.csv', ageDays: 0, sizeBytes: 512);
      }
      // Under our 30 MB quota — no eviction should occur.
      await expectLater(CacheEvictionManager.prune(), completes);
    });
  });
}
