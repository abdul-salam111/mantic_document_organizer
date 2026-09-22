import 'package:flutter/material.dart';

import '../../../core/di/di_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../viewmodel/home_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<HomeViewModel>(),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: .symmetric(horizontal: 10, vertical: 20),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  children: [
                    const AppLogo(
                      height: 36,
                      width: 36,
                    ).withRoundedCorners(10),
                    widthBox(10),
                    Text(
                      'Mantic',
                      style: context.titleMedium.copyWith(
                        color: context.primary,
                        fontWeight: .bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Profile',
                      style: IconButton.styleFrom(
                        backgroundColor: context.surface,
                        fixedSize: const Size(36, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: .circular(10),
                        ),
                      ),
                      icon: Icon(
                        Iconsax.profile_circle,
                        color: context.textPrimary,
                        size: 20,
                      ),
                      onPressed: () =>
                          AppToastsUtils.info('Profile — coming soon'),
                    ),
                  ],
                ),
                heightBox(20),
                const CustomSearchField(hintText: 'Search documents'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
