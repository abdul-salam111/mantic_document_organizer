import 'package:flutter/material.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../viewmodels/{{fileName}}_viewmodel.dart';

class {{className}}Page extends StatefulWidget {
  const {{className}}Page({super.key});

  @override
  State<{{className}}Page> createState() => _{{className}}PageState();
}

class _{{className}}PageState extends State<{{className}}Page> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<{{className}}ViewModel>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('{{className}}'),
        ),
        body: Consumer<{{className}}ViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '{{className}} Page',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: viewModel.isLoading
                        ? null
                        : () => viewModel.performAction(),
                    child: const Text('Perform Action'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
