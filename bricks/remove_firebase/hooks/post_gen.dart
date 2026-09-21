import 'dart:io';
import 'package:mason/mason.dart';

// The inverse of add_firebase's post_gen.dart: reverts every file it
// wires (pubspec.yaml, the Android Gradle files, lib/main.dart,
// lib/core/di/injection_container.dart, auth_exports.dart) and deletes
// the Firebase source files it generated. pre_gen.dart already refused to
// run if IAuthRepository is currently wired to FirebaseAuthRepositoryImpl,
// so by the time this runs it's safe to delete that class.
Future<void> run(HookContext context) async {
  final logger = context.logger;
  final projectRoot = Directory.current.path;
  final libDir = Directory('$projectRoot/lib');

  final touchedFiles = <File>[];

  _updatePubspec(projectRoot, logger);
  _updateAndroidGradle(projectRoot, logger);
  touchedFiles.addAll(_updateMain(libDir, logger));
  touchedFiles.addAll(_updateDependencyInjection(libDir, logger));
  touchedFiles.addAll(_updateAuthExports(libDir, logger));

  await _formatPaths(
    touchedFiles.where((f) => f.path.endsWith('.dart')).map((f) => f.path).toList(),
    logger,
  );

  _deleteIfExists(
    File('${libDir.path}/core/networks/exceptions/firebase_auth_exceptions.dart'),
    logger,
  );
  _deleteDirIfExists(Directory('${libDir.path}/core/networks/firebase'), logger);
  _deleteIfExists(
    File(
      '${libDir.path}/features/auth/data/repository_impl/firebase_auth_repository_impl.dart',
    ),
    logger,
  );

  logger.success('\n✅ Firebase Auth infrastructure removed.');
  logger.info(
    '💡 Run `flutter pub get` to drop firebase_core/firebase_auth from '
    'the resolved dependency tree.',
  );
}

void _deleteIfExists(File file, Logger logger) {
  if (file.existsSync()) {
    file.deleteSync();
    logger.success('🗑️  Deleted: ${_rel(file.path)}');
  }
}

void _deleteDirIfExists(Directory dir, Logger logger) {
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
    logger.success('🗑️  Deleted: ${_rel(dir.path)}/');
  }
}

String _rel(String path) => path.replaceAll('\\', '/');

// ------------------------------------------------------------------
// 🧩 REVERT pubspec.yaml
// ------------------------------------------------------------------
void _updatePubspec(String projectRoot, Logger logger) {
  final pubspecFile = File('$projectRoot/pubspec.yaml');
  if (!pubspecFile.existsSync()) return;

  final crlf = _RawFile(pubspecFile);
  var content = crlf.content;
  var changed = false;

  for (final prefix in ['firebase_core:', 'firebase_auth:']) {
    final updated = _removeLineStartingWith(content, prefix);
    if (updated != null) {
      content = updated;
      changed = true;
    }
  }

  if (!changed) return;
  crlf.content = content;
  crlf.save();
  logger.success('📦 Updated: pubspec.yaml');
}

// ------------------------------------------------------------------
// 🧩 REVERT ANDROID GRADLE FILES
// ------------------------------------------------------------------
void _updateAndroidGradle(String projectRoot, Logger logger) {
  final settingsFile = File('$projectRoot/android/settings.gradle.kts');
  if (settingsFile.existsSync()) {
    final crlf = _RawFile(settingsFile);
    final updated = _removeLineStartingWith(
      crlf.content,
      'id("com.google.gms.google-services")',
    );
    if (updated != null) {
      crlf.content = updated;
      crlf.save();
      logger.success('🧭 Updated: android/settings.gradle.kts');
    }
  }

  final appGradleFile = File('$projectRoot/android/app/build.gradle.kts');
  if (appGradleFile.existsSync()) {
    final crlf = _RawFile(appGradleFile);
    const block =
        '\n'
        '// Firebase (google-services.json) — applied only if that file exists,\n'
        '// so builds/CI keep working before Firebase is actually configured.\n'
        '// See the add_firebase brick\'s README for how to add this file.\n'
        'if (file("google-services.json").exists()) {\n'
        '    apply(plugin = "com.google.gms.google-services")\n'
        '}\n';
    if (crlf.content.contains(block)) {
      crlf.content = crlf.content.replaceFirst(block, '');
      crlf.save();
      logger.success('🧭 Updated: android/app/build.gradle.kts');
    }
  }
}

