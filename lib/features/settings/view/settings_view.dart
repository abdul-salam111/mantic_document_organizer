import 'package:flutter/material.dart';

import '../../../core/di/di_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../viewmodel/settings_viewmodel.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<SettingsViewModel>(),
      child: Scaffold(
        appBar: const CustomAppBar(title: 'Settings'),
        body: Padding(
          padding: .all(24),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text('Appearance', style: context.titleMedium),
              heightBox(12),
              Consumer<ThemeController>(
                builder: (context, themeController, _) {
                  return SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Auto'),
                        icon: Icon(Iconsax.autobrightness),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Iconsax.sun_1),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Iconsax.moon),
                      ),
                    ],
                    selected: {themeController.themeMode},
                    onSelectionChanged: (selection) =>
                        themeController.setTheme(selection.first),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
