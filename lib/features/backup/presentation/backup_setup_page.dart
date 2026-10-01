import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../../../core/database/database_exports.dart';
import '../../../core/di/di_exports.dart';
import '../../../core/local_storage/local_storage_exports.dart';
import '../../../core/services/services_exports.dart';
import '../../../routes/routes_exports.dart';
import '../../../core/shared/shared_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../../documents/domain/usecases/document_usecases.dart';
import '../domain/entities/backup_space.dart';
import '../domain/usecases/backup_usecases.dart';
import '../data/services/document_sync_service.dart';

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
        if (value.isDriveConnected) {
          await sl<AppDatabase>().queueExistingDocumentsForSync();
          await sl<DocumentSyncService>().sync(token: token, spaceId: value.id);
          // Home keeps an in-memory document list. Reload it after restore so
          // the documents pulled into SQLite are visible immediately.
          await sl<DocumentUseCases>().init();
        }
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
    // Fire-and-forget: the durable outbox retains failures for the next run.
    final token = SessionController.instance.userToken;
    if (token != null) {
      await sl<DocumentSyncService>().sync(token: token, spaceId: _space!.id);
    }
    AppToastsUtils.success(
      'Google Drive connected. Backup will run in the background.',
    );
    // This is the end of the account-and-backup onboarding flow. Replacing
    // the route prevents Back from returning to sign-in or closing the app.
    if (mounted) AppNavigator.goNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Backup'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Go to Home',
        onPressed: () => AppNavigator.goNamed(RouteNames.home),
      ),
    ),
    body: SafeArea(
      child: _space == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hero(context),
                  heightBox(24),
                  _connectionCard(context),
                  heightBox(24),
                  Text('How your backup works', style: context.titleMedium),
                  heightBox(12),
                  _benefit(
                    context,
                    Icons.phone_android_outlined,
                    'Always available offline',
                    'Your documents stay on this device first.',
                  ),
                  _benefit(
                    context,
                    Icons.cloud_outlined,
                    'Protected in Drive',
                    'A secure copy is kept in your connected Google Drive.',
                  ),
                  _benefit(
                    context,
                    Icons.sync_outlined,
                    'Syncs when online',
                    'Changes wait safely until an internet connection is available.',
                  ),
                  heightBox(28),
                  if (!_space!.isDriveConnected)
                    CustomButton(
                      text: 'Connect Google Drive',
                      isLoading: _loading,
                      onPressed: _loading ? null : _connect,
                    )
                  else
                    CustomButton(
                      text: 'Go to Home',
                      icon: Icons.home_outlined,
                      onPressed: () => AppNavigator.goNamed(RouteNames.home),
                    ),
                ],
              ),
            ),
    ),
  );

  Widget _hero(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: context.primary,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .18),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        heightBox(20),
        Text(
          'Keep your documents protected',
          style: context.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        heightBox(8),
        Text(
          'Your device remains your primary workspace. Backup happens quietly when you are online.',
          style: context.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: .88),
            height: 1.45,
          ),
        ),
      ],
    ),
  );

  Widget _connectionCard(BuildContext context) {
    final connected = _space!.isDriveConnected;
    final color = connected ? Colors.green : context.textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              connected ? Icons.check_circle_outline : Icons.cloud_off_outlined,
              color: color,
            ),
          ),
          widthBox(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? 'Google Drive connected' : 'Backup not connected',
                  style: context.titleMedium,
                ),
                heightBox(4),
                Text(
                  connected
                      ? 'Syncing with ${_space!.name}'
                      : 'Connect Drive to protect your documents.',
                  style: context.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefit(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.primary, size: 22),
        widthBox(14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.titleSmall),
              heightBox(3),
              Text(
                subtitle,
                style: context.bodySmall.copyWith(color: context.textSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