// ------------------------------------------------------------------
// 🧩 REVERT lib/main.dart
// ------------------------------------------------------------------
List<File> _updateMain(Directory libDir, Logger logger) {
  final mainFile = File('${libDir.path}/main.dart');
  if (!mainFile.existsSync()) return const [];

  final crlf = _RawFile(mainFile);
  var content = crlf.content;
  var changed = false;

  final withoutImport = _removeLineWithText(
    content,
    "import 'package:firebase_core/firebase_core.dart';",
  );
  if (withoutImport != null) {
    content = withoutImport;
    changed = true;
  }

  final withoutInit = _removeLineWithText(
    content,
    'await Firebase.initializeApp();',
  );
  if (withoutInit != null) {
    content = withoutInit;
    changed = true;
  }

  if (!changed) return const [];
  crlf.content = content;
  crlf.save();
  logger.success('🧭 Updated: lib/main.dart');
  return [mainFile];
}

// ------------------------------------------------------------------
// 🧩 REVERT lib/core/di/injection_container.dart
// ------------------------------------------------------------------
List<File> _updateDependencyInjection(Directory libDir, Logger logger) {
  final diFile = File('${libDir.path}/core/di/injection_container.dart');
  if (!diFile.existsSync()) return const [];

  final crlf = _RawFile(diFile);
  var content = crlf.content;
  var changed = false;

  for (final importLine in [
    "import 'package:firebase_auth/firebase_auth.dart';",
    "import '../networks/firebase/firebase_auth_helper.dart';",
  ]) {
    final updated = _removeLineWithText(content, importLine);
    if (updated != null) {
      content = updated;
      changed = true;
    }
  }

  final withoutFunction = _removeDependencyFunction(content, 'firebase');
  if (withoutFunction != null) {
    content = withoutFunction;
    changed = true;
  }

  final withoutCall = _removeLineWithText(
    content,
    'await firebaseDependencies();',
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
// 🧩 REVERT auth's barrel export
// ------------------------------------------------------------------
List<File> _updateAuthExports(Directory libDir, Logger logger) {
  final exportsFile = File('${libDir.path}/features/auth/auth_exports.dart');
  if (!exportsFile.existsSync()) return const [];

  final crlf = _RawFile(exportsFile);
  final updated = _removeLineWithText(
    crlf.content,
    "export 'data/repository_impl/firebase_auth_repository_impl.dart';",
  );
  if (updated == null) return const [];

  crlf.content = updated;
  crlf.save();
  logger.success('🧱 Updated: auth_exports.dart');
  return [exportsFile];
}

// ------------------------------------------------------------------
// 🧩 HELPER FUNCTIONS
// ------------------------------------------------------------------

/// Removes the first line whose (trimmed) content starts with [prefix] —
/// used for pubspec/Gradle dependency lines whose version may have
/// drifted from what add_firebase originally pinned (e.g. after a
/// `flutter pub upgrade`).
String? _removeLineStartingWith(String content, String prefix) {
  final pattern = RegExp(
    '^[ \\t]*${RegExp.escape(prefix)}.*\$\\r?\\n?',
    multiLine: true,
  );
  if (!pattern.hasMatch(content)) return null;
  return content.replaceFirst(pattern, '');
}

/// Removes the first line whose trimmed content exactly equals [text].
String? _removeLineWithText(String content, String text) {
  final pattern = RegExp(
    '^[ \\t]*${RegExp.escape(text)}[ \\t]*\$\\r?\\n?',
    multiLine: true,
  );
  if (!pattern.hasMatch(content)) return null;
  return content.replaceFirst(pattern, '');
}

/// Removes a `Future<void> <camelName>Dependencies() async { ... }`
/// function, including any `///` doc comment lines directly above it.
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
