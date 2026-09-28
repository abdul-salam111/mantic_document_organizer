// Barrel export for the trash page — this is what OTHER features/core
// files import to reach trash's public API (e.g. its view pushed from
// Profile's "Trash" menu tile). The documents feature's data/domain
// layer lives one level up, shared with every other page under
// lib/features/documents/ (see add_document_exports.dart) — not
// duplicated per page. Files *inside* the trash page should import each
// other with relative paths, not this file.
export '../../data/datasources/remote_document_datasource.dart';
export '../../data/models/request_models/document_params.dart';
export '../../data/models/response_models/document_response.dart';
export '../../data/repository_impl/document_repository_impl.dart';
export '../../domain/entities/document_entity.dart';
export '../../domain/repositories/document_repository.dart';
export '../../domain/usecases/document_usecase.dart';
export 'presentation/trash/views/trash_view.dart';
export 'presentation/trash/viewmodels/trash_viewmodel.dart';
