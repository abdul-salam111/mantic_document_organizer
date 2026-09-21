import 'dart:io';
import 'package:mason/mason.dart';

// The inverse of create_feature's (and, for any pages added afterward,
// add_page's) post_gen.dart. Rather than only removing the one route
// named after the feature itself, this discovers EVERY page the feature
// contains by listing lib/features/<name>/presentation/*/ — each
// subfolder is one page, whether it's the feature's original page from
// create_feature or a sub-flow added later via add_page (e.g. auth's
// signin/signup) — and removes each one's routes/DI wiring before
// deleting the whole feature directory.
Future<void> run(HookContext context) async {
  final logger = context.logger;

  final fileName = context.vars['fileName'] as String;
  final camelName = context.vars['camelName'] as String;

  final libDir = Directory('${Directory.current.path}/lib');
  final featureDir = Directory('${libDir.path}/features/$fileName');
  final touchedFiles = <File>[];

  final pages = _discoverPages(featureDir);
  if (pages.isEmpty) {
    logger.warn(
      '⚠️  No pages found under ${_rel(featureDir.path)}/presentation/ — '
      'only removing the barrel-export imports below.',
    );
  }

  for (final page in pages) {
    touchedFiles.addAll(
      _removePageRoutes(libDir, page.className, page.fileName, logger),
    );
    touchedFiles.addAll(
      _removePageDependencies(libDir, page.camelName, logger),
    );
  }

  touchedFiles.addAll(_removeFeatureImports(libDir, fileName, logger));

  // Also remove the feature's own top-level dependency function, in case
  // it registered a DataSource/Repository that isn't tied to any single
  // page's camelName (create_feature's own pattern: `${camelName}
  // Dependencies()` named after the FEATURE, which for a feature whose
  // main page shares its own name is already covered by the loop above,
  // but isn't if the feature's page folders are all named differently).
  touchedFiles.addAll(_removePageDependencies(libDir, camelName, logger));

  await _formatPaths(
    touchedFiles.map((f) => f.path).toSet().toList(),
    logger,
  );

  if (featureDir.existsSync()) {
    featureDir.deleteSync(recursive: true);
    logger.success('🗑️  Deleted: ${_rel(featureDir.path)}/');
  }

  logger.success('\n✅ "$fileName" feature removed.');
}

String _rel(String path) => path.replaceAll('\\', '/');

class _Page {
  final String fileName;
  final String className;
  final String camelName;
  _Page(this.fileName, this.className, this.camelName);
}

/// Lists lib/features/<name>/presentation/*/ — each subfolder is one page
/// (create_feature's own main page, or a sub-flow add_page added later).
List<_Page> _discoverPages(Directory featureDir) {
  final presentationDir = Directory('${featureDir.path}/presentation');
  if (!presentationDir.existsSync()) return const [];

  final pages = <_Page>[];
  for (final entity in presentationDir.listSync()) {
    if (entity is! Directory) continue;
    final pageFileName = entity.path.split(RegExp(r'[\\/]')).last;
    final words = _splitWords(pageFileName);
    if (words.isEmpty) continue;

    pages.add(
      _Page(
        words.join('_'),
        words.map((w) => w[0].toUpperCase() + w.substring(1)).join(),
        words.first +
            words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join(),
      ),
    );
  }
  return pages;
}

// ------------------------------------------------------------------
// 🧩 REMOVE ONE PAGE'S ROUTES
// ------------------------------------------------------------------
List<File> _removePageRoutes(
  Directory libDir,
  String className,
  String fileName,
  Logger logger,
) {
  final routesDir = Directory('${libDir.path}/routes');
  final touched = <File>[];

  final namesFile = File('${routesDir.path}/route_names.dart');
  if (namesFile.existsSync()) {
    final crlf = _RawFile(namesFile);
    final updated = _removeLineWithValue(crlf.content, fileName);
    if (updated != null) {
      crlf.content = updated;
      crlf.save();
      touched.add(namesFile);
    }
  }

  final pathsFile = File('${routesDir.path}/route_paths.dart');
  if (pathsFile.existsSync()) {
    final crlf = _RawFile(pathsFile);
    final updated = _removeLineWithValue(crlf.content, '/$fileName');
    if (updated != null) {
      crlf.content = updated;
      crlf.save();
      touched.add(pathsFile);
    }
  }

  final routerFile = File('${routesDir.path}/app_router.dart');
  if (routerFile.existsSync()) {
    final crlf = _RawFile(routerFile);
    final updated = _removeGoRouteBlock(crlf.content, className);
    if (updated != null) {
      crlf.content = updated;
      crlf.save();
      touched.add(routerFile);
    }
  }

  if (touched.isNotEmpty) {
    logger.success('🧭 Removed routes for ${className}Page');
  }
  return touched;
}

