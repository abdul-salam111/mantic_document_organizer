import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mantic_doc_org/features/bulk_import/domain/entities/bulk_import_candidate.dart';
import 'package:mantic_doc_org/features/bulk_import/domain/entities/discovered_asset.dart';
import 'package:mantic_doc_org/features/bulk_import/domain/repositories/bulk_import_repository.dart';
import 'package:mantic_doc_org/features/bulk_import/domain/repositories/discovery_examined_assets_repository.dart';
import 'package:mantic_doc_org/features/bulk_import/domain/repositories/discovery_watermark_repository.dart';
import 'package:mantic_doc_org/features/bulk_import/domain/repositories/gallery_discovery_repository.dart';
import 'package:mantic_doc_org/features/bulk_import/domain/usecases/bulk_import_usecases.dart';
import 'package:mantic_doc_org/features/bulk_import/domain/usecases/gallery_discovery_usecases.dart';
import 'package:mantic_doc_org/features/bulk_import/presentation/viewmodel/bulk_import_viewmodel.dart';
import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/categories/domain/repositories/category_repository.dart';
import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/attachment_item.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_suggestion.dart';
import 'package:mantic_doc_org/features/documents/domain/repositories/document_repository.dart';
import 'package:mantic_doc_org/features/documents/domain/repositories/document_processing_repository.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_processing_usecases.dart';

BulkImportCandidate candidate(String id, {String extension = 'jpg'}) =>
    BulkImportCandidate(
      id: id,
      attachment: AttachmentItem(
        path: '/staged/$id.$extension',
        type: AttachmentType.file,
      ),
      title: 'Original $id',
      categoryId: uncategorizedCategoryId,
    );

/// A discovered asset whose resolved path matches a `candidate(id)` fake
/// staged result, so a scan finding [id] and staging [id] line up 1:1.
DiscoveredAsset discoveredAsset(
  String id, {
  DateTime? takenAt,
  String extension = 'jpg',
}) => DiscoveredAsset(
  id: id,
  takenAt: takenAt ?? DateTime(2025, 1, 1),
  resolvePath: () async => '/gallery/$id.$extension',
);

class FakeImports implements BulkImportRepository {
  /// Consumed one at a time, in order, by [stage] -- mirrors production
  /// where discovery stages exactly one asset per call.
  List<BulkImportCandidate> picked = [];
  final removed = <String>[];
  final rolledBack = <String>[];
  final promoted = <String>[];
  final copyFailures = <String>{};
  int discarded = 0;
  int? limit;
  int stageCalls = 0;
  Completer<BulkPickResult>? pickGate;
  @override
  Future<BulkPickResult> stage(
    List<({String? path, String name})> files, {
    required int limit,
  }) async {
    this.limit = limit;
    stageCalls++;
    if (pickGate != null) return pickGate!.future;
    if (picked.isEmpty) return const BulkPickResult([]);
    return BulkPickResult([picked.removeAt(0)]);
  }

  @override
  Future<String> promote(BulkImportCandidate candidate) async {
    if (copyFailures.contains(candidate.id)) throw StateError('copy failed');
    promoted.add(candidate.id);
    return '/permanent/${candidate.id}.jpg';
  }

  @override
  Future<void> removeStaged(BulkImportCandidate candidate) async {
    removed.add(candidate.id);
  }

  @override
  Future<void> removePromoted(String path) async {
    rolledBack.add(path);
  }

  @override
  Future<void> discard() async {
    discarded++;
  }
}

class FakeDiscovery implements GalleryDiscoveryRepository {
  DiscoveryPermission permission = DiscoveryPermission.granted;
  // Independent of [permission] -- lets a test simulate "not yet decided,
  // would show a prompt if asked" (passive check false) vs. "already
  // granted" (passive check true), the distinction allowPermissionPrompts
  // exists to respect.
  bool passivelyGranted = true;
  List<DiscoveredAsset> assets = [];
  int openSettingsCalls = 0;
  int findCandidatesCalls = 0;
  int requestPermissionCalls = 0;
  int hasPermissionCalls = 0;
  DateTime? lastSince;
  int? lastMaxExamined;

  @override
  Future<DiscoveryPermission> requestPermission() async {
    requestPermissionCalls++;
    return permission;
  }

  @override
  Future<bool> hasPermission() async {
    hasPermissionCalls++;
    return passivelyGranted;
  }

  @override
  Future<void> openSettings() async {
    openSettingsCalls++;
  }

  @override
  Future<List<DiscoveredAsset>> findCandidates({
    required DateTime? since,
    required int maxExamined,
  }) async {
    findCandidatesCalls++;
    lastSince = since;
    lastMaxExamined = maxExamined;
    return assets.take(maxExamined).toList();
  }
}

class FakeConnectivity {
  bool online = true;
  Future<bool> check() async => online;
}

class FakeWatermarkStore implements DiscoveryWatermarkRepository {
  DateTime? stored;
  @override
  Future<DateTime?> read() async => stored;
  @override
  Future<void> write(DateTime value) async {
    stored = value;
  }
}

/// In-memory stand-in for the real sqflite-backed store -- mirrors its
/// exact-id dedup contract without touching a database.
class FakeExaminedAssetsStore implements DiscoveryExaminedAssetsRepository {
  final examined = <String>{};
  int markExaminedCalls = 0;

  @override
  Future<List<String>> filterUnexamined(List<String> assetIds) async =>
      [for (final id in assetIds) if (!examined.contains(id)) id];

