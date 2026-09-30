// Barrel export for the favorites feature — this is what OTHER
// features/core files import to reach favorites's public API (e.g. its
// view for the navbar tab, or its models for a DI registration). Files
// *inside* the favorites feature should import each other with relative
// paths, not this file.
export 'presentation/favorites/views/favorites_view.dart';
export 'presentation/favorites/viewmodels/favorites_viewmodel.dart';
