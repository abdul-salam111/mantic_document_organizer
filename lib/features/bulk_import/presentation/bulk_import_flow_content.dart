import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/di/di_exports.dart';
import '../../../core/local_storage/local_storage_exports.dart';
import 'viewmodel/bulk_import_viewmodel.dart';

/// The actual "find my documents" prompt/progress/error UI, with no
/// opinion on what contains it -- [BulkImportPopup] shows it in a compact
/// [Dialog]; [BulkImportIntroView] wraps it in a full-page [Scaffold] as a
/// defensive fallback for direct navigation. Both call sites get the same
/// state machine and the same, deliberately short, copy.
class BulkImportFlowContent extends StatefulWidget {
  /// Called once discovery finds something to review. The caller decides
  /// what "showing the review screen" means for its container (e.g. pop a
  /// dialog first, or just push on top of a page).
  final void Function(BulkImportViewModel vm) onFound;

  /// Called when the user explicitly backs out (Not now / Skip) rather
  /// than completing the flow.
  final VoidCallback onDismiss;

  const BulkImportFlowContent({
    super.key,
    required this.onFound,
    required this.onDismiss,
  });

  @override
  State<BulkImportFlowContent> createState() => _BulkImportFlowContentState();
}

class _BulkImportFlowContentState extends State<BulkImportFlowContent> {
  bool _scanning = false;
  bool _permissionDenied = false;
  bool _offline = false;
  String? _error;
  BulkImportViewModel? _pending;

  @override
  void initState() {
    super.initState();
    // Seeing this prompt counts as shown, including backdrop/back dismissal.
    unawaited(_markSeen());
  }

  Future<void> _markSeen() async {
    try {
      await storage.setValues(StorageKeys.hasSeenBulkImportPrompt, 'true');
    } catch (_) {
      /* The persistent Profile entry remains available. */
    }
  }

  @override
  void dispose() {
    _pending?.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final vm = sl<BulkImportViewModel>();
    setState(() {
      _scanning = true;
      _permissionDenied = false;
      _offline = false;
      _error = null;
      _pending = vm;
    });
    final found = await vm.discover();
    if (!mounted) return; // dispose owns the pending session.
    if (vm.offline) {
      setState(() {
        _scanning = false;
        _offline = true;
      });
      return;
    }
    if (vm.permissionDenied) {
      // Kept alive (not disposed) so "Open Settings" below can still use
      // it; this widget's dispose() owns cleanup when the user leaves.
      setState(() {
        _scanning = false;
        _permissionDenied = true;
      });
      return;
    }
    if (!found) {
      _pending = null;
      setState(() {
        _scanning = false;
        _error = vm.notice;
      });
      vm.dispose();
      return;
    }
    _pending = null;
    widget.onFound(vm);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.travel_explore_outlined,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Find your documents',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(_descriptionFor(), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        if (_scanning && _pending != null) _ScanStatus(viewModel: _pending!),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        if (_offline)
          _ActionRow(
            primaryIcon: Icons.refresh,
            primaryLabel: 'Retry',
            onPrimary: _find,
            onDismiss: widget.onDismiss,
          )
        else if (_permissionDenied)
          _ActionRow(
            primaryIcon: Icons.settings_outlined,
            primaryLabel: 'Open Settings',
            onPrimary: () => _pending?.openPermissionSettings(),
            onDismiss: widget.onDismiss,
          )
        else
          _ActionRow(
            primaryIcon: Icons.travel_explore_outlined,
            primaryLabel: 'Find my documents',
            onPrimary: _scanning ? null : _find,
            dismissLabel: 'Not now',
            onDismiss: widget.onDismiss,
          ),
      ],
    );
  }

  String _descriptionFor() {
    if (_offline) {
      return "You're offline. Connect to the internet to find your "
          'documents automatically.';
    }
    if (_permissionDenied) {
      return 'Docketly needs photo access to find your documents.';
    }
    return 'Docketly scans your photos with AI to find and organize IDs, '
        'receipts, invoices, and bills for you. Requires internet.';
  }
}

class _ActionRow extends StatelessWidget {
  final IconData primaryIcon;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String dismissLabel;
  final VoidCallback onDismiss;

  const _ActionRow({
    required this.primaryIcon,
    required this.primaryLabel,
    required this.onPrimary,
    this.dismissLabel = 'Not now',
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton.icon(
        onPressed: onPrimary,
        icon: Icon(primaryIcon),
        label: Text(primaryLabel),
      ),
      const SizedBox(height: 8),
      TextButton(onPressed: onDismiss, child: Text(dismissLabel)),
    ],
  );
}

class _ScanStatus extends StatelessWidget {
  final BulkImportViewModel viewModel;
  const _ScanStatus({required this.viewModel});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: viewModel,
    builder: (context, _) {
      final examined = viewModel.scanExamined;
      final budget = BulkImportViewModel.maxExaminedPerScan;
      final started = examined > 0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: started ? examined / budget : null),
            const SizedBox(height: 8),
            Text(
              started
                  ? 'Scanning… $examined of $budget checked · ${viewModel.scanFound} found'
                  : 'Looking through your photos…',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    },
  );
}
