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
                  heightBox(16),
                  _StatsRow(vm: vm),
                  heightBox(24),
                  _ProfileMenuTile(
                    icon: Iconsax.setting_2,
                    iconColor: context.primary,
                    label: AppLocalizations.of(context).settings,
                    subtitle: AppLocalizations.of(context).settingsSubtitle,
                    onTap: () => AppNavigator.pushNamed(RouteNames.settings),
                  ),
                  heightBox(10),
                  _ProfileMenuTile(
                    icon: Iconsax.trash,
                    iconColor: context.warning,
                    label: AppLocalizations.of(context).trash,
                    subtitle: AppLocalizations.of(context).trashSubtitle,
                    onTap: () => AppToastsUtils.info(
                      AppLocalizations.of(
                        context,
                      ).comingSoonToast(AppLocalizations.of(context).trash),
                    ),
                  ),
                  if (vm.isSignedIn) ...[
                    heightBox(20),
                    Divider(color: context.divider, height: 1),
                    heightBox(20),
                    _ProfileMenuTile(
                      icon: Iconsax.logout,
                      iconColor: context.errorAccent,
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

  String? get _initials {
    final name = vm.userName?.trim();
    if (name == null || name.isEmpty) return null;
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = [
      for (final part in parts.take(2)) part[0].toUpperCase(),
    ].join();
    return letters.isEmpty ? null : letters;
  }

  @override
  Widget build(BuildContext context) {
    final initials = vm.isSignedIn ? _initials : null;

    return Container(
      width: double.infinity,
      padding: const .fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: .topLeft,
          end: .bottomRight,
          colors: [context.primaryDark, context.primary, context.primaryLight],
        ),
        borderRadius: .circular(18),
        boxShadow: [
          BoxShadow(
            color: context.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: .center,
            decoration: BoxDecoration(
              shape: .circle,
              color: context.white.withValues(alpha: 0.15),
              border: Border.all(
                color: context.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: initials != null
                ? Text(
                    initials,
                    style: context.titleLarge.copyWith(
                      color: context.white,
                      fontWeight: .bold,
                    ),
                  )
                : Icon(Iconsax.user, size: 32, color: context.white),
          ),
          heightBox(14),
          Text(
            vm.isSignedIn
                ? (vm.userName ?? AppLocalizations.of(context).account)
                : AppLocalizations.of(context).guest,
            style: context.titleMedium.copyWith(
              color: context.white,
              fontWeight: .bold,
            ),
          ),
          heightBox(6),
          if (vm.isSignedIn)
            Text(
              vm.userEmail ?? '',
              textAlign: .center,
              style: context.labelSmall.copyWith(
                color: context.white.withValues(alpha: 0.85),
              ),
            )
          else
            Row(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Padding(
                  padding: const .only(top: 2),
                  child: Icon(
                    Iconsax.security_safe,
                    size: 12,
                    color: context.white.withValues(alpha: 0.85),
                  ),
                ),
                widthBox(6),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context).localOnlyStatus,
                    textAlign: .center,
                    style: context.labelSmall.copyWith(
                      color: context.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
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

class _StatsRow extends StatelessWidget {
  final ProfileViewModel vm;

  const _StatsRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: .circular(16),
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
          Expanded(
            child: _StatItem(
              icon: Iconsax.document_text,
              value: vm.documentCount,
              label: AppLocalizations.of(context).statDocuments,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Iconsax.category,
              value: vm.categoryCount,
              label: AppLocalizations.of(context).statCategories,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Iconsax.heart,
              value: vm.favoriteCount,
              label: AppLocalizations.of(context).statFavorites,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: context.primary),
        heightBox(6),
        Text('$value', style: context.titleMedium.copyWith(fontWeight: .bold)),
        heightBox(2),
        Text(
          label,
          style: context.labelSmall.copyWith(color: context.textSecondary),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: context.divider);
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileMenuTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDestructive
        ? context.errorAccent
        : context.textPrimary;
    return InkWell(
      borderRadius: .circular(12),
      onTap: onTap,
      child: Container(
        padding: const .symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: .circular(12),
          boxShadow: isDestructive
              ? null
              : [
                  BoxShadow(
                    color: context.shadow,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: .center,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: .circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            widthBox(14),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    label,
                    style: context.bodyMedium.copyWith(
                      fontWeight: .w600,
                      color: labelColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    heightBox(2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: context.labelSmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ],
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
