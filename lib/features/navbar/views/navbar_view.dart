import 'package:flutter/material.dart';

import '../../../core/di/di_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../../../routes/routes_exports.dart';
import '../../favorites/favorites_exports.dart';
import '../../home/home_exports.dart';
import '../../profile/profile_exports.dart';
import '../../search/search_exports.dart';
import '../viewmodel/navbar_viewmodel.dart';
import 'widgets/main_bottom_navbar.dart';

class NavbarView extends StatelessWidget {
  const NavbarView({super.key});

  static const List<Widget> _tabs = [
    HomeView(),
    SearchView(),
    FavoritesView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<NavbarViewModel>(),
      child: Consumer<NavbarViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            body: IndexedStack(index: vm.selectedIndex, children: _tabs),
            bottomNavigationBar: MainBottomNavbar(
              selectedIndex: vm.selectedIndex,
              onTabSelected: vm.selectTab,
              onAddPressed: () =>
                  AppNavigator.pushNamed(RouteNames.addDocument),
            ),
          );
        },
      ),
    );
  }
}
