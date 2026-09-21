// Barrel export for the {{fileName}} feature — this is what OTHER
// features/core files import to reach {{fileName}}'s public API (e.g. its
// page for routing, or its models for a DI registration). Files *inside*
// the {{fileName}} feature should import each other with relative paths,
// not this file.
export 'data/datasources/remote_{{fileName}}_datasource.dart';
export 'data/models/request_models/{{fileName}}_params.dart';
export 'data/models/response_models/{{fileName}}_response.dart';
export 'data/repository_impl/{{fileName}}_repository_impl.dart';
export 'domain/entities/{{fileName}}_entity.dart';
export 'domain/repositories/{{fileName}}_repository.dart';
export 'domain/usecases/{{fileName}}_usecase.dart';
export 'presentation/{{fileName}}/views/{{fileName}}_page.dart';
export 'presentation/{{fileName}}/viewmodels/{{fileName}}_viewmodel.dart';
