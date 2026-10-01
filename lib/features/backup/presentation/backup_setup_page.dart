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
import '../domain/entities/sync_progress.dart';
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
  bool _syncing = false;

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
        if (mounted) setState(() => _loading = false);
      case Success(:final value):
        await storage.setValues(StorageKeys.backupSpaceId, value.id);
        // Preparing the backup only loads its state. Syncing is user-driven so
        // people can review the pending count and choose when to use data.
        if (mounted) {
          setState(() {
            _space = value;
            _loading = false;
          });
        }
    }
  }

  Future<void> _backUpNow() async {
    final token = SessionController.instance.userToken;
    final space = _space;
    if (token == null || space == null || !space.isDriveConnected || _syncing) {
      return;
    }

    setState(() => _syncing = true);
    try {
      await sl<AppDatabase>().queueExistingDocumentsForSync();
      await _runSync(token: token, spaceId: space.id);
      // Home keeps an in-memory document list. Reload it after a restore so
      // downloaded documents are visible without reopening the application.
      await sl<DocumentUseCases>().init();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _runSync({
    required String token,
    required String spaceId,
  }) async {
    try {
      await sl<DocumentSyncService>().sync(token: token, spaceId: spaceId);
    } catch (error) {
      debugPrint('Document sync failed: $error');
    }
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
      'Google Drive connected. Tap Back up now when you are ready.',
    );
  }

  void _goToProfile() => AppNavigator.goNamed(RouteNames.profile);

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _goToProfile();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Backup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Profile',
          onPressed: _goToProfile,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(context),
              heightBox(24),
              if (_space == null)
                _preparingBackupCard(context)
              else ...[
                _connectionCard(context),
                if (_space!.isDriveConnected) ...[
                  heightBox(16),
                  _SyncStatusCard(
                    onRetry: () {
                      final token = SessionController.instance.userToken;
                      if (token == null) return;
                      _runSync(token: token, spaceId: _space!.id);
                    },
                  ),
                ],
              ],
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
              if (_space != null) ...[
                heightBox(28),
                if (!_space!.isDriveConnected)
                  CustomButton(
                    text: 'Connect Google Drive',
                    isLoading: _loading,
                    onPressed: _loading ? null : _connect,
                  )
                else ...[
                  CustomButton(
                    text: 'Back up now',
                    icon: Icons.cloud_upload_outlined,
                    isLoading: _syncing,
                    onPressed: _syncing ? null : _backUpNow,
                  ),
                  heightBox(6),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => AppNavigator.goNamed(RouteNames.home),
                      icon: const Icon(Icons.home_outlined, size: 18),
                      label: const Text('Go to Home'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _preparingBackupCard(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: context.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.primary.withValues(alpha: .25)),
    ),
    child: Row(
      children: [
        _StatusIcon(
          color: context.primary,
          icon: Icons.cloud_sync_outlined,
          showRing: true,
        ),
        widthBox(14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preparing your backup…', style: context.titleMedium),
              heightBox(4),
              Text(
                'Checking your backup space and local documents',
                style: context.bodySmall.copyWith(color: context.textSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _hero(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.primary,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            widthBox(10),
            Expanded(
              child: Text(
                'Keep your documents protected',
                style: context.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        heightBox(8),
        Text(
          'Your device remains your primary workspace. Backup happens quietly when you are online.',
          style: context.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: .88),
            height: 1.35,
          ),
        ),
      ],
    ),
  );

  Widget _connectionCard(BuildContext context) =>
      ValueListenableBuilder<Set<String>>(
        valueListenable: sl<AppDatabase>().pendingDocumentIds,
        builder: (context, pendingIds, _) =>
            _connectionCardContent(context, pendingIds.length),
      );

  Widget _connectionCardContent(BuildContext context, int pendingCount) {
    final connected = _space!.isDriveConnected;
    final color = connected ? Colors.green : context.textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              connected ? Icons.check_circle_outline : Icons.cloud_off_outlined,
              color: color,
              size: 20,
            ),
          ),
          widthBox(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? 'Google Drive connected' : 'Backup not connected',
                  style: context.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                heightBox(2),
                Text(
                  connected
                      ? 'Ready to back up to ${_space!.name}'
                      : 'Connect Drive to protect your documents.',
                  style: context.labelSmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (pendingCount > 0) ...[
            widthBox(10),
            PendingBackupCountBadge(count: pendingCount),
          ],
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

typedef _SyncVisuals = ({
  IconData icon,
  Color color,
  String title,
  String subtitle,
});

/// Shows what `DocumentSyncService` is doing right now — uploading,
/// downloading, or done — instead of leaving the page on a bare spinner
/// while a backup sync runs in the background.
class _SyncStatusCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _SyncStatusCard({required this.onRetry});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<SyncProgress>(
    valueListenable: sl<DocumentSyncService>().progress,
    builder: (context, progress, _) {
      if (progress.stage == SyncStage.idle) return const SizedBox.shrink();
      final visuals = _visualsFor(context, progress);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: visuals.color.withValues(alpha: .25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusIcon(
                  color: visuals.color,
                  icon: visuals.icon,
                  showRing: progress.isActive,
                  ringValue: progress.fraction,
                ),
                widthBox(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(visuals.title, style: context.titleMedium),
                      heightBox(4),
                      Text(
                        visuals.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodySmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (progress.stage == SyncStage.documents &&
                    progress.fraction != null)
                  Text(
                    '${(progress.fraction! * 100).round()}%',
                    style: context.labelMedium.copyWith(
                      color: visuals.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            if (progress.isActive) ...[
              heightBox(14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.fraction,
                  minHeight: 6,
                  backgroundColor: visuals.color.withValues(alpha: .12),
                  valueColor: AlwaysStoppedAnimation(visuals.color),
                ),
              ),
            ],
            if (progress.stage == SyncStage.failed) ...[
              heightBox(10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );

  _SyncVisuals _visualsFor(
    BuildContext context,
    SyncProgress progress,
  ) => switch (progress.stage) {
    SyncStage.idle => (
      icon: Icons.sync,
      color: context.textSecondary,
      title: '',
      subtitle: '',
    ),
    SyncStage.preparing => (
      icon: Icons.sync,
      color: context.primary,
      title: 'Preparing backup…',
      subtitle: 'Getting your documents ready to sync',
    ),
    SyncStage.categories => (
      icon: Icons.folder_copy_outlined,
      color: context.primary,
      title: 'Syncing categories…',
      subtitle: 'Matching your categories with Drive',
    ),
    SyncStage.documents => (
      icon: progress.direction == SyncDirection.upload
          ? Icons.cloud_upload_outlined
          : Icons.cloud_download_outlined,
      color: context.primary,
      title: progress.total > 0
          ? '${progress.direction == SyncDirection.upload ? 'Uploading' : 'Downloading'} ${progress.current} of ${progress.total}'
          : '${progress.direction == SyncDirection.upload ? 'Uploading' : 'Downloading'} documents…',
      subtitle:
          progress.itemLabel ??
          (progress.direction == SyncDirection.upload
              ? 'Sending your documents to Drive'
              : 'Pulling documents from Drive'),
    ),
    SyncStage.completed => (
      icon: Icons.check_circle_outline,
      color: context.success,
      title: 'Backup up to date',
      subtitle: 'All your documents are synced with Drive',
    ),
    SyncStage.failed => (
      icon: Icons.error_outline,
      color: context.error,
      title: 'Sync ran into a problem',
      subtitle: "We'll retry automatically, or tap retry now",
    ),
  };
}

/// A small icon badge that doubles as a progress ring — indeterminate while
/// [ringValue] is null and active, filled to [ringValue] once it's known,
/// and a plain tinted badge once the sync is no longer active.
class _StatusIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool showRing;
  final double? ringValue;

  const _StatusIcon({
    required this.color,
    required this.icon,
    required this.showRing,
    this.ringValue,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 46,
    height: 46,
    child: Stack(
      alignment: Alignment.center,
      children: [
        if (showRing)
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              value: ringValue,
              strokeWidth: 2.6,
              backgroundColor: color.withValues(alpha: .15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          )
        else
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
          ),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ],
    ),
  );
}