// ------------------------------------------------------------------
// 🧩 REMOVE ONE PAGE'S DEPENDENCY FUNCTION + CALL
// ------------------------------------------------------------------
List<File> _removePageDependencies(
  Directory libDir,
  String camelName,
  Logger logger,
) {
  final diFile = File('${libDir.path}/core/di/injection_container.dart');
  if (!diFile.existsSync()) return const [];

  final crlf = _RawFile(diFile);
  var content = crlf.content;
  var changed = false;

  final withoutFunction = _removeDependencyFunction(content, camelName);
  if (withoutFunction != null) {
    content = withoutFunction;
    changed = true;
  }

  final withoutCall = _removeLineWithText(
    content,
    'await ${camelName}Dependencies();',
  );
  if (withoutCall != null) {
    content = withoutCall;
    changed = true;
  }

  if (!changed) return const [];

  crlf.content = content;
  crlf.save();
  logger.success('🧱 Removed ${camelName}Dependencies() wiring');
  return [diFile];
}

// ------------------------------------------------------------------
// 🧩 REMOVE THE FEATURE'S BARREL IMPORT FROM ROUTER/DI
// ------------------------------------------------------------------
List<File> _removeFeatureImports(
  Directory libDir,
  String fileName,
  Logger logger,
) {
  final touched = <File>[];

  final routerFile = File('${libDir.path}/routes/app_router.dart');
  if (routerFile.existsSync()) {
    final crlf = _RawFile(routerFile);
    final updated = _removeLineWithText(
      crlf.content,
      "import '../features/$fileName/${fileName}_exports.dart';",
    );
    if (updated != null) {
      crlf.content = updated;
      crlf.save();
      touched.add(routerFile);
      logger.success('🧭 Removed feature import from app_router.dart');
    }
  }

  final diFile = File('${libDir.path}/core/di/injection_container.dart');
  if (diFile.existsSync()) {
    final crlf = _RawFile(diFile);
    final updated = _removeLineWithText(
      crlf.content,
      "import '../../features/$fileName/${fileName}_exports.dart';",
    );
    if (updated != null) {
      crlf.content = updated;
      crlf.save();
      touched.add(diFile);
      logger.success('🧱 Removed feature import from injection_container.dart');
    }
  }

  return touched;
}

// ------------------------------------------------------------------
// 🧩 HELPER FUNCTIONS
// ------------------------------------------------------------------

List<String> _splitWords(String text) {
  final normalized = text.trim().replaceAll(RegExp(r'[\s\-]+'), '_');
  final withBoundaries = normalized.replaceAllMapped(
    RegExp(r'(?<=[a-z0-9])(?=[A-Z])'),
    (match) => '_',
  );
  return withBoundaries
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => word.toLowerCase())
      .toList();
}

String? _removeLineWithValue(String content, String value) {
  final pattern = RegExp(
    '^[ \\t]*static const String \\w+ = "${RegExp.escape(value)}";[ \\t]*\$\\r?\\n?',
    multiLine: true,
  );
  if (!pattern.hasMatch(content)) return null;
  return content.replaceFirst(pattern, '');
}

String? _removeLineWithText(String content, String text) {
  final pattern = RegExp(
    '^[ \\t]*${RegExp.escape(text)}[ \\t]*\$\\r?\\n?',
    multiLine: true,
  );
  if (!pattern.hasMatch(content)) return null;
  return content.replaceFirst(pattern, '');
}

String? _removeGoRouteBlock(String content, String className) {
  final pattern = RegExp(
    r'[ \t]*GoRoute\(\s*path:\s*RoutePaths\.\w+,\s*name:\s*RouteNames\.\w+,\s*builder:\s*\(context,\s*state\)\s*=>\s*const\s*'
    '$className'
    r'Page\(\),\s*\),[ \t]*\r?\n',
  );
  final match = pattern.firstMatch(content);
  if (match == null) return null;
  return content.replaceRange(match.start, match.end, '');
}

String? _removeDependencyFunction(String content, String camelName) {
  final pattern = RegExp(
    '(?:^[ \\t]*///.*\\r?\\n)*'
    '^Future<void> ${RegExp.escape(camelName)}Dependencies\\(\\) async \\{'
    r'[\s\S]*?'
    r'\r?\n\}\r?\n\r?\n?',
    multiLine: true,
  );
  final match = pattern.firstMatch(content);
  if (match == null) return null;
  return content.replaceRange(match.start, match.end, '');
}

class _RawFile {
  final File file;
  final bool _wasCrlf;
  String content;

  _RawFile(this.file)
    : _wasCrlf = file.readAsStringSync().contains('\r\n'),
      content = file.readAsStringSync().replaceAll('\r\n', '\n');

  void save() {
    file.writeAsStringSync(_wasCrlf ? content.replaceAll('\n', '\r\n') : content);
  }
}

Future<void> _formatPaths(List<String> paths, Logger logger) async {
  if (paths.isEmpty) return;

  final result = await Process.run('dart', [
    'format',
    ...paths,
  ], runInShell: true);

  if (result.exitCode == 0) {
    logger.success('🎨 Formatted updated files');
  } else {
    logger.warn('⚠️  dart format failed: ${result.stderr}');
  }
}