  @override
  Future<void> markExamined(List<String> assetIds) async {
    markExaminedCalls++;
    examined.addAll(assetIds);
  }
}

class FakeCategories extends ChangeNotifier implements ICategoryRepository {
  @override
  List<CategoryItem> categories = [
    const CategoryItem(id: 'bank', name: 'Bank', iconKey: 'bank'),
    const CategoryItem(id: 'personal', name: 'Personal', iconKey: 'file'),
  ];
  @override
  Future<void> init() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocuments extends ChangeNotifier implements IDocumentRepository {
  @override
  final List<DocumentItem> documents = [];
  final failures = <String>{};
  Completer<void>? gate;
  @override
  Future<void> addDocument(DocumentItem document) async {
    if (gate != null) await gate!.future;
    if (failures.contains(document.id)) throw StateError('database failed');
    documents.add(document);
  }

  @override
  Future<void> init() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProcessing implements IDocumentProcessingRepository {
  final calls = <String>[];
  int concurrent = 0;
  int maxConcurrent = 0;
  int analysisCalls = 0;
  int _analyzeConcurrent = 0;
  int maxAnalyzeConcurrent = 0;
  Completer<String>? ocrGate;
  Completer<AiDocumentSuggestion?>? suggestionGate;
  // Non-empty by default so discover()'s free "no readable text" filter
  // doesn't reject a candidate before the (faked) AI call ever runs.
  String text =
      'INVOICE\nBill To: Example Customer\nDue Date: 2025-01-01\n'
      'Description of services rendered for the period.';
  AiDocumentSuggestion? suggestion = AiDocumentSuggestion(
    isDocument: true,
    title: 'Suggested title',
    categoryName: 'Bank',
    description: 'Suggested description',
    tags: [
      'BANK statement',
      'bank-statement',
      'valid',
      'other',
      'fourth',
      '!invalid',
    ],
    isExpirable: true,
    expiryDate: DateTime(2030, 6, 4),
  );
  @override
  Future<String> extractText(String path) async {
    calls.add(path);
    concurrent++;
    if (concurrent > maxConcurrent) maxConcurrent = concurrent;
    try {
      return ocrGate == null ? text : await ocrGate!.future;
    } finally {
      concurrent--;
    }
  }

  @override
  Future<AiDocumentSuggestion?> analyze({
    required String ocrText,
    required List<String> availableCategories,
  }) async {
    analysisCalls++;
    _analyzeConcurrent++;
    if (_analyzeConcurrent > maxAnalyzeConcurrent) {
      maxAnalyzeConcurrent = _analyzeConcurrent;
    }
    try {
      return suggestionGate == null ? suggestion : await suggestionGate!.future;
    } finally {
      _analyzeConcurrent--;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ImportFixture {
  final imports = FakeImports();
  final categories = FakeCategories();
  final documents = FakeDocuments();
  final processing = FakeProcessing();
  final discovery = FakeDiscovery();
  final watermarkStore = FakeWatermarkStore();
  final examinedAssetsStore = FakeExaminedAssetsStore();
  final connectivity = FakeConnectivity();
  late final vm = BulkImportViewModel(
    imports: BulkImportUseCases(imports),
    categories: CategoryUseCases(categories),
    documents: DocumentUseCases(documents),
    processing: DocumentProcessingUseCases(processing),
    discovery: GalleryDiscoveryUseCases(discovery),
    watermark: watermarkStore,
    examinedAssets: examinedAssetsStore,
    checkConnectivity: connectivity.check,
  );

  /// Convenience for the common case: [candidates] are "found" by discovery
  /// (one matching asset each, same order) and successfully staged.
  void seedFound(List<BulkImportCandidate> candidates) {
    imports.picked = List.of(candidates);
    discovery.assets = [for (final c in candidates) discoveredAsset(c.id)];
  }

  // Second discovery source + watermark, wired into [vmWithFileSystem]
  // only -- [vm] above stays gallery-only, matching production's
  // `discover()` (manual "Find more documents") vs. `discoverAll()`
  // (AutoImportService) split.
  final fileSystemDiscovery = FakeDiscovery();
  final fileSystemWatermarkStore = FakeWatermarkStore();
  final fileSystemExaminedAssetsStore = FakeExaminedAssetsStore();
  late final vmWithFileSystem = BulkImportViewModel(
    imports: BulkImportUseCases(imports),
    categories: CategoryUseCases(categories),
    documents: DocumentUseCases(documents),
    processing: DocumentProcessingUseCases(processing),
    discovery: GalleryDiscoveryUseCases(discovery),
    watermark: watermarkStore,
    examinedAssets: examinedAssetsStore,
    checkConnectivity: connectivity.check,
    fileSystemDiscovery: GalleryDiscoveryUseCases(fileSystemDiscovery),
    fileSystemWatermark: fileSystemWatermarkStore,
    fileSystemExaminedAssets: fileSystemExaminedAssetsStore,
  );

  /// Like [seedFound], but splits candidates across the gallery and
  /// filesystem sources (gallery scanned first, matching
  /// [vmWithFileSystem]'s scan order) -- for discoverAll() tests.
  void seedFoundAcrossSources({
    List<BulkImportCandidate> gallery = const [],
    List<BulkImportCandidate> fileSystem = const [],
  }) {
    imports.picked = [...gallery, ...fileSystem];
    discovery.assets = [for (final c in gallery) discoveredAsset(c.id)];
    fileSystemDiscovery.assets = [
      for (final c in fileSystem) discoveredAsset(c.id),
    ];
  }
}
