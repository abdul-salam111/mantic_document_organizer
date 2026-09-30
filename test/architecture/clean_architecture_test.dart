import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

final _directives = RegExp(
  r'''^(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);
const _features = ['categories', 'documents', 'favorites'];

Iterable<File> _files(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'));

Uri? _resolve(File source, String uri) {
  if (uri.startsWith('package:mantic_doc_org/')) {
    return File(
      'lib/${uri.substring('package:mantic_doc_org/'.length)}',
    ).absolute.uri;
  }
  if (uri.contains(':')) return null;
  return source.absolute.uri.resolve(uri);
}

void main() {
  test('feature domain dependencies remain pure Dart, transitively', () {
    final visited = <String>{};
    void inspect(File file) {
      if (!visited.add(file.absolute.path)) return;
      for (final match in _directives.allMatches(file.readAsStringSync())) {
        final uri = match[1]!;
        if (uri.startsWith('dart:')) {
          expect(uri, isNot(anyOf('dart:ui', 'dart:io')), reason: file.path);
          continue;
        }
        final resolved = _resolve(file, uri);
        expect(
          resolved,
          isNotNull,
          reason: '${file.path} imports SDK/package $uri',
        );
        final dependency = File.fromUri(resolved!);
        expect(
          dependency.path,
          contains('/domain/'),
          reason: '${file.path} -> $uri',
        );
        inspect(dependency);
      }
    }

    for (final feature in _features) {
      for (final file in _files('lib/features/$feature/domain')) {
        inspect(file);
      }
    }
  });

  test('data never imports presentation, including through core helpers', () {
    final visited = <String>{};
    void inspect(File file) {
      if (!visited.add(file.absolute.path)) return;
      for (final match in _directives.allMatches(file.readAsStringSync())) {
        final resolved = _resolve(file, match[1]!);
        if (resolved == null) continue;
        final dependency = File.fromUri(resolved);
        expect(
          dependency.path,
          isNot(matches(r'/(presentation|view|views|viewmodel|viewmodels)/')),
          reason: '${file.path} -> ${dependency.path}',
        );
        inspect(dependency);
      }
    }

    for (final feature in _features) {
      for (final file in _files('lib/features/$feature/data')) {
        inspect(file);
      }
    }
  });

  test('presentation does not import storage/network implementations', () {
    for (final feature in _features) {
      for (final file in _files('lib/features/$feature/presentation')) {
        for (final match in _directives.allMatches(file.readAsStringSync())) {
          expect(
            match[1],
            isNot(
              matches(
                r'/data/|core/(database|networks|ai|ocr|notifications)/|package:(sqflite|dio|path_provider|file_picker|image_picker|flutter_doc_scanner|content_resolver|share_plus)/',
              ),
            ),
            reason: file.path,
          );
        }
      }
    }
  });
}
