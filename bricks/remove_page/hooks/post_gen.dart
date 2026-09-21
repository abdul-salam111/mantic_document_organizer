import 'dart:io';
import 'package:mason/mason.dart';

// The inverse of add_page's post_gen.dart: removes everything that brick
// wires into files that already exist (route_names.dart, route_paths.dart,
// app_router.dart, injection_container.dart, the feature's barrel export),
// then deletes the page's own files. Deliberately does NOT assume which
// generator created the page (create_feature and add_page use slightly
// different identifier-naming conventions for their route constants) —
// every removal below matches on the STRING VALUE ("$fileName") or on the
// concrete generated class name, both of which are stable regardless of
// which brick originally created the page.
Future<void> run(HookContext context) async {
  final logger = context.logger;

  final featureFileName = context.vars['featureFileName'] as String;
  final fileName = context.vars['fileName'] as String;
  final className = context.vars['className'] as String;
  final camelName = context.vars['camelName'] as String;

  final libDir = Directory('${Directory.current.path}/lib');
  final touchedFiles = <File>[];

  touchedFiles.addAll(_updateRoutes(libDir, className, fileName, logger));
  touchedFiles.addAll(
    _updateDependencyInjection(libDir, fileName, camelName, logger),
  );
  touchedFiles.addAll(
    _updateFeatureExports(libDir, featureFileName, fileName, logger),
  );

  await _formatPaths(
    touchedFiles.map((f) => f.path).toList(),
    logger,
  );

  final pageDir = Directory(
    '${libDir.path}/features/$featureFileName/presentation/$fileName',
  );
  final usecaseFile = File(
    '${libDir.path}/features/$featureFileName/domain/usecases/${fileName}_usecase.dart',
  );

  if (pageDir.existsSync()) {
    pageDir.deleteSync(recursive: true);
    logger.success('🗑️  Deleted: ${_rel(pageDir.path)}');
  }
  if (usecaseFile.existsSync()) {
    usecaseFile.deleteSync();
    logger.success('🗑️  Deleted: ${_rel(usecaseFile.path)}');
  } else {
    logger.warn(
      '⚠️  ${_rel(usecaseFile.path)} not found — skipped (already moved '
      'or renamed?).',
    );
  }

  logger.success('\n✅ $className page removed.');
}

String _rel(String path) => path.replaceAll('\\', '/');

// ------------------------------------------------------------------
// 🧩 REMOVE ROUTES
// ------------------------------------------------------------------
List<File> _updateRoutes(
  Directory libDir,
  String className,
  String fileName,
  Logger logger,
) {
  final routesDir = Directory('${libDir.path}/routes');
  final touched = <File>[];

  // ✅ 1. route_names.dart — matched by the string VALUE ("$fileName"),
  // not the constant identifier, since create_feature and add_page don't
  // use the same identifier-naming convention.
  final namesFile = File('${routesDir.path}/route_names.dart');
  if (namesFile.existsSync()) {
    final crlf = _RawFile(namesFile);
    final updated = _removeLineWithValue(crlf.content, fileName);
    if (updated != null) {
      crlf.content = updated;
      crlf.save();
      touched.add(namesFile);
      logger.success('🧭 Updated: lib/routes/route_names.dart');
    } else {
      logger.warn('⚠️  No route_names.dart entry found for "$fileName"');
    }
  }

  // ✅ 2. route_paths.dart
  final pathsFile = File('${routesDir.path}/route_paths.dart');
  if (pathsFile.existsSync()) {
    final crlf = _RawFile(pathsFile);
    final updated = _removeLineWithValue(crlf.content, '/$fileName');
    if (updated != null) {
      crlf.content = updated;
      crlf.save();
      touched.add(pathsFile);
      logger.success('🧭 Updated: lib/routes/route_paths.dart');
    } else {
      logger.warn('⚠️  No route_paths.dart entry found for "/$fileName"');
    }
  }

  // ✅ 3. app_router.dart — matched by the concrete builder line, which is
  // stable regardless of the route constant's identifier name.
  final routerFile = File('${routesDir.path}/app_router.dart');
  if (routerFile.existsSync()) {
    final crlf = _RawFile(routerFile);
    final updated = _removeGoRouteBlock(crlf.content, className);
    if (updated != null) {
      crlf.content = updated;
      crlf.save();
      touched.add(routerFile);
      logger.success('🧭 Updated: lib/routes/app_router.dart');
    } else {
      logger.warn('⚠️  No app_router.dart route found for ${className}Page');
    }
  }

  return touched;
}

