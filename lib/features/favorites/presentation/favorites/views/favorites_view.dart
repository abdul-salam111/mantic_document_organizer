import 'package:flutter/material.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../viewmodels/favorites_viewmodel.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<FavoritesViewModel>(),
      child: Scaffold(
        appBar: const CustomAppBar(title: 'Favorites'),
        body: const EmptyStateWidget(
          icon: Iconsax.heart,
          title: 'Favorites',
          subtitle: 'Coming soon',
        ),
      ),
    );
  }
}
