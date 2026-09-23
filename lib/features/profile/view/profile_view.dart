import 'package:flutter/material.dart';

import '../../../core/di/di_exports.dart';
import '../../../core/localization/localization_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../../../routes/routes_exports.dart';
import '../viewmodel/profile_viewmodel.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<ProfileViewModel>(),
      child: Scaffold(
        appBar: CustomAppBar(title: AppLocalizations.of(context).profileTitle),
        body: SafeArea(
          child: Consumer<ProfileViewModel>(
            builder: (context, vm, _) {
              return ListView(
                padding: const .all(16),
                children: [
                  _ProfileHeaderCard(vm: vm),
                  heightBox(24),
                  _ProfileMenuTile(
                    icon: Iconsax.setting_2,
                    label: AppLocalizations.of(context).settings,
                    onTap: () => AppNavigator.pushNamed(RouteNames.settings),
                  ),
                  heightBox(10),
                  _ProfileMenuTile(
                    icon: Iconsax.trash,
                    label: AppLocalizations.of(context).trash,
                    onTap: () => AppToastsUtils.info(
                      AppLocalizations.of(
                        context,
                      ).comingSoonToast(AppLocalizations.of(context).trash),
                    ),
                  ),
                  if (vm.isSignedIn) ...[
                    heightBox(10),
                    _ProfileMenuTile(
                      icon: Iconsax.logout,
                      label: AppLocalizations.of(context).signOut,
                      isDestructive: true,
                      onTap: vm.signOut,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final ProfileViewModel vm;

  const _ProfileHeaderCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const .all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: .topLeft,
          end: .bottomRight,
          colors: [context.primaryDark, context.primary, context.primaryLight],
        ),
        borderRadius: .circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: .center,
            decoration: BoxDecoration(
              shape: .circle,
              color: context.white.withValues(alpha: 0.15),
            ),
            child: Icon(Iconsax.user, size: 30, color: context.white),
          ),
          heightBox(12),
          Text(
            vm.isSignedIn
                ? (vm.userName ?? AppLocalizations.of(context).account)
                : AppLocalizations.of(context).guest,
            style: context.titleMedium.copyWith(
              color: context.white,
              fontWeight: .bold,
            ),
          ),
          heightBox(4),
          Text(
            vm.isSignedIn
                ? (vm.userEmail ?? '')
                : AppLocalizations.of(context).localOnlyStatus,
            textAlign: .center,
            style: context.labelSmall.copyWith(
              color: context.white.withValues(alpha: 0.85),
            ),
          ),
          if (!vm.isSignedIn) ...[
            heightBox(16),
            CustomButton(
              text: AppLocalizations.of(context).setUpBackup,
              backgroundColor: context.white,
              textColor: context.primary,
              radius: 12,
              onPressed: () => AppNavigator.pushNamed(RouteNames.signin),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? context.errorAccent : context.textPrimary;
    return InkWell(
      borderRadius: .circular(12),
      onTap: onTap,
      child: Container(
        padding: const .symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: .circular(12),
          boxShadow: [
            BoxShadow(
              color: context.shadow,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            widthBox(14),
            Expanded(
              child: Text(
                label,
                style: context.bodyMedium.copyWith(
                  fontWeight: .w600,
                  color: color,
                ),
              ),
            ),
            if (!isDestructive)
              Icon(
                Iconsax.arrow_right_3,
                size: 16,
                color: context.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
