import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../../../core/di/di_exports.dart';
import '../../../core/local_storage/local_storage_exports.dart';
import '../../../core/services/services_exports.dart';
import '../../../core/shared/shared_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../domain/entities/backup_space.dart';
import '../domain/usecases/backup_usecases.dart';

class BackupSetupPage extends StatefulWidget {
  const BackupSetupPage({super.key});
  @override
  State<BackupSetupPage> createState() => _BackupSetupPageState();
}

class _BackupSetupPageState extends State<BackupSetupPage> {
  static const _appScheme = 'mantic-drive-auth';
  BackupSpace? _space;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final token = SessionController.instance.userToken;
    if (token == null) return;
    final saved = await storage.readValues(StorageKeys.backupSpaceId);
    setState(() => _loading = true);
    final result = await sl<PrepareBackupUsecase>()((
      token: token,
      savedSpaceId: saved,
    ));
    switch (result) {
      case Failure(:final error):
        AppToastsUtils.error(error.message);
      case Success(:final value):
        _space = value;
        await storage.setValues(StorageKeys.backupSpaceId, value.id);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _connect() async {
    final token = SessionController.instance.userToken;
    final space = _space;
    if (token == null || space == null) return;
    setState(() => _loading = true);
    try {
      final result = await sl<ConnectGoogleDriveUsecase>()((
        token: token,
        spaceId: space.id,
      ));
      switch (result) {
        case Failure(:final error):
          AppToastsUtils.error(error.message);
        case Success(:final value):
          final callbackUrl = await FlutterWebAuth2.authenticate(
            url: value,
            callbackUrlScheme: _appScheme,
          );
          await _handleDriveCallback(Uri.parse(callbackUrl));
      }
    } catch (error) {
      debugPrint('Google Drive authorization session failed: $error');
      AppToastsUtils.error('Google Drive authorization was not completed.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleDriveCallback(Uri uri) async {
    debugPrint(
      'Google Drive callback: scheme=${uri.scheme}, host=${uri.host}, '
      'path=${uri.path}, status=${uri.queryParameters['status']}',
    );
    if (uri.scheme != _appScheme ||
        (uri.host != 'storage-connected' && uri.path != '/storage-connected')) {
      return;
    }
    if (uri.queryParameters['status'] != 'success') {
      AppToastsUtils.error('Google Drive authorization was not completed.');
      return;
    }

    await _prepare();
    if (!mounted || _space?.isDriveConnected != true) return;
    await storage.setValues(StorageKeys.backupEnabled, 'true');
    AppToastsUtils.success(
      'Google Drive connected. Backup will run in the background.',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Set up backup')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.backup_outlined, size: 56, color: context.primary),
            heightBox(20),
            Text('Keep your documents safe', style: context.headlineSmall),
            heightBox(8),
            Text(
              'Your documents remain available offline. Google Drive will securely store file backups.',
              style: context.bodyMedium.copyWith(color: context.textSecondary),
            ),
            const Spacer(),
            if (_space == null)
              const Center(child: CircularProgressIndicator())
            else if (_space!.isDriveConnected)
              Text('Google Drive is connected to ${_space!.name}.')
            else
              CustomButton(
                text: 'Connect Google Drive',
                isLoading: _loading,
                onPressed: _loading ? null : _connect,
              ),
            heightBox(16),
          ],
        ),
      ),
    ),
  );
}
