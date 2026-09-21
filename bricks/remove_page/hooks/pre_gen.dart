import 'dart:io';
import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final logger = context.logger;

  final featureName = context.vars['feature_name'] as String;
  final pageName = context.vars['page_name'] as String;
  final confirm = context.vars['confirm'] as bool? ?? false;

  final featureWords = _splitWords(featureName);
  final pageWords = _splitWords(pageName);
  if (featureWords.isEmpty) {
    logger.err('❌ Feature name cannot be empty.');
    exit(1);
  }
  if (pageWords.isEmpty) {
    logger.err('❌ Page name cannot be empty.');
    exit(1);
  }

  final featureFileName = featureWords.join('_');
  final fileName = pageWords.join('_');
  final className = _toPascalCase(pageWords);
  final camelName = _toCamelCase(pageWords);

  context.vars = {
    ...context.vars,
    'featureFileName': featureFileName,
    'fileName': fileName,
    'className': className,
    'camelName': camelName,
  };

  final libDir = Directory('${Directory.current.path}/lib');
  final pageDir = Directory(
    '${libDir.path}/features/$featureFileName/presentation/$fileName',
  );

  if (!pageDir.existsSync()) {
    logger.err(
      '❌ ${pageDir.path} doesn\'t exist — nothing to remove. Check the '
      'feature/page names (e.g. `mason make remove_page --feature_name '
      'auth --page_name change_password`).',
    );
    exit(1);
  }

  // Best-effort safety net: warn about anything OUTSIDE this page's own
  // folder that still references it, so a confirmed deletion doesn't
  // silently leave a dangling import somewhere unexpected. Doesn't block
  // — `confirm` is the actual gate — just makes the blast radius visible
  // before it happens.
  //
  // Excludes the files post_gen.dart itself auto-cleans (routes,
  // injection_container.dart, the feature's own barrel export) — those
  // aren't "manual fixing", they're handled by this very brick a moment
  // later, so warning about them here would just be noise.
  final autoFixedFiles = {
    'routes/route_names.dart',
    'routes/route_paths.dart',
    'routes/app_router.dart',
    'core/di/injection_container.dart',
    'features/$featureFileName/${featureFileName}_exports.dart',
  };

  final externalRefs = _findExternalReferences(
    libDir,
    'presentation/$fileName/',
    excludeDir: pageDir,
  ).where((path) => !autoFixedFiles.any((f) => path.endsWith(f))).toList();
  if (externalRefs.isNotEmpty) {
    logger.warn(
      '⚠️  These files reference presentation/$fileName/ and will need '
      'manual fixing after this page is removed:',
    );
    for (final path in externalRefs) {
      logger.warn('   - $path');
    }
  }

  if (!confirm) {
    logger.err(
      '❌ Not deleting anything — pass --confirm to actually remove '
      '"$fileName" from the "$featureFileName" feature. This will delete:\n'
      '   lib/features/$featureFileName/presentation/$fileName/\n'
      '   lib/features/$featureFileName/domain/usecases/${fileName}_usecase.dart\n'
      'and remove its routes/DI/barrel-export wiring.',
    );
    exit(1);
  }
}

String _toPascalCase(List<String> words) =>
    words.map((word) => word[0].toUpperCase() + word.substring(1)).join();

String _toCamelCase(List<String> words) =>
    words.first +
    words.skip(1).map((word) => word[0].toUpperCase() + word.substring(1)).join();

// Splits arbitrary input (snake_case, camelCase, PascalCase,
// space/hyphen-separated, or any mix) into lowercase words.
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

/// Scans every .dart file under [libDir] (except [excludeDir]) for a
/// literal occurrence of [needle], returning the relative paths of any
/// that contain it.
List<String> _findExternalReferences(
  Directory libDir,
  String needle,
  {required Directory excludeDir}
) {
  final matches = <String>[];
  final excludePath = excludeDir.absolute.path;

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.absolute.path.startsWith(excludePath)) continue;

    final content = entity.readAsStringSync();
    if (content.contains(needle)) {
      matches.add(entity.path.replaceAll('\\', '/'));
    }
  }
  return matches;
}
