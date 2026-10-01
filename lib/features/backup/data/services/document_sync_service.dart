import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/database/app_database.dart';

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
    } finally {
      _running = false;
    }
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
    // Local category ids are not server UUIDs yet. Category synchronization is
    // a separate queued entity, so documents first sync without a category.
    payload.remove('category_id');
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
  }
}
