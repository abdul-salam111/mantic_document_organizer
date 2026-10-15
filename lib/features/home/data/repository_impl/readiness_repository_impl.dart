import 'dart:convert';
import '../../../../core/local_storage/local_storage_exports.dart';
import '../../../../core/shared/domain/repository/base_repository.dart';
import '../../../../core/shared/domain/result/result.dart';
import '../../domain/entities/document_readiness.dart';
import '../../domain/repositories/readiness_repository.dart';

class ReadinessRepositoryImpl extends BaseRepository implements IReadinessRepository {
  static const _key = 'documentReadiness.v1';
  @override
  Future<Result<ReadinessPreferences>> load() => execute(call: () async {
    final raw = await storage.readValues(_key);
    if (raw == null) return ReadinessPreferences();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final excluded = List<String>.from(data['excluded'] as List);
    final links = Map<String, String>.from(data['links'] as Map);
    return ReadinessPreferences(
      excluded: {for (final group in ReadinessGroup.values) if (excluded.contains(group.name)) group},
      links: {for (final group in ReadinessGroup.values) if (links[group.name] case final id?) group: id},
    );
  });
  @override
  Future<Result<ReadinessPreferences>> save(ReadinessPreferences preferences) => execute(call: () async {
    await storage.setValues(_key, jsonEncode({
      'excluded': preferences.excluded.map((g) => g.name).toList(),
      'links': {for (final entry in preferences.links.entries) entry.key.name: entry.value},
    }));
    return preferences;
  });
}
