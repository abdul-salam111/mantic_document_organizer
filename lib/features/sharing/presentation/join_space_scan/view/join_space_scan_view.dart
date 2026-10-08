import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/services/services_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../../../routes/routes_exports.dart';

/// In-app QR scanner for joining a shared category (see
/// docs/space_sharing_ux_plan.txt §3.3) -- bypasses OS link-resolution
/// entirely by reading the QR payload directly and handing it to
/// [DeepLinkService], the same path a tapped link/notification uses.
class JoinSpaceScanView extends StatefulWidget {
  const JoinSpaceScanView({super.key});

  @override
  State<JoinSpaceScanView> createState() => _JoinSpaceScanViewState();
}

class _JoinSpaceScanViewState extends State<JoinSpaceScanView> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handledOne = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_handledOne) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    _handledOne = true;
    AppNavigator.pop();
    sl<DeepLinkService>().handleScannedLink(uri);
  }

  Future<void> _enterLinkManually() async {
    final controller = TextEditingController();
    final link = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter link manually',
              style: sheetContext.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            heightBox(16),
            CustomTextFormField(controller: controller, hintText: 'Paste the invite link'),
            heightBox(16),
            CustomButton(
              text: 'Join',
              onPressed: () => Navigator.of(sheetContext).pop(controller.text.trim()),
            ),
          ],
        ),
      ),
    );
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) {
      AppToastsUtils.error("That doesn't look like a valid link.");
      return;
    }
    if (!mounted) return;
    AppNavigator.pop();
    sl<DeepLinkService>().handleScannedLink(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Scan to join', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
            errorBuilder: (context, error) => _ScannerError(
              error: error,
              onOpenSettings: ph.openAppSettings,
              onBack: AppNavigator.pop,
            ),
          ),
          const _ScanTargetOverlay(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 36,
            child: Center(
              child: TextButton(
                onPressed: _enterLinkManually,
                child: const Text(
                  'Enter link manually',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanTargetOverlay extends StatelessWidget {
  const _ScanTargetOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  final MobileScannerException error;
  final Future<bool> Function() onOpenSettings;
  final VoidCallback onBack;

  const _ScannerError({
    required this.error,
    required this.onOpenSettings,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isPermissionDenied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.camera_slash, color: Colors.white, size: 40),
            heightBox(16),
            Text(
              isPermissionDenied
                  ? 'Camera access is needed to scan a QR code to join a shared category.'
                  : "Couldn't start the camera.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            heightBox(20),
            if (isPermissionDenied)
              CustomButton(text: 'Open Settings', onPressed: onOpenSettings),
            heightBox(8),
            TextButton(
              onPressed: onBack,
              child: const Text('Go back', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}
