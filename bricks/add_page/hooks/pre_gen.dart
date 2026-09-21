import 'dart:io';
import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final logger = context.logger;

  final featureName = context.vars['feature_name'] as String;
  final pageName = context.vars['page_name'] as String;

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
  final featureClassName = _toPascalCase(featureWords);

  final fileName = pageWords.join('_');
  final className = _toPascalCase(pageWords);
  final camelName = _toCamelCase(pageWords);

  context.vars = {
    ...context.vars,
    'featureFileName': featureFileName,
    'featureClassName': featureClassName,
    'fileName': fileName,
    'className': className,
    'camelName': camelName,
  };

  final libDir = Directory('${Directory.current.path}/lib');
  final featureDir = Directory('${libDir.path}/features/$featureFileName');

  if (!featureDir.existsSync() ||
      !Directory('${featureDir.path}/data').existsSync() ||
      !Directory('${featureDir.path}/domain').existsSync() ||
      !Directory('${featureDir.path}/presentation').existsSync()) {
    logger.err(
      '❌ Feature "$featureFileName" doesn\'t exist (or is missing '
      'data/domain/presentation) under lib/features/. Use create_feature to '
      'scaffold a new feature module first, then add_page to add more pages '
      'to it.',
    );
    exit(1);
  }

  final pageDir = Directory('${featureDir.path}/presentation/$fileName');
  if (pageDir.existsSync()) {
    logger.err(
      '❌ lib/features/$featureFileName/presentation/$fileName already '
      'exists. Pick a different page name, or delete it first if you meant '
      'to regenerate it.',
    );
    exit(1);
  }

  if (!Directory('${libDir.path}/routes').existsSync() ||
      !Directory('${libDir.path}/core/di').existsSync()) {
    logger.err(
      '❌ Could not find lib/routes or lib/core/di — this doesn\'t look '
      'like a project scaffolded from this template.',
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
