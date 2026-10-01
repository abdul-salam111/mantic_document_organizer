import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/database/app_database.dart';
import '../../../categories/domain/entities/category_item.dart';
import '../../../documents/domain/entities/document_item.dart';

/// Sends durable local document mutations after backup setup. Local writes
/// always succeed first; failed HTTP work remains in SQLite for a later run.
class DocumentSyncService {
  DocumentSyncService(this._database, this._dio);

  final AppDatabase _database;
  final Dio _dio;
  bool _running = false;

  Future<void> sync({required String token, required String spaceId}) async {
    if (_running) return;
    _running = true;
    try {
      await _syncCategories(token: token, spaceId: spaceId);
      for (final item in await _database.pendingSyncOperations()) {
        final id = item['id'] as int;
        try {
          await _syncDocument(item, token: token, spaceId: spaceId);
          await _database.completeSyncOperation(id);
        } catch (_) {
          await _database.recordSyncFailure(id);
          break;
        }
      }
      await _pullRemoteDocuments(token: token, spaceId: spaceId);
    } finally {
      _running = false;
    }
  }

  Future<void> _syncCategories({
    required String token,
    required String spaceId,
  }) async {
    final headers = Options(headers: {'Authorization': 'Bearer $token'});
    final remoteResponse = await _dio.get(
      '${ApiEndPoints.baseUrl}spaces/$spaceId/categories',
      options: headers,
    );
    final localCategories = await _database.fetchCategories();
    for (final value in remoteResponse.data as List) {
      final remote = Map<String, dynamic>.from(value as Map);
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
        );
        await _database.upsertCategory(localCategory);
      }
      await _database.saveCategorySyncState(
        localId: localCategory.id,
        remoteId: remoteId,
      );
    }

    for (final category in await _database.fetchCategories()) {
      if (category.id == uncategorizedCategoryId ||
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

    // Send the current local appearance too. This backfills built-in category
    // colors created by older app versions and keeps custom category edits
    // consistent for every device in the space.
    for (final category in await _database.fetchCategories()) {
      if (category.id == uncategorizedCategoryId) continue;
      final remoteId = await _database.remoteCategoryIdForLocalId(category.id);
      if (remoteId == null) continue;
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

  Future<void> _pullRemoteDocuments({
    required String token,
    required String spaceId,
  }) async {
    final response = await _dio.get(
      '${ApiEndPoints.baseUrl}spaces/$spaceId/documents',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    for (final value in response.data as List) {
      final remote = Map<String, dynamic>.from(value as Map);
      final remoteId = remote['id'] as String;
      final localId =
          await _database.localDocumentIdForRemoteId(remoteId) ?? remoteId;
      final existing = await _database.documentById(localId);
      final attachmentPaths = await _downloadAttachments(
        attachments: List<Map<String, dynamic>>.from(
          (remote['attachments'] as List? ?? const []).map(
            (value) => Map<String, dynamic>.from(value as Map),
          ),
        ),
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
        revision: remote['revision'] as int,
      );
    }
  }

  Future<List<String>> _downloadAttachments({
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
      if (!await file.exists()) {
        await _dio.download(
          '${ApiEndPoints.baseUrl}attachments/$id/content',
          path,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
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
        await _dio.delete(
          '${ApiEndPoints.baseUrl}documents/${state['remote_document_id']}',
          options: headers,
        );
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
}
