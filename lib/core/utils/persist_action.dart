import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'apptoast_utils.dart';

/// Returns false on failure so callers keep the form/selection and skip success UI.
Future<bool> persistAction(
  BuildContext context,
  Future<void> Function() action, {
  String? errorMessage,
}) async {
  try {
    await action();
    return context.mounted;
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'document actions',
      ),
    );
    if (context.mounted) {
      AppToastsUtils.error(
        errorMessage ?? AppLocalizations.of(context).operationFailedToast,
      );
    }
    return false;
  }
}
