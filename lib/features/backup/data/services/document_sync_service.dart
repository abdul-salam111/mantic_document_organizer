import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/database/app_database.dart';
import '../../../categories/domain/entities/category_item.dart';
import '../../../documents/domain/entities/document_item.dart';
import '../../domain/entities/sync_progress.dart';

/// Sends durable local document mutations after backup setup. Local writes
/// always succeed first; failed HTTP work remains in SQLite for a later run.
class DocumentSyncService {
  DocumentSyncService(this._database, this._dio);

  final AppDatabase _database;
  final Dio _dio;
  bool _running = false;

  /// Live status of the current/last run, for the setup/profile UI to show
  /// a real progress bar instead of a bare spinner.
  final ValueNotifier<SyncProgress> progress = ValueNotifier(
    const SyncProgress.idle(),
  );

  /// [isPersonalSpace] scopes every step below to only the local categories
  /// that actually belong to this run -- the personal backup space only
  /// ever touches categories with no [CategoryItem.spaceId] (today's only
  /// case, unchanged), while a shared category's space only touches the one
  /// local category whose `spaceId` matches [spaceId]. Without this, a
  /// shared-space run would also push every other unsynced personal
  /// category/document into that family space (and vice versa) -- see
  /// docs/space_sharing_ux_plan.txt / the sharing technical plan's "sync
  /// engine generalization" step.
  ///
  /// [newCategoryRole] is only consulted when this run discovers a shared
  /// category it has no local copy of yet (e.g. a member syncing a space
  /// for the first time after joining) -- it becomes that new local
  /// category's [CategoryItem.myRole].
  Future<void> sync({
    required String token,
    required String spaceId,
    bool isPersonalSpace = true,
    String? newCategoryRole,
  }) async {
    if (_running) return;
    _running = true;
    progress.value = const SyncProgress(stage: SyncStage.preparing);
    try {
      final scopedCategoryIds = await _scopedLocalCategoryIds(
        spaceId: spaceId,
        isPersonalSpace: isPersonalSpace,
      );
      progress.value = const SyncProgress(stage: SyncStage.categories);
      await _syncCategories(
        token: token,
        spaceId: spaceId,
        isPersonalSpace: isPersonalSpace,
        newCategoryRole: newCategoryRole,
        scopedCategoryIds: scopedCategoryIds,
      );

      // A document can be removed directly from Neon (or by a recovery
      // operation) while its local copy and files still exist. Its old sync
      // state would otherwise make us PATCH a non-existent remote ID, or
      // skip attachments because they were previously uploaded. Resolve this
      // before processing the outbox: the active local document becomes a
      // new create/upload, while an intentional local delete remains a
      // delete operation and is never resurrected.
      await _requeueLocalDocumentsMissingFromRemote(
        token: token,
        spaceId: spaceId,
        scopedCategoryIds: scopedCategoryIds,
      );

      final pending = (await _database.pendingSyncOperations())
          .where((op) => scopedCategoryIds.contains(_categoryIdFromPayload(op)))
          .toList(growable: false);
      for (var i = 0; i < pending.length; i++) {
        final item = pending[i];
        final id = item['id'] as int;
        progress.value = SyncProgress(
          stage: SyncStage.documents,
          direction: SyncDirection.upload,
          current: i + 1,
          total: pending.length,
          itemLabel: _uploadLabel(item),
        );
        try {
          await _syncDocument(item, token: token, spaceId: spaceId);
          await _database.completeSyncOperation(id);
        } catch (_) {
          // Keep going: one stuck/failing item (e.g. a Drive-side folder
          // that no longer exists) must not block every other queued
          // document — including brand-new ones — from ever being
          // attempted, since this queue is processed oldest-first forever.
          await _database.recordSyncFailure(id);
        }
      }

      await _pullRemoteDocuments(token: token, spaceId: spaceId);
      progress.value = const SyncProgress(stage: SyncStage.completed);
    } catch (error) {
      progress.value = SyncProgress(
        stage: SyncStage.failed,
        errorMessage: error.toString(),
      );
      rethrow;
    } finally {
      _running = false;
    }
  }

