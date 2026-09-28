// Barrel export for the expiring-soon page — this is what OTHER
// features/core files import to reach its public API (the weekly digest
// notification's tap target, wired in main.dart via ExpiryDigestListener).
// The documents feature's data/domain layer lives one level up, shared
// with every other page under lib/features/documents/ (see
// trash_exports.dart) — not duplicated per page. Files *inside* this page
// should import each other with relative paths, not this file.
export '../../data/datasources/remote_document_datasource.dart';
export '../../data/models/request_models/document_params.dart';
export '../../data/models/response_models/document_response.dart';
export '../../data/repository_impl/document_repository_impl.dart';
export '../../domain/entities/document_entity.dart';
export '../../domain/repositories/document_repository.dart';
export '../../domain/usecases/document_usecase.dart';
export 'presentation/expiring_soon/views/expiring_soon_view.dart';
export 'presentation/expiring_soon/viewmodels/expiring_soon_viewmodel.dart';
