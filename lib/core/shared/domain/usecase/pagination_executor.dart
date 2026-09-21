import 'package:flutter/foundation.dart';

import '../../../networks/networks_exports.dart';
import '../../../utils/utils_exports.dart';
import '../result/result.dart';

/// A page-number/page-size fetch function — what a usecase/repository call
/// for a paginated list looks like. Returns [Result] like every other call
/// in this template, just returning a page of items instead of one object.
typedef PageFetcher<T> =
    Future<Result<List<T>>> Function({required int page, required int pageSize});

/// Mixin for list screens — the [UseCaseExecutor] equivalent for paginated
/// data. Composes alongside `UseCaseExecutor` on the same ViewModel (a
/// screen can have one paginated list plus other single-result calls); use
/// a second `with PaginationExecutor<OtherItem>` (as a separate class, see
/// below) if a screen genuinely needs two independent paginated lists.
///
/// Assumes page-number + page-size pagination — the common case. If your
/// API is cursor-based, adapt [PageFetcher] to take a cursor instead; the
/// rest of this mixin's bookkeeping still applies.
mixin PaginationExecutor<T> on ChangeNotifier {
  final List<T> _items = [];
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingFirstPage = false;
  bool _isLoadingMore = false;
  AppException? _paginationError;

  List<T> get items => List.unmodifiable(_items);
  bool get hasMore => _hasMore;
  bool get isLoadingFirstPage => _isLoadingFirstPage;
  bool get isLoadingMore => _isLoadingMore;
  AppException? get paginationError => _paginationError;

  /// Loads page 1, replacing any existing items. Call this on initial
  /// screen load and for pull-to-refresh.
  Future<void> refreshPage({
    required PageFetcher<T> fetchPage,
    int pageSize = 20,
    bool showError = false,
  }) async {
    _isLoadingFirstPage = true;
    _paginationError = null;
    notifyListeners();

    final result = await fetchPage(page: 1, pageSize: pageSize);

    result.fold(
      onFailure: (error) {
        _paginationError = error;
        _isLoadingFirstPage = false;
        notifyListeners();
        if (showError) AppToastsUtils.error(error.toString());
      },
      onSuccess: (page) {
        _items
          ..clear()
          ..addAll(page);
        _currentPage = 1;
        _hasMore = page.length >= pageSize;
        _isLoadingFirstPage = false;
        notifyListeners();
      },
    );
  }

  /// Loads the next page and appends it. No-ops if a load is already in
  /// flight or there's nothing more to fetch, so it's safe to call
  /// unconditionally from a scroll listener without extra guards.
  Future<void> loadNextPage({
    required PageFetcher<T> fetchPage,
    int pageSize = 20,
    bool showError = false,
  }) async {
    if (_isLoadingMore || _isLoadingFirstPage || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    final nextPage = _currentPage + 1;
    final result = await fetchPage(page: nextPage, pageSize: pageSize);

    result.fold(
      onFailure: (error) {
        _paginationError = error;
        _isLoadingMore = false;
        notifyListeners();
        if (showError) AppToastsUtils.error(error.toString());
      },
      onSuccess: (page) {
        _items.addAll(page);
        _currentPage = nextPage;
        _hasMore = page.length >= pageSize;
        _isLoadingMore = false;
        notifyListeners();
      },
    );
  }

  void resetPagination() {
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
    _isLoadingFirstPage = false;
    _isLoadingMore = false;
    _paginationError = null;
    notifyListeners();
  }
}
