import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mantic_doc_org/core/localization/localization_exports.dart';
import 'package:mantic_doc_org/core/theme/theme.dart';
import 'package:mantic_doc_org/features/navbar/views/widgets/main_bottom_navbar.dart';

void main() {
  testWidgets('the visible outer add-button ring is tappable', (tester) async {
    var addPresses = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          bottomNavigationBar: MainBottomNavbar(
            selectedIndex: 0,
            onTabSelected: (_) {},
            onAddPressed: () => addPresses++,
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byIcon(Iconsax.add));
    // 31px from the icon's center is inside the 68px hit circle and outside
    // the 60px purple visual disc.
    await tester.tapAt(Offset(center.dx + 31, center.dy));
    await tester.pump();

    expect(addPresses, 1);
  });
}
