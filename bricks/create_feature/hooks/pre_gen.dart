import 'dart:io';
import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final logger = context.logger;
  final pageName = context.vars['page_name'] as String;

  final words = _splitWords(pageName);
  if (words.isEmpty) {
    logger.err('❌ Feature name cannot be empty.');
    exit(1);
  }

  // Computed once here so every template file under __brick__/ can just
  // reference {{fileName}}/{{className}}/{{camelName}} directly, instead of
  // repeating case-conversion mustache lambdas everywhere.
  final fileName = words.join('_');
  final className = words
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join();
  final camelName =
      words.first +
      words
          .skip(1)
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join();

  context.vars = {
    ...context.vars,
    'fileName': fileName,
    'className': className,
    'camelName': camelName,
  };

  final libDir = Directory('${Directory.current.path}/lib');
  if (!_isCleanArchitectureProvider(libDir)) {
    logger.err('❌ Could not detect Clean Architecture with Provider.');
    logger.info('💡 Please run setup_architecture first.');
    exit(1);
  }
}

bool _isCleanArchitectureProvider(Directory libDir) {
  if (!Directory('${libDir.path}/features').existsSync() ||
      !Directory('${libDir.path}/core/di').existsSync() ||
      !Directory('${libDir.path}/routes').existsSync()) {
    return false;
  }

  final features = Directory('${libDir.path}/features').listSync();
  if (features.isEmpty) return false;

  final firstFeature = features.first;
  if (firstFeature is! Directory) return false;

  return Directory('${firstFeature.path}/data').existsSync() &&
      Directory('${firstFeature.path}/domain').existsSync() &&
      Directory('${firstFeature.path}/presentation').existsSync();
}

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
