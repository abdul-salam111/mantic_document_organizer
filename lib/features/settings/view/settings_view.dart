import 'package:flutter/material.dart';

import '../../../core/di/di_exports.dart';
import '../../../core/localization/localization_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
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
        appBar: CustomAppBar(title: AppLocalizations.of(context).settings),
        body: ListView(
          padding: const .all(24),
          children: [
            Text(
              AppLocalizations.of(context).appearance,
              style: context.titleMedium,
            ),
            heightBox(12),
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
            Text(
              AppLocalizations.of(context).language,
              style: context.titleMedium,
            ),
            heightBox(12),
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
          ],
        ),
      ),
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
