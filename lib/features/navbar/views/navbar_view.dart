import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/di/di_exports.dart';
import '../../../core/constants/constants_exports.dart';
import '../../../core/local_storage/local_storage_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../../../routes/routes_exports.dart';
import '../../bulk_import/bulk_import_exports.dart';
import '../../favorites/favorites_exports.dart';
import '../../home/home_exports.dart';
import '../../profile/profile_exports.dart';
import '../../search/search_exports.dart';
import '../viewmodel/navbar_viewmodel.dart';
import 'widgets/main_bottom_navbar.dart';

class NavbarView extends StatefulWidget {
  final int initialIndex;

  const NavbarView({super.key, this.initialIndex = 0});

  @override
  State<NavbarView> createState() => _NavbarViewState();
}

class _NavbarViewState extends State<NavbarView> {
  static const List<Widget> _tabs = [
    HomeView(),
    SearchView(),
    FavoritesView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    // Home is reached only once signup/login is complete, so this is the
    // one place "first time the user is actually in the app" can be
    // checked, regardless of which auth path got them here.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowBulkImportPrompt(),
    );
  }

  Future<void> _maybeShowBulkImportPrompt() async {
    if (!AppConstants.autoImportEnabled || !mounted) return;
    final hasSeenImport = await storage.readValues(
      StorageKeys.hasSeenBulkImportPrompt,
    );
    if (hasSeenImport == 'true' || !mounted) return;
    unawaited(AutoImportConsentSheet.show(context));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<NavbarViewModel>()..selectTab(widget.initialIndex),
      child: Consumer<NavbarViewModel>(
        builder: (context, vm, _) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (vm.handleBackPressed()) {
                SystemNavigator.pop();
              }
            },
            child: Scaffold(
              // IndexedStack keeps every tab mounted (just not painted) so
              // switching tabs doesn't lose their scroll position/state —
              // but that also means a document shown on more than one tab
              // at once (e.g. Home's Recent Files and the Favorites tab)
              // would register its cover's Hero tag twice in the same
              // route. HeroMode(enabled: false) opts an offstage tab's
              // Heroes out of that registration entirely, so only the
              // actually-visible tab's cover can ever be a flight
              // candidate.
              body: IndexedStack(
                index: vm.selectedIndex,
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    HeroMode(enabled: vm.selectedIndex == i, child: _tabs[i]),
                ],
              ),
              bottomNavigationBar: MainBottomNavbar(
                selectedIndex: vm.selectedIndex,
                onTabSelected: vm.selectTab,
                onAddPressed: () =>
                    AppNavigator.pushNamed(RouteNames.addDocument),
              ),
            ),
          );
        },
      ),
    );
  }
}