  String? _uploadLabel(Map<String, Object?> operation) {
    if (operation['operation'] == 'delete') return 'Removing a document';
    try {
      final payload = jsonDecode(operation['payload'] as String) as Map;
      return payload['title'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Set<String>> _scopedLocalCategoryIds({
    required String spaceId,
    required bool isPersonalSpace,
  }) async {
    final categories = await _database.fetchCategories();
    if (isPersonalSpace) {
      return {
        uncategorizedCategoryId,
        ...categories
            .where((category) => category.spaceId == null)
            .map((category) => category.id),
      };
    }
    return categories
        .where((category) => category.spaceId == spaceId)
        .map((category) => category.id)
        .toSet();
  }

  String? _categoryIdFromPayload(Map<String, Object?> operation) {
    try {
      final payload = jsonDecode(operation['payload'] as String) as Map;
      return payload['category_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _syncCategories({
    required String token,
    required String spaceId,
    required bool isPersonalSpace,
    required String? newCategoryRole,
    required Set<String> scopedCategoryIds,
  }) async {
    final headers = Options(headers: {'Authorization': 'Bearer $token'});
    final remoteResponse = await _dio.get(
      '${ApiEndPoints.baseUrl}spaces/$spaceId/categories',
      options: headers,
    );
    final remoteCategories = List<Map<String, dynamic>>.from(
      (remoteResponse.data as List).map(
        (value) => Map<String, dynamic>.from(value as Map),
      ),
    );
    final remoteById = {
      for (final remote in remoteCategories) remote['id'] as String: remote,
    };
    final localCategories = await _database.fetchCategories();
    for (final remote in remoteCategories) {
      final remoteId = remote['id'] as String;
      var localId = await _database.localCategoryIdForRemoteId(remoteId);
      CategoryItem? localCategory;
      if (localId != null) {
        localCategory = localCategories
            .where((category) => category.id == localId)
            .firstOrNull;
      }
      localCategory ??= localCategories
          .where(
            (category) =>
                category.name == remote['name'] &&
                category.iconKey == (remote['icon_key'] as String? ?? ''),
          )
          .firstOrNull;
      if (localCategory == null) {
        localCategory = CategoryItem(
          id: remoteId,
          name: remote['name'] as String,
          iconKey: remote['icon_key'] as String? ?? 'folder',
          colorValue: _colorFromRemote(remote['color']),
          spaceId: isPersonalSpace ? null : spaceId,
          myRole: isPersonalSpace ? null : newCategoryRole,
        );
        await _database.upsertCategory(localCategory);
      }
      await _database.saveCategorySyncState(
        localId: localCategory.id,
        remoteId: remoteId,
      );
    }

    for (final category in await _database.fetchCategories()) {
      if (!scopedCategoryIds.contains(category.id) ||
          category.id == uncategorizedCategoryId ||
          await _database.remoteCategoryIdForLocalId(category.id) != null) {
        continue;
      }
      final response = await _dio.post(
        '${ApiEndPoints.baseUrl}spaces/$spaceId/categories',
        data: {
          'name': category.name,
          'icon_key': category.iconKey,
          'color': category.colorValue?.toRadixString(16),
        },
        options: headers,
      );
      final remote = Map<String, dynamic>.from(response.data as Map);
      await _database.saveCategorySyncState(
        localId: category.id,
        remoteId: remote['id'] as String,
      );
    }

    // Backfills built-in category colors created by older app versions and
    // keeps custom category edits consistent for every device in the space.
    // Only categories that actually differ from the server are sent — the
    // GET above already told us what the server has, so comparing against
    // `remoteById` instead of PATCHing unconditionally is what stops every
    // category being re-sent (and its revision bumped) on every sync.
    for (final category in await _database.fetchCategories()) {
      if (!scopedCategoryIds.contains(category.id) ||
          category.id == uncategorizedCategoryId) {
        continue;
      }
      final remoteId = await _database.remoteCategoryIdForLocalId(category.id);
      if (remoteId == null) continue;
      final remote = remoteById[remoteId];
      final matchesRemote =
          remote != null &&
          remote['name'] == category.name &&
          (remote['icon_key'] as String? ?? '') == category.iconKey &&
          _colorFromRemote(remote['color']) == category.colorValue;
      if (matchesRemote) continue;
      await _dio.patch(
        '${ApiEndPoints.baseUrl}spaces/$spaceId/categories/$remoteId',
        data: {
          'name': category.name,
          'icon_key': category.iconKey,
          'color': category.colorValue?.toRadixString(16),
        },
        options: headers,
      );
    }
  }

  int? _colorFromRemote(Object? value) {
    final hex = value as String?;
    return hex == null ? null : int.tryParse(hex, radix: 16);
  }

  Future<void> _requeueLocalDocumentsMissingFromRemote({
    required String token,
    required String spaceId,
    required Set<String> scopedCategoryIds,
  }) async {
    final response = await _dio.get(
      '${ApiEndPoints.baseUrl}spaces/$spaceId/documents',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final remoteIds = (response.data as List)
        .map((value) => (value as Map)['id'] as String)
        .toSet();

    for (final document in await _database.fetchDocuments()) {
      if (!scopedCategoryIds.contains(document.categoryId)) continue;
      final state = await _database.documentSyncState(document.id);
      if (state == null || remoteIds.contains(state['remote_document_id'])) {
        continue;
      }
      await _database.requeueDocumentForRemoteRestore(document);
    }
  }

  Future<void> _pullRemoteDocuments({
    required String token,
    required String spaceId,
  }) async {
    final response = await _dio.get(
      '${ApiEndPoints.baseUrl}spaces/$spaceId/documents',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final items = response.data as List;
    for (var i = 0; i < items.length; i++) {
      final remote = Map<String, dynamic>.from(items[i] as Map);
      progress.value = SyncProgress(
        stage: SyncStage.documents,
        direction: SyncDirection.download,
        current: i + 1,
        total: items.length,
        itemLabel: remote['title'] as String?,
      );
      final remoteId = remote['id'] as String;
      var remoteRevision = remote['revision'] as int;
      final remoteAttachments = List<Map<String, dynamic>>.from(
        (remote['attachments'] as List? ?? const []).map(
          (value) => Map<String, dynamic>.from(value as Map),
        ),
      );
      final localId =
          await _database.localDocumentIdForRemoteId(remoteId) ?? remoteId;
      final currentState = await _database.documentSyncState(localId);
      final existing = await _database.documentById(localId);
      final supportsTags = remote.containsKey('tags');
      var remoteTags = supportsTags
          ? List<String>.from(remote['tags'] as List? ?? const [])
          : existing?.tags ?? const <String>[];

      // Tags used to live only in the device database. Once the API supports
      // them, publish an existing device's local tags exactly once even if the
      // document itself has not otherwise changed. Do not attempt this against
      // an older server which does not include a `tags` field in its response.
      if (supportsTags &&
          currentState != null &&
          currentState['remote_revision'] == remoteRevision &&
          remoteTags.isEmpty &&
          existing != null &&
          existing.tags.isNotEmpty) {
        final tagResponse = await _dio.patch(
          '${ApiEndPoints.baseUrl}documents/$remoteId',
          data: {'tags': existing.tags, 'base_revision': remoteRevision},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        final taggedRemote = Map<String, dynamic>.from(tagResponse.data as Map);
        remoteRevision = taggedRemote['revision'] as int;
        remoteTags = List<String>.from(
          taggedRemote['tags'] as List? ?? existing.tags,
        );
        remote['tags'] = remoteTags;
      }
      if (currentState != null &&
          currentState['remote_revision'] == remoteRevision &&
          await _attachmentsAreUsable(localId, remoteAttachments)) {
        // Already current locally — most commonly because we're the one
        // that just pushed this exact revision in the upload step above.
        // Nothing changed server-side, so there's nothing to pull: skip
        // the DB rewrite and attachment work entirely.
        continue;
      }
      final attachmentPaths = await _downloadAttachments(
        localId: localId,
        remoteDocumentId: remoteId,
        attachments: remoteAttachments,
        token: token,
      );
      final createdAt = DateTime.parse(
        remote['created_at'] as String,
      ).toLocal();
      final expiry = remote['expiry_date'] as String?;
      final remoteCategoryId = remote['category_id'] as String?;
      final localCategoryId = remoteCategoryId == null
          ? uncategorizedCategoryId
          : await _database.localCategoryIdForRemoteId(remoteCategoryId) ??
                uncategorizedCategoryId;
      final localCategory = (await _database.fetchCategories())
          .where((category) => category.id == localCategoryId)
          .firstOrNull;
      await _database.applyRemoteDocument(
        DocumentItem(
          id: localId,
          title: remote['title'] as String,
          category: localCategory?.name ?? 'Uncategorized',
          categoryId: localCategoryId,
          iconKey: localCategory?.iconKey ?? 'folder',
          createdAt: createdAt,
          description: remote['description'] as String? ?? '',
          ocrText: remote['ocr_text'] as String? ?? '',
          tags: remoteTags,
          isExpirable: remote['is_expirable'] as bool? ?? false,
          expiryDate: expiry == null ? null : DateTime.tryParse(expiry),
          filePaths: attachmentPaths.isEmpty
              ? existing?.filePaths ?? const []
              : attachmentPaths,
        ),
      );
      await _database.saveDocumentSyncState(
        localId: localId,
        remoteId: remoteId,
        revision: remoteRevision,
      );
    }
  }

  /// A matching document revision alone is insufficient: an interrupted
  /// download may leave a partial attachment behind while the database has
  /// already recorded the remote revision. Verify the cached file before
  /// skipping a restore.
  Future<bool> _attachmentsAreUsable(
    String localDocumentId,
    List<Map<String, dynamic>> attachments,
  ) async {
    for (final attachment in attachments) {
      final id = attachment['id'] as String;
      final path = await _database.localPathForRemoteAttachment(
        localDocumentId,
        id,
      );
      if (path == null) return false;
      final file = File(path);
      if (!await file.exists()) return false;
      final expectedBytes = (attachment['byte_size'] as num?)?.toInt();
      if (expectedBytes != null && await file.length() != expectedBytes) {
        return false;
      }
    }
    return true;
  }

  Future<List<String>> _downloadAttachments({
    required String localId,
    required String remoteDocumentId,
    required List<Map<String, dynamic>> attachments,
    required String token,
  }) async {
    if (attachments.isEmpty) return const [];
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/documents');
    if (!await directory.exists()) await directory.create(recursive: true);
    final paths = <String>[];
    for (final attachment in attachments) {
      final id = attachment['id'] as String;
      final filename = (attachment['original_filename'] as String).replaceAll(
        RegExp(r'[^A-Za-z0-9._-]'),
        '_',
      );
      final path = '${directory.path}/remote_${id}_$filename';
      final file = File(path);
      final expectedBytes = (attachment['byte_size'] as num?)?.toInt();
      final isValidCachedFile =
          await file.exists() &&
          (expectedBytes == null || await file.length() == expectedBytes);
      if (!isValidCachedFile) {
        if (await file.exists()) await file.delete();
        final temporaryFile = File('$path.download');
        if (await temporaryFile.exists()) await temporaryFile.delete();
        try {
          await _dio.download(
            '${ApiEndPoints.baseUrl}attachments/$id/content',
            temporaryFile.path,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          if (expectedBytes != null &&
              await temporaryFile.length() != expectedBytes) {
            throw StateError(
              'Downloaded attachment size did not match the remote file.',
            );
          }
          // Rename only after a complete download, so the viewer never sees
          // a partial file if the app closes or the network drops mid-sync.
          await temporaryFile.rename(path);
        } on DioException catch (error) {
          if (await temporaryFile.exists()) await temporaryFile.delete();
          if (error.response?.statusCode == 404) {
            // The file was removed directly in Drive, outside the app.
            // If this device is the one that originally uploaded it, it
            // still has the bytes locally — push them back up to repair
            // the Drive copy instead of leaving the attachment orphaned.
            final ownPath = await _database.localPathForRemoteAttachment(
              localId,
              id,
            );
            if (ownPath != null && await File(ownPath).exists()) {
              await _database.clearAttachmentUploaded(localId, id);
              await _pushAttachment(
                localId: localId,
                remoteDocumentId: remoteDocumentId,
                path: ownPath,
                token: token,
              );
              paths.add(ownPath);
            }
            continue;
          }
          rethrow;
        } catch (_) {
          if (await temporaryFile.exists()) await temporaryFile.delete();
          rethrow;
        }
      }
      // This file now exists both locally and on the server under this
      // path — record it as already uploaded so a later edit of this
      // document (which re-sends its current file_paths) doesn't push the
      // exact same attachment back up as if it were new.
      await _database.markAttachmentUploaded(
        documentId: localId,
        path: path,
        remoteAttachmentId: id,
      );
      paths.add(path);
    }
    return paths;
  }

  Future<void> _syncDocument(
    Map<String, Object?> operation, {
    required String token,
    required String spaceId,
  }) async {
    final localId = operation['entity_id'] as String;
    final state = await _database.documentSyncState(localId);
    final headers = Options(headers: {'Authorization': 'Bearer $token'});
    if (operation['operation'] == 'delete') {
      if (state != null) {
        try {
          await _dio.delete(
            '${ApiEndPoints.baseUrl}documents/${state['remote_document_id']}',
            options: headers,
          );
        } on DioException catch (error) {
          // Delete is idempotent. If it was already removed from Neon, this
          // queued local delete is complete rather than a permanent retry.
          if (error.response?.statusCode != 404) rethrow;
        }
        await _database.clearDocumentRemoteState(localId);
      }
      return;
    }
    final payload = Map<String, dynamic>.from(
      jsonDecode(operation['payload'] as String) as Map,
    );
    final filePaths = List<String>.from(
      payload['file_paths'] as List? ?? const [],
    );
    final localCategoryId = payload['category_id'] as String?;
    payload['category_id'] =
        localCategoryId == null || localCategoryId == uncategorizedCategoryId
        ? null
        : await _database.remoteCategoryIdForLocalId(localCategoryId);
    payload.remove('file_paths');
    payload['expiry_date'] = (payload['expiry_date'] as String?)
        ?.split('T')
        .first;
    if (state == null) {
      final response = await _dio.post(
        '${ApiEndPoints.baseUrl}spaces/$spaceId/documents',
        data: payload,
        options: headers,
      );
      final remote = Map<String, dynamic>.from(response.data as Map);
      await _database.saveDocumentSyncState(
        localId: localId,
        remoteId: remote['id'] as String,
        revision: remote['revision'] as int,
      );
      await _uploadAttachments(
        localId: localId,
        remoteDocumentId: remote['id'] as String,
        paths: filePaths,
        token: token,
      );
      return;
    }
    payload['base_revision'] = state['remote_revision'];
    final response = await _dio.patch(
      '${ApiEndPoints.baseUrl}documents/${state['remote_document_id']}',
      data: payload,
      options: headers,
    );
    final remote = Map<String, dynamic>.from(response.data as Map);
    await _database.saveDocumentSyncState(
      localId: localId,
      remoteId: remote['id'] as String,
      revision: remote['revision'] as int,
    );
    await _uploadAttachments(
      localId: localId,
      remoteDocumentId: remote['id'] as String,
      paths: filePaths,
      token: token,
    );
  }

  Future<void> _uploadAttachments({
    required String localId,
    required String remoteDocumentId,
    required List<String> paths,
    required String token,
  }) async {
    for (final path in paths) {
      if (await _database.isAttachmentUploaded(localId, path)) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      await _pushAttachment(
        localId: localId,
        remoteDocumentId: remoteDocumentId,
        path: path,
        token: token,
      );
    }
  }

  Future<void> _pushAttachment({
    required String localId,
    required String remoteDocumentId,
    required String path,
    required String token,
  }) async {
    final response = await _dio.post(
      '${ApiEndPoints.baseUrl}documents/$remoteDocumentId/attachments',
      data: FormData.fromMap({'file': await MultipartFile.fromFile(path)}),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final remote = Map<String, dynamic>.from(response.data as Map);
    await _database.markAttachmentUploaded(
      documentId: localId,
      path: path,
      remoteAttachmentId: remote['id'] as String,
    );
  }
}
