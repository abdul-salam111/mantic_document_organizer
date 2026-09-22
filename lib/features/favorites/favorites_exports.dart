// Barrel export for the favorites feature — this is what OTHER
// features/core files import to reach favorites's public API (e.g. its
// view for the navbar tab, or its models for a DI registration). Files
// *inside* the favorites feature should import each other with relative
// paths, not this file.
export 'data/datasources/remote_favorites_datasource.dart';
export 'data/models/response_models/favorites_response.dart';
export 'data/repository_impl/favorites_repository_impl.dart';
export 'domain/entities/favorites_entity.dart';
export 'domain/repositories/favorites_repository.dart';
export 'domain/usecases/favorites_usecase.dart';
export 'presentation/favorites/views/favorites_view.dart';
export 'presentation/favorites/viewmodels/favorites_viewmodel.dart';
