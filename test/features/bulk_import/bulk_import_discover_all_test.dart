import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/features/bulk_import/domain/repositories/gallery_discovery_repository.dart';
import 'bulk_import_fakes.dart';

/// Covers `BulkImportViewModel.discoverAll` -- the combined gallery +
/// filesystem scan AutoImportService drives for every entry point
/// (automatic first scan AND the manual "Find more documents" tile; see
/// AutoImportService.runManualScan), as opposed to the existing, unchanged,
/// gallery-only `discover()` (no longer reachable from the UI, but still
/// covered by bulk_import_viewmodel_test.dart).
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

  test(
    'discoverAll is uncapped -- every candidate across both sources is '
    'found in one pass',
    () async {
      f.seedFoundAcrossSources(
        gallery: [candidate('a'), candidate('b')],
        fileSystem: [candidate('c'), candidate('d')],
      );
      final found = await f.vmWithFileSystem.discoverAll();
      expect(found, true);
      expect(f.vmWithFileSystem.candidates.length, 4);
    },
  );

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

  group('restrictToRecentWindow', () {
    test(
      'defaults to true: a never-scanned source gets a null `since`, '
      'letting the discovery datasource apply its own ~12-month window',
      () async {
        f.seedFoundAcrossSources(
          gallery: [candidate('a')],
          fileSystem: [candidate('b')],
        );
        await f.vmWithFileSystem.discoverAll();
        expect(f.discovery.lastSince, isNull);
        expect(f.fileSystemDiscovery.lastSince, isNull);
      },
    );

    test(
      'false: a never-scanned source gets an epoch `since`, overriding the '
      "datasource's default window so the whole history is covered",
      () async {
        f.seedFoundAcrossSources(
          gallery: [candidate('a')],
          fileSystem: [candidate('b')],
        );
        await f.vmWithFileSystem.discoverAll(restrictToRecentWindow: false);
        expect(f.discovery.lastSince, DateTime.fromMillisecondsSinceEpoch(0));
        expect(
          f.fileSystemDiscovery.lastSince,
          DateTime.fromMillisecondsSinceEpoch(0),
        );
      },
    );

    test(
      'an existing watermark is always respected as-is, regardless of '
      'restrictToRecentWindow',
      () async {
        final watermark = DateTime(2025, 3, 1);
        f.watermarkStore.stored = watermark;
        f.fileSystemWatermarkStore.stored = watermark;
        f.seedFoundAcrossSources(
          gallery: [candidate('a')],
          fileSystem: [candidate('b')],
        );
        await f.vmWithFileSystem.discoverAll(restrictToRecentWindow: false);
        expect(f.discovery.lastSince, watermark);
        expect(f.fileSystemDiscovery.lastSince, watermark);
      },
    );
  });

  group('exact id-based dedup (discovery_examined_assets)', () {
    test(
      'each source records its own examined assets independently',
      () async {
        f.seedFoundAcrossSources(gallery: [candidate('a')]);
        await f.vmWithFileSystem.discoverAll();
        expect(f.examinedAssetsStore.examined, {'a'});
        expect(f.fileSystemExaminedAssetsStore.examined, isEmpty);
      },
    );

    test(
      'an asset already examined on either source is never reconsidered, '
      'even after both watermarks are rolled back far enough that date '
      'alone would offer it again',
      () async {
        f.seedFoundAcrossSources(
          gallery: [candidate('a')],
          fileSystem: [candidate('b')],
        );
        final firstFound = await f.vmWithFileSystem.discoverAll();
        expect(firstFound, true);
        expect(f.examinedAssetsStore.examined, {'a'});
        expect(f.fileSystemExaminedAssetsStore.examined, {'b'});

        f.watermarkStore.stored = DateTime(2000, 1, 1);
        f.fileSystemWatermarkStore.stored = DateTime(2000, 1, 1);
        f.seedFoundAcrossSources(
          gallery: [candidate('a')],
          fileSystem: [candidate('b')],
        );
        final secondFound = await f.vmWithFileSystem.discoverAll();
        // false (nothing *new* found) -- not the same as *zero* candidates,
        // since candidates accumulate across repeat scans by design (a
        // second "find more" tap adds to the review list, it doesn't reset
        // it). The real assertion is that the count didn't grow: 'a' and
        // 'b' from the first scan are still the only two, never duplicated.
        expect(secondFound, false);
        expect(f.vmWithFileSystem.candidates.map((c) => c.id).toSet(), {
          'a',
          'b',
        });
      },
    );
  });
}
