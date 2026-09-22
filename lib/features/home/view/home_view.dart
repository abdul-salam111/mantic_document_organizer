import 'package:flutter/material.dart';

import '../../../core/di/di_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../viewmodel/home_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<HomeViewModel>(),
      child: Scaffold(
        appBar: const CustomAppBar(title: 'Home'),
        body: Consumer<HomeViewModel>(
          builder: (context, vm, _) {
            return Center(
              child: Padding(
                padding: .all(24),
                child: Text(
                  'Welcome, ${vm.userName}!',
                  textAlign: .center,
                  style: context.headlineSmall,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
