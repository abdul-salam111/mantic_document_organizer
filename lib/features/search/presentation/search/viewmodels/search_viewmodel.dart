import 'package:flutter/foundation.dart';

import '../../../../../core/shared/shared_exports.dart';
import '../../../data/models/request_models/search_params.dart';
import '../../../domain/entities/search_entity.dart';
import '../../../domain/usecases/search_usecase.dart';

class SearchViewModel extends ChangeNotifier with UseCaseExecutor {
  final SearchUsecase _searchUsecase;

  SearchViewModel({required SearchUsecase searchUsecase})
    : _searchUsecase = searchUsecase;

  List<SearchEntity> _results = [];
  List<SearchEntity> get results => _results;

  Future<void> search(String query) async {
    await execute(
      call: () => _searchUsecase(SearchParams(query: query)),
      onSuccess: (results) {
        _results = results;
        notifyListeners();
      },
    );
  }
}
