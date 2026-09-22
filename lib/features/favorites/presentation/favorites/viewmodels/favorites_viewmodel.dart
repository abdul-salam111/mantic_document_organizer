import 'package:flutter/foundation.dart';

import '../../../../../core/shared/shared_exports.dart';
import '../../../domain/entities/favorites_entity.dart';
import '../../../domain/usecases/favorites_usecase.dart';

class FavoritesViewModel extends ChangeNotifier with UseCaseExecutor {
  final FavoritesUsecase _favoritesUsecase;

  FavoritesViewModel({required FavoritesUsecase favoritesUsecase})
    : _favoritesUsecase = favoritesUsecase;

  List<FavoritesEntity> _favorites = [];
  List<FavoritesEntity> get favorites => _favorites;

  Future<void> loadFavorites() async {
    await execute(
      call: () => _favoritesUsecase(NoParams()),
      onSuccess: (favorites) {
        _favorites = favorites;
        notifyListeners();
      },
    );
  }
}
