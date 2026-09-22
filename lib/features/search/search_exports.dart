// Barrel export for the search feature — this is what OTHER
// features/core files import to reach search's public API (e.g. its view
// for the navbar tab, or its models for a DI registration). Files
// *inside* the search feature should import each other with relative
// paths, not this file.
export 'data/datasources/remote_search_datasource.dart';
export 'data/models/request_models/search_params.dart';
export 'data/models/response_models/search_response.dart';
export 'data/repository_impl/search_repository_impl.dart';
export 'domain/entities/search_entity.dart';
export 'domain/repositories/search_repository.dart';
export 'domain/usecases/search_usecase.dart';
export 'presentation/search/views/search_view.dart';
export 'presentation/search/viewmodels/search_viewmodel.dart';