// ------------------------------------------------------------------
// 🧩 REMOVE DEPENDENCY INJECTION
// ------------------------------------------------------------------
List<File> _updateDependencyInjection(
  Directory libDir,
  String fileName,
  String camelName,
  Logger logger,
) {
  final diFile = File('${libDir.path}/core/di/injection_container.dart');
  if (!diFile.existsSync()) {
    logger.err('❌ injection_container.dart not found');
    return const [];
  }

  final crlf = _RawFile(diFile);
  var content = crlf.content;
  var changed = false;

  final withoutFunction = _removeDependencyFunction(content, camelName);
  if (withoutFunction != null) {
    content = withoutFunction;
    changed = true;
  } else {
    logger.warn(
      '⚠️  No ${camelName}Dependencies() function found in '
      'injection_container.dart',
    );
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
  logger.success('🧱 Updated: lib/core/di/injection_container.dart');
  return [diFile];
}

// ------------------------------------------------------------------
// 🧩 REMOVE FROM THE FEATURE'S BARREL EXPORT
// ------------------------------------------------------------------
List<File> _updateFeatureExports(
  Directory libDir,
  String featureFileName,
  String fileName,
  Logger logger,
) {
  final exportsFile = File(
    '${libDir.path}/features/$featureFileName/${featureFileName}_exports.dart',
  );
  if (!exportsFile.existsSync()) return const [];

  final exportsToRemove = [
    "export 'presentation/$fileName/views/${fileName}_page.dart';",
    "export 'presentation/$fileName/viewmodels/${fileName}_viewmodel.dart';",
    "export 'domain/usecases/${fileName}_usecase.dart';",
  ];

  final crlf = _RawFile(exportsFile);
  var content = crlf.content;
  var changed = false;

  for (final line in exportsToRemove) {
    final updated = _removeLineWithText(content, line);
    if (updated != null) {
      content = updated;
      changed = true;
    }
  }

  if (!changed) return const [];

  crlf.content = content;
  crlf.save();
  logger.success('🧱 Updated: ${featureFileName}_exports.dart');
  return [exportsFile];
}

// ------------------------------------------------------------------
// 🧩 HELPER FUNCTIONS
// ------------------------------------------------------------------

/// Removes a `static const String <ident> = "<value>";` line whose string
/// literal is exactly [value] (matched on the value, not the identifier
/// name, since different generators name the identifier differently).
/// Returns `null` if no such line is found.
String? _removeLineWithValue(String content, String value) {
  final pattern = RegExp(
    '^[ \\t]*static const String \\w+ = "${RegExp.escape(value)}";[ \\t]*\$\\r?\\n?',
    multiLine: true,
  );
  if (!pattern.hasMatch(content)) return null;
  return content.replaceFirst(pattern, '');
}

/// Removes the first line whose trimmed content exactly equals
/// [text]. Returns `null` if not found.
String? _removeLineWithText(String content, String text) {
  final pattern = RegExp(
    '^[ \\t]*${RegExp.escape(text)}[ \\t]*\$\\r?\\n?',
    multiLine: true,
  );
  if (!pattern.hasMatch(content)) return null;
  return content.replaceFirst(pattern, '');
}

/// Removes a `GoRoute(...)` block whose builder constructs
/// `const <className>Page()`, regardless of what its `path`/`name`
/// constant identifiers are called.
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

/// Removes a `Future<void> <camelName>Dependencies() async { ... }`
/// function, including any `///` doc comment lines directly above it.
/// Matches braces one level deep only (this template's generated
/// dependency functions never nest braces beyond the outer one), which is
/// enough to find the function's closing brace reliably.
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

/// Reads a file, normalizing CRLF to LF so plain string/regex anchors
/// match regardless of the working tree's line-ending style, then
/// converts back to the file's original line ending on [save].
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

/// Runs `dart format` on every file this hook modified (never on deleted
/// paths — those no longer exist by the time this runs).
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
