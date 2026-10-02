import 'package:flutter/material.dart';
import '../../../routes/routes_exports.dart';
import 'bulk_import_flow_content.dart';

/// A thin page wrapper around [BulkImportFlowContent] -- kept only so
/// `RouteNames.bulkImport`/the `bulkImportReview` fallback resolve to
/// something sensible for a direct/malformed navigation. The real entry
/// points (first-login prompt, Profile's "Find more documents") use
/// [BulkImportPopup] instead.
class BulkImportIntroView extends StatelessWidget {
  const BulkImportIntroView({super.key});

  static void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Import documents'),
      leading: IconButton(
        onPressed: () => _leave(context),
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: BulkImportFlowContent(
              onFound: (vm) =>
                  context.pushNamed(RouteNames.bulkImportReview, extra: vm),
              onDismiss: () => _leave(context),
            ),
          ),
        ),
      ),
    ),
  );
}
