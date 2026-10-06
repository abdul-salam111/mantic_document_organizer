import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/features/bulk_import/domain/repositories/gallery_discovery_repository.dart';
import 'bulk_import_fakes.dart';

/// Covers `BulkImportViewModel.discoverAll` -- the combined gallery +
/// filesystem scan AutoImportService drives, as opposed to the existing,
/// unchanged `discover()` (gallery-only, used by the manual "Find more
/// documents" entry point and already covered by
/// bulk_import_viewmodel_test.dart).
void main() {
  late ImportFixture f;
  setUp(() {
    f = ImportFixture();
  });
  tearDown(() async {
    await f.vmWithFileSystem.cancel();
    f.vmWithFileSystem.dispose();
  });

  test(
    'scans both sources and accumulates combined counts and watermarks',
    () async {
      f.seedFoundAcrossSources(
        gallery: [candidate('a'), candidate('b')],
        fileSystem: [candidate('c'), candidate('d')],
      );
      final found = await f.vmWithFileSystem.discoverAll();
      expect(found, true);
      expect(f.vmWithFileSystem.candidates.map((c) => c.id).toSet(), {
        'a',
        'b',
        'c',
        'd',
      });
      expect(f.vmWithFileSystem.scanFound, 4);
      expect(f.vmWithFileSystem.scanExamined, 4);
      // Each source writes its own independent watermark.
      expect(f.watermarkStore.stored, isNotNull);
      expect(f.fileSystemWatermarkStore.stored, isNotNull);
    },
  );

  test(
    'one source denying permission does not block the other from scanning',
    () async {
      f.discovery.permission = DiscoveryPermission.denied;
      f.seedFoundAcrossSources(fileSystem: [candidate('a')]);
      final found = await f.vmWithFileSystem.discoverAll();
      expect(found, true);
      expect(f.vmWithFileSystem.permissionDenied, false);
      expect(f.vmWithFileSystem.candidates.single.id, 'a');
    },
  );

  test('permissionDenied is only set when every source denies', () async {
    f.discovery.permission = DiscoveryPermission.denied;
    f.fileSystemDiscovery.permission = DiscoveryPermission.denied;
    f.seedFoundAcrossSources(fileSystem: [candidate('a')]);
    final found = await f.vmWithFileSystem.discoverAll();
    expect(found, false);
    expect(f.vmWithFileSystem.permissionDenied, true);
    expect(f.imports.stageCalls, 0);
  });

  test('maxCandidatesOverride bounds the combined total, not per-source', () async {
    f.seedFoundAcrossSources(
      gallery: [candidate('a'), candidate('b')],
      fileSystem: [candidate('c'), candidate('d')],
    );
    final found = await f.vmWithFileSystem.discoverAll(
      maxCandidatesOverride: 3,
    );
    expect(found, true);
    expect(f.vmWithFileSystem.candidates.length, 3);
    expect(f.vmWithFileSystem.scanHasMore, true);
  });

  test(
    'allowPermissionPrompts false checks passively instead of requesting',
    () async {
      f.seedFoundAcrossSources(
        gallery: [candidate('a')],
        fileSystem: [candidate('b')],
      );
      final found = await f.vmWithFileSystem.discoverAll(
        allowPermissionPrompts: false,
      );
      expect(found, true);
      expect(f.discovery.requestPermissionCalls, 0);
      expect(f.discovery.hasPermissionCalls, 1);
      expect(f.fileSystemDiscovery.requestPermissionCalls, 0);
      expect(f.fileSystemDiscovery.hasPermissionCalls, 1);
    },
  );

  test(
    'allowPermissionPrompts false skips a source that is not yet passively granted',
    () async {
      f.discovery.passivelyGranted = false; // not yet decided this session
      // Gallery is skipped entirely (passive check fails) -- only seed the
      // filesystem source, since FakeImports.stage() pops staged
      // candidates in seeding order regardless of which source triggered
      // the call, and a skipped source never calls stage() at all.
      f.seedFoundAcrossSources(fileSystem: [candidate('b')]);
      final found = await f.vmWithFileSystem.discoverAll(
        allowPermissionPrompts: false,
      );
      expect(found, true);
      expect(f.discovery.findCandidatesCalls, 0);
      expect(f.fileSystemDiscovery.findCandidatesCalls, 1);
      expect(f.vmWithFileSystem.candidates.single.id, 'b');
    },
  );

  test('discover() never touches the filesystem source even when configured', () async {
    f.seedFoundAcrossSources(fileSystem: [candidate('a')]);
    final found = await f.vmWithFileSystem.discover();
    expect(found, false);
    expect(f.fileSystemDiscovery.requestPermissionCalls, 0);
    expect(f.fileSystemDiscovery.findCandidatesCalls, 0);
    expect(f.vmWithFileSystem.candidates, isEmpty);
  });
}
