import 'package:flutter/material.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../viewmodels/search_viewmodel.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<SearchViewModel>(),
      child: Scaffold(
        appBar: const CustomAppBar(title: 'Search'),
        body: const EmptyStateWidget(
          icon: Iconsax.search_normal,
          title: 'Search',
          subtitle: 'Coming soon',
        ),
      ),
    );
  }
}
