import '../../../../core/shared/shared_exports.dart';
import '../datasources/remote_{{fileName}}_datasource.dart';
import '../models/request_models/{{fileName}}_params.dart';
import '../../domain/entities/{{fileName}}_entity.dart';
import '../../domain/repositories/{{fileName}}_repository.dart';

class {{className}}RepositoryImpl extends BaseRepository implements I{{className}}Repository {
  final IRemote{{className}}DataSource dataSource;

  {{className}}RepositoryImpl({required this.dataSource});

  @override
  Future<Result<{{className}}Entity>> performAction({
    required {{className}}Params params,
  }) async {
    final result = await execute(
      call: () => dataSource.performAction(params: params),
    );
    return result.fold(
      onFailure: (error) => Failure(error),
      onSuccess: (response) => Success(
        {{className}}Entity(
          id: response.id,
          name: response.name,
          description: response.description,
        ),
      ),
    );
  }
}
