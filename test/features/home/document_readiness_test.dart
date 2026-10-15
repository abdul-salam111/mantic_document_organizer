import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/home/domain/entities/document_readiness.dart';

DocumentItem document({String id = 'one', String title = '', String categoryId = 'bank', DateTime? deletedAt, List<String> files = const ['file.pdf']}) => DocumentItem(
  id: id, title: title, category: categoryId, categoryId: categoryId,
  iconKey: 'solidFolder', createdAt: DateTime(2026), filePaths: files, deletedAt: deletedAt,
);
void main() {
  test('five fixed groups, empty library has no completed groups', () {
    final items = evaluateReadiness([], ReadinessPreferences());
    expect(items.length, 5);
    expect(items.any((i) => i.complete), false);
  });
  test('specific identity alternatives satisfy a single group', () {
    final items = evaluateReadiness([document(categoryId: 'passports'), document(id: 'two', categoryId: 'id_card')], ReadinessPreferences());
    expect(items.where((i) => i.complete).length, 1);
    expect(items.first.document, isNotNull);
  });
  test('broad categories and incidental title mentions do not count', () {
    final items = evaluateReadiness([
      document(categoryId: 'medical', title: 'Hospital parking receipt'),
      document(id: 'two', title: 'How to request a bank statement'),
    ], ReadinessPreferences());
    expect(items.any((i) => i.complete), false);
  });
  test('exact document labels recognize records outside default categories', () {
    final items = evaluateReadiness([document(title: 'شهادة ميلاد', categoryId: 'custom')], ReadinessPreferences());
    expect(items.singleWhere((i) => i.group == ReadinessGroup.birth).complete, true);
  });
  test('explicit links survive moves and trash/restore, never count trash', () {
    final preferences = ReadinessPreferences(links: {ReadinessGroup.finance: 'one'});
    final original = document(categoryId: 'custom');
    bool complete(DocumentItem doc) => evaluateReadiness([doc], preferences).last.complete;
    expect(complete(original), true);
    expect(complete(original.markDeleted(DateTime(2026))), false);
    expect(complete(original.markDeleted(DateTime(2026)).restored()), true);
    expect(evaluateReadiness([], preferences).last.complete, false);
  });
  test('empty attachment records never count and exclusions are not completed', () {
    final items = evaluateReadiness([document(categoryId: 'id_card', files: [])], ReadinessPreferences(excluded: ReadinessGroup.values.toSet()));
    expect(items.every((i) => i.excluded), true);
    expect(items.any((i) => i.complete), false);
  });
}
