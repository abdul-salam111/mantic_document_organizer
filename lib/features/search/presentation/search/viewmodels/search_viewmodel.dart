import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../../core/shared/shared_exports.dart';
import '../../../data/models/request_models/search_params.dart';
import '../../../domain/entities/search_entity.dart';
import '../../../domain/usecases/search_usecase.dart';

/// Presentational-only for now, mirroring HomeViewModel's dummy
/// categories/recentFiles — no local DB exists yet (see CLAUDE.md's
/// "Known mismatches" section) to actually search across.
class SearchResultItem {
  final String name;
  final String category;
  final FaIconData icon;

  const SearchResultItem({
    required this.name,
    required this.category,
    required this.icon,
  });
}

class SearchViewModel extends ChangeNotifier with UseCaseExecutor {
  final SearchUsecase _searchUsecase;

  SearchViewModel({required SearchUsecase searchUsecase})
    : _searchUsecase = searchUsecase;

  List<SearchEntity> _results = [];
  List<SearchEntity> get results => _results;

  /// Hits the REST search endpoint via [_searchUsecase] — kept for when a
  /// real backend/local DB exists. Unused by SearchView today; see
  /// [updateQuery]/[localResults] below for what actually powers the UI.
  Future<void> search(String query) async {
    await execute(
      call: () => _searchUsecase(SearchParams(query: query)),
      onSuccess: (results) {
        _results = results;
        notifyListeners();
      },
    );
  }

  String _query = '';
  String get query => _query;

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  static const String allCategoryTab = 'All';

  /// [allCategoryTab] first, then every distinct document category,
  /// alphabetically — mirrors HomeViewModel's category set so "All Docs"
  /// browses the same categories Home's grid shows.
  List<String> get categoryTabs {
    final distinct = _dummyDocuments.map((d) => d.category).toSet().toList()
      ..sort();
    return [allCategoryTab, ...distinct];
  }

  /// Documents in [category] (or every document, for [allCategoryTab]),
  /// further narrowed by the current search [query] if one's been typed.
  List<SearchResultItem> documentsFor(String category) {
    final q = _query.trim().toLowerCase();
    return _dummyDocuments.where((d) {
      final matchesCategory =
          category == allCategoryTab || d.category == category;
      final matchesQuery =
          q.isEmpty ||
          d.name.toLowerCase().contains(q) ||
          d.category.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  static const List<SearchResultItem> _dummyDocuments = [
    SearchResultItem(
      name: 'Electricity Bill - Sept',
      category: 'Electricity/Gas',
      icon: FontAwesomeIcons.boltLightning,
    ),
    SearchResultItem(
      name: 'Passport Scan',
      category: 'Passports',
      icon: FontAwesomeIcons.passport,
    ),
    SearchResultItem(
      name: 'Insurance Policy',
      category: 'Insurance',
      icon: FontAwesomeIcons.shieldHalved,
    ),
    SearchResultItem(
      name: 'Bank Statement',
      category: 'Bank',
      icon: FontAwesomeIcons.buildingColumns,
    ),
    SearchResultItem(
      name: 'Lease Agreement',
      category: 'Contracts',
      icon: FontAwesomeIcons.fileContract,
    ),
    SearchResultItem(
      name: 'Lab Report',
      category: 'Medical',
      icon: FontAwesomeIcons.stethoscope,
    ),
    SearchResultItem(
      name: 'Driving License',
      category: 'Driving License',
      icon: FontAwesomeIcons.idCardClip,
    ),
    SearchResultItem(
      name: 'National ID Card',
      category: 'ID Card',
      icon: FontAwesomeIcons.idCard,
    ),
    SearchResultItem(
      name: 'Concert Ticket',
      category: 'Tickets',
      icon: FontAwesomeIcons.ticket,
    ),
    SearchResultItem(
      name: 'University Degree',
      category: 'Education',
      icon: FontAwesomeIcons.graduationCap,
    ),
    SearchResultItem(
      name: 'Warranty Card - Laptop',
      category: 'Products',
      icon: FontAwesomeIcons.boxesStacked,
    ),
    SearchResultItem(
      name: 'Annual Tax Return',
      category: 'Tax Documents',
      icon: FontAwesomeIcons.fileInvoiceDollar,
    ),
    SearchResultItem(
      name: 'Personal Business Card',
      category: 'Business Card',
      icon: FontAwesomeIcons.addressCard,
    ),
    SearchResultItem(
      name: 'Freelance Invoice - Aug',
      category: 'Invoices',
      icon: FontAwesomeIcons.fileInvoice,
    ),
  ];
}
