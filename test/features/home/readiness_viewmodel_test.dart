import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mantic_doc_org/core/shared/domain/result/result.dart';
import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:mantic_doc_org/features/home/data/repository_impl/readiness_repository_impl.dart';
import 'package:mantic_doc_org/features/home/domain/entities/document_readiness.dart';
import 'package:mantic_doc_org/features/home/domain/usecases/readiness_usecases.dart';
import 'package:mantic_doc_org/features/home/viewmodel/readiness_viewmodel.dart';
import '../bulk_import/bulk_import_fakes.dart';
import 'document_readiness_test.dart' show document;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  ReadinessViewModel create(FakeDocuments documents, FakeCategories categories) {
    final repository = ReadinessRepositoryImpl();
    return ReadinessViewModel(documents: DocumentUseCases(documents), categories: CategoryUseCases(categories),
      load: LoadReadiness(repository), save: SaveReadiness(repository));
  }
  test('links and exclusions survive recreation; all excluded is neutral', () async {
    final documents = FakeDocuments()..documents.add(document());
    final categories = FakeCategories();
    final vm = create(documents, categories);
    await vm.init();
    await vm.link(ReadinessGroup.finance, documents.documents.first);
    expect(vm.completed, 1);
    await vm.setExcluded(ReadinessGroup.birth, true);
    expect(vm.total, 4);
    vm.dispose();
    final restored = create(documents, categories);
    await restored.init();
    expect(restored.completed, 1);
    expect(restored.total, 4);
    for (final group in ReadinessGroup.values) {
      await restored.setExcluded(group, true);
    }
    expect(restored.total, 0);
    expect(restored.progress, 0);
    await restored.setExcluded(ReadinessGroup.finance, false);
    expect(restored.progress, 1);
    restored.dispose(); documents.dispose(); categories.dispose();
  });
  test('unavailable documents cannot be linked', () async {
    final documents = FakeDocuments();
    final categories = FakeCategories();
    final vm = create(documents, categories);
    await vm.init();
    await vm.link(ReadinessGroup.finance, document());
    final stored = await ReadinessRepositoryImpl().load();
    expect((stored as Success<ReadinessPreferences>).value.links, isEmpty);
    vm.dispose(); documents.dispose(); categories.dispose();
  });
  test('invalid persisted preferences return failure rather than overwriting them', () async {
    FlutterSecureStorage.setMockInitialValues({'documentReadiness.v1': 'invalid'});
    expect(await ReadinessRepositoryImpl().load(), isA<Failure<ReadinessPreferences>>());
  });
}
