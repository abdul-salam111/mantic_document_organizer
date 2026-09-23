import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../../core/shared/shared_exports.dart';
import '../../../domain/entities/favorites_entity.dart';
import '../../../domain/usecases/favorites_usecase.dart';

/// Presentational-only for now, mirroring HomeViewModel/SearchViewModel's
/// dummy data — no local DB exists yet (see CLAUDE.md's "Known
/// mismatches" section) to actually persist favorited documents in.
class FavoriteItem {
  final String name;
  final String category;
  final FaIconData icon;

  const FavoriteItem({
    required this.name,
    required this.category,
    required this.icon,
  });
}

class FavoritesViewModel extends ChangeNotifier with UseCaseExecutor {
  final FavoritesUsecase _favoritesUsecase;

  FavoritesViewModel({required FavoritesUsecase favoritesUsecase})
    : _favoritesUsecase = favoritesUsecase;

  List<FavoritesEntity> _favorites = [];
  List<FavoritesEntity> get favorites => _favorites;

  /// Hits the REST favorites endpoint via [_favoritesUsecase] — kept for
  /// when a real backend/local DB exists. Unused by FavoritesView today;
  /// see [items]/[removeFavorite] below for what actually powers the UI.
  Future<void> loadFavorites() async {
    await execute(
      call: () => _favoritesUsecase(NoParams()),
      onSuccess: (favorites) {
        _favorites = favorites;
        notifyListeners();
      },
    );
  }

  final List<FavoriteItem> _items = [
    const FavoriteItem(
      name: 'Passport Scan',
      category: 'Passports',
      icon: FontAwesomeIcons.passport,
    ),
    const FavoriteItem(
      name: 'Insurance Policy',
      category: 'Insurance',
      icon: FontAwesomeIcons.shieldHalved,
    ),
    const FavoriteItem(
      name: 'Bank Statement',
      category: 'Bank',
      icon: FontAwesomeIcons.buildingColumns,
    ),
    const FavoriteItem(
      name: 'Lease Agreement',
      category: 'Contracts',
      icon: FontAwesomeIcons.fileContract,
    ),
    const FavoriteItem(
      name: 'National ID Card',
      category: 'ID Card',
      icon: FontAwesomeIcons.idCard,
    ),
  ];

  List<FavoriteItem> get items => List.unmodifiable(_items);

  void removeFavorite(FavoriteItem item) {
    _items.remove(item);
    notifyListeners();
  }
}
