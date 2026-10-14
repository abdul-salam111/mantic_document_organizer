import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:mantic_doc_org/features/search/presentation/search/viewmodels/search_viewmodel.dart';

import '../bulk_import/bulk_import_fakes.dart';

DocumentItem _doc({
  required String id,
  required String title,
  String category = 'Bank',
  String categoryId = 'bank',
  DateTime? createdAt,
  String description = '',
  String ocrText = '',
  List<String> filePaths = const [],
  bool isExpirable = false,
  DateTime? expiryDate,
}) => DocumentItem(
  id: id,
  title: title,
  category: category,
  categoryId: categoryId,
  iconKey: 'file',
  createdAt: createdAt ?? DateTime(2025, 1, 1),
  description: description,
  ocrText: ocrText,
  filePaths: filePaths,
  isExpirable: isExpirable,
  expiryDate: expiryDate,
);

void main() {
  late FakeDocuments documents;
  late SearchViewModel vm;

  setUp(() {
    documents = FakeDocuments();
    vm = SearchViewModel(
      categoryUseCases: CategoryUseCases(FakeCategories()),
      documentUseCases: DocumentUseCases(documents),
    );
  });

  test('a title match ranks above a match only found in the body text', () {
    documents.documents.addAll([
      _doc(id: 'body', title: 'Lease agreement', ocrText: 'rent is 1200'),
      _doc(id: 'title', title: 'Rent receipt'),
    ]);
    vm.updateQuery('rent');

    final results = vm.documentsFor(SearchViewModel.allCategoryTab);

    expect(results.map((r) => r.document.id), ['title', 'body']);
    expect(results[0].excerpt, isNull);
    expect(results[1].excerpt, contains('rent is 1200'));
  });

  test('excerpt is only attached to the body-match result', () {
    final ocrText = '${'A' * 80}account number 55512${'B' * 80}';
    documents.documents.add(
      _doc(id: 'a', title: 'Utility bill', ocrText: ocrText),
    );
    vm.updateQuery('account number');

    final match = vm.documentsFor(SearchViewModel.allCategoryTab).single;

    expect(match.excerpt, isNotNull);
    expect(match.excerpt, contains('account number 55512'));
    // Capped around the match rather than dumping the whole field.
    expect(match.excerpt!.length, lessThan(ocrText.length));
    expect(match.excerpt, startsWith('…'));
    expect(match.excerpt, endsWith('…'));
  });

  test('empty query returns every document with no excerpt', () {
    documents.documents.addAll([
      _doc(id: 'a', title: 'A'),
      _doc(id: 'b', title: 'B'),
    ]);

    final results = vm.documentsFor(SearchViewModel.allCategoryTab);

    expect(results.length, 2);
    expect(results.every((r) => r.excerpt == null), true);
  });

  test('file-type filter matches a document with any attachment of that type', () {
    documents.documents.addAll([
      _doc(id: 'img', title: 'Scan', filePaths: const ['/a/photo.jpg']),
      _doc(id: 'pdf', title: 'Statement', filePaths: const ['/a/doc.pdf']),
      _doc(id: 'none', title: 'Empty'),
    ]);

    vm.setFileTypeFilter(DocumentFileTypeFilter.images);
    expect(
      vm.documentsFor(SearchViewModel.allCategoryTab).map((r) => r.document.id),
      ['img'],
    );

    vm.setFileTypeFilter(DocumentFileTypeFilter.pdfs);
    expect(
      vm.documentsFor(SearchViewModel.allCategoryTab).map((r) => r.document.id),
      ['pdf'],
    );
  });

  test('expiry filter separates expiring-soon, expired, and untracked documents', () {
    final now = DateTime.now();
    documents.documents.addAll([
      _doc(
        id: 'soon',
        title: 'Passport',
        isExpirable: true,
        expiryDate: now.add(const Duration(days: 5)),
      ),
      _doc(
        id: 'expired',
        title: 'Warranty',
        isExpirable: true,
        expiryDate: now.subtract(const Duration(days: 5)),
      ),
      _doc(id: 'none', title: 'Receipt'),
    ]);

    vm.setExpiryFilter(DocumentExpiryFilter.expiringSoon);
    expect(
      vm.documentsFor(SearchViewModel.allCategoryTab).map((r) => r.document.id),
      ['soon'],
    );

    vm.setExpiryFilter(DocumentExpiryFilter.expired);
    expect(
      vm.documentsFor(SearchViewModel.allCategoryTab).map((r) => r.document.id),
      ['expired'],
    );

    vm.setExpiryFilter(DocumentExpiryFilter.noExpiry);
    expect(
      vm.documentsFor(SearchViewModel.allCategoryTab).map((r) => r.document.id),
      ['none'],
    );
  });

  test('date-range filter keeps only documents created inside the range', () {
    documents.documents.addAll([
      _doc(id: 'old', title: 'Old', createdAt: DateTime(2020, 1, 1)),
      _doc(id: 'in', title: 'In range', createdAt: DateTime(2024, 6, 15)),
      _doc(id: 'new', title: 'New', createdAt: DateTime(2026, 1, 1)),
    ]);

    vm.setDateRange(
      DateTimeRange(start: DateTime(2024, 1, 1), end: DateTime(2024, 12, 31)),
    );

    expect(
      vm.documentsFor(SearchViewModel.allCategoryTab).map((r) => r.document.id),
      ['in'],
    );
    expect(vm.hasActiveFilters, true);

    vm.clearFilters();
    expect(vm.hasActiveFilters, false);
    expect(vm.documentsFor(SearchViewModel.allCategoryTab).length, 3);
  });
}
