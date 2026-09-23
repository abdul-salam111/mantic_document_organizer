import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/di/di_exports.dart';
import '../../../core/localization/localization_exports.dart';
import '../../../core/security/security_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
// Imports the viewmodel directly rather than navbar_exports.dart — the
// barrel re-exports NavbarView, which imports every tab feature
// (including this one), so importing it here would create an import cycle.
import '../../navbar/viewmodel/navbar_viewmodel.dart';
import '../viewmodel/settings_viewmodel.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  /// Language names are shown in their own language (not translated),
  /// so a user stuck in the wrong language can still find their own.
  static const _languages = [
    (locale: Locale('en'), label: 'English'),
    (locale: Locale('es'), label: 'Español'),
    (locale: Locale('fr'), label: 'Français'),
    (locale: Locale('ar'), label: 'العربية'),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<SettingsViewModel>(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: AppLocalizations.of(context).settings,
          onBackPressed: () => context.read<NavbarViewModel>().selectTab(0),
        ),
        body: ListView(
          padding: const .fromLTRB(16, 20, 16, 32),
          children: [
            _SectionHeader(AppLocalizations.of(context).appearance),
            heightBox(10),
            Consumer<ThemeController>(
              builder: (context, themeController, _) {
                return SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(AppLocalizations.of(context).themeAuto),
                      icon: const Icon(Iconsax.autobrightness),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(AppLocalizations.of(context).themeLight),
                      icon: const Icon(Iconsax.sun_1),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(AppLocalizations.of(context).themeDark),
                      icon: const Icon(Iconsax.moon),
                    ),
                  ],
                  selected: {themeController.themeMode},
                  onSelectionChanged: (selection) =>
                      themeController.setTheme(selection.first),
                );
              },
            ),

            heightBox(28),
            _SectionHeader(AppLocalizations.of(context).language),
            heightBox(10),
            Consumer<LocaleController>(
              builder: (context, localeController, _) {
                return Column(
                  children: [
                    for (final language in _languages) ...[
                      _LanguageTile(
                        label: language.label,
                        isSelected:
                            localeController.locale.languageCode ==
                            language.locale.languageCode,
                        onTap: () =>
                            localeController.setLocale(language.locale),
                      ),
                      if (language != _languages.last) heightBox(8),
                    ],
                  ],
                );
              },
            ),

            heightBox(28),
            _SectionHeader(AppLocalizations.of(context).categories),
            heightBox(10),
            _SettingsCard(
              children: [
                _SettingsRow(
                  icon: Iconsax.add_square,
                  label: AppLocalizations.of(context).addCategory,
                  onTap: () => AppToastsUtils.info(
                    AppLocalizations.of(
                      context,
                    ).comingSoonToast(AppLocalizations.of(context).addCategory),
                  ),
                ),
                _SettingsRow(
                  icon: Iconsax.category,
                  label: AppLocalizations.of(context).manageCategories,
                  onTap: () => AppToastsUtils.info(
                    AppLocalizations.of(context).comingSoonToast(
                      AppLocalizations.of(context).manageCategories,
                    ),
                  ),
                ),
              ],
            ),

            heightBox(28),
            _SectionHeader(AppLocalizations.of(context).security),
            heightBox(10),
            const _SettingsCard(children: [_SecurityToggleRow()]),

            heightBox(28),
            _SectionHeader(AppLocalizations.of(context).support),
            heightBox(10),
            _SettingsCard(
              children: [
                _SettingsRow(
                  icon: Iconsax.star,
                  label: AppLocalizations.of(context).rateApp,
                  onTap: () => AppToastsUtils.info(
                    AppLocalizations.of(
                      context,
                    ).comingSoonToast(AppLocalizations.of(context).rateApp),
                  ),
                ),
                _SettingsRow(
                  icon: Iconsax.share,
                  label: AppLocalizations.of(context).shareApp,
                  onTap: () => SharePlus.instance.share(
                    ShareParams(
                      text: AppLocalizations.of(context).shareAppMessage,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: context.labelSmall.copyWith(
          color: context.textSecondary,
          fontWeight: .bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Groups related [_SettingsRow]s into one rounded card with hairline
/// dividers between rows, matching a typical native settings-list look
/// (rather than a separate elevated card per item).
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: .circular(14),
        boxShadow: [
          BoxShadow(
            color: context.shadow,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                indent: 58,
                endIndent: 16,
                color: context.divider,
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const .symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: .center,
              decoration: BoxDecoration(
                color: context.primary.withValues(alpha: 0.1),
                borderRadius: .circular(9),
              ),
              child: Icon(icon, size: 18, color: context.primary),
            ),
            widthBox(12),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Text(
                    label,
                    style: context.bodyMedium.copyWith(
                      fontWeight: .w600,
                      color: context.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    heightBox(2),
                    Text(
                      subtitle!,
                      style: context.labelSmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            widthBox(8),
            trailing ??
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

/// The biometric-lock toggle. A confirmation biometric prompt is required
/// before the toggle actually turns on (so it can't silently claim to be
/// protecting the app when the device has no usable biometrics, or the
/// user didn't really mean to enable it).
class _SecurityToggleRow extends StatefulWidget {
  const _SecurityToggleRow();

  @override
  State<_SecurityToggleRow> createState() => _SecurityToggleRowState();
}

class _SecurityToggleRowState extends State<_SecurityToggleRow> {
  bool _isBusy = false;
  BiometricKind? _biometricKind;

  @override
  void initState() {
    super.initState();
    context.read<SecurityController>().primaryBiometricKind().then((kind) {
      if (mounted) setState(() => _biometricKind = kind);
    });
  }

  (IconData, String) _iconAndLabel(BiometricKind? kind, AppLocalizations l10n) {
    switch (kind) {
      case BiometricKind.faceId:
        return (Icons.face, l10n.faceIdUnlock);
      case BiometricKind.touchId:
      case BiometricKind.fingerprint:
        return (Iconsax.finger_scan, l10n.biometricUnlock);
      case BiometricKind.generic:
      case null:
        return (Iconsax.finger_scan, l10n.biometricUnlockGeneric);
    }
  }

  Future<void> _handleChanged(bool enable, SecurityController security) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    // Resolved up front — this widget may be unmounted by the time the
    // async biometric calls below return, and AppLocalizations.of(context)
    // isn't safe to call after an await without a fresh mounted check.
    final l10n = AppLocalizations.of(context);

    if (enable) {
      final isAvailable = await security.isBiometricAvailable();
      if (!isAvailable) {
        if (mounted) {
          AppToastsUtils.error(l10n.biometricUnavailable);
          setState(() => _isBusy = false);
        }
        return;
      }
      final didAuthenticate = await security.authenticate(
        l10n.biometricPromptReason,
      );
      if (!didAuthenticate) {
        if (mounted) {
          AppToastsUtils.error(l10n.biometricAuthFailed);
          setState(() => _isBusy = false);
        }
        return;
      }
    }

    await security.setBiometricLockEnabled(enable);
    if (mounted) setState(() => _isBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityController>(
      builder: (context, security, _) {
        final l10n = AppLocalizations.of(context);
        final (icon, label) = _iconAndLabel(_biometricKind, l10n);
        return _SettingsRow(
          icon: icon,
          label: label,
          subtitle: l10n.biometricUnlockSubtitle,
          trailing: _isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: security.isBiometricLockEnabled,
                  onChanged: (value) => _handleChanged(value, security),
                ),
        );
      },
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: .circular(12),
      onTap: onTap,
      child: Container(
        padding: const .symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: .circular(12),
          border: isSelected
              ? Border.all(color: context.primaryAccent, width: 1.5)
              : null,
          boxShadow: isSelected
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
            Expanded(
              child: Text(
                label,
                style: context.bodyMedium.copyWith(
                  fontWeight: isSelected ? .bold : .w500,
                  color: isSelected
                      ? context.primaryAccent
                      : context.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: context.primaryAccent, size: 20),
          ],
        ),
      ),
    );
  }
}
