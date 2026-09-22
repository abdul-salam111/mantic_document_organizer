import 'package:flutter/material.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../viewmodels/add_document_viewmodel.dart';

class AddDocumentView extends StatelessWidget {
  const AddDocumentView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<AddDocumentViewModel>(),
      child: Scaffold(
        appBar: const CustomAppBar(title: 'Add Document'),
        body: const EmptyStateWidget(
          icon: Iconsax.document_upload,
          title: 'Add a document',
          subtitle: 'Coming soon',
        ),
      ),
    );
  }
}
