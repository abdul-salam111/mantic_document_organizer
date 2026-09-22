import 'package:flutter/material.dart';

import '../../../core/di/di_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../viewmodel/profile_viewmodel.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<ProfileViewModel>(),
      child: Scaffold(
        appBar: const CustomAppBar(title: 'Profile'),
        body: const EmptyStateWidget(
          icon: Iconsax.profile_circle,
          title: 'Profile',
          subtitle: 'Coming soon',
        ),
      ),
    );
  }
}
