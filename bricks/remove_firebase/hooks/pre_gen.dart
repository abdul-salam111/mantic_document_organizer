import 'dart:io';
import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final logger = context.logger;
  final confirm = context.vars['confirm'] as bool? ?? false;

  final libDir = Directory('${Directory.current.path}/lib');
  final firebaseDir = Directory('${libDir.path}/core/networks/firebase');

  if (!firebaseDir.existsSync()) {
    logger.err(
      '❌ ${firebaseDir.path} doesn\'t exist — add_firebase doesn\'t look '
      'like it has been run on this project. Nothing to remove.',
    );
    exit(1);
  }

  // Hard stop (not just a warning) if IAuthRepository is currently wired
  // to FirebaseAuthRepositoryImpl — deleting that class out from under an
  // active registration would leave injection_container.dart referencing
  // an undefined type, breaking the build. add_firebase never wires this
  // up itself, but the developer may have made the one-line swap it
  // documents.
  final diFile = File('${libDir.path}/core/di/injection_container.dart');
  if (diFile.existsSync()) {
    // Strip `///` doc-comment lines before checking — add_firebase's own
    // generated comment block quotes this exact registration line as an
    // example, which would otherwise false-positive this check every
    // time, even when Firebase was never actually wired up as active.
    final codeOnly = diFile
        .readAsStringSync()
        .split(RegExp(r'\r?\n'))
        .where((line) => !line.trim().startsWith('///'))
        .join('\n');
    if (codeOnly.contains('FirebaseAuthRepositoryImpl(firebaseAuthHelper: sl())')) {
      logger.err(
        '❌ IAuthRepository is currently registered as '
        'FirebaseAuthRepositoryImpl in injection_container.dart — removing '
        'Firebase now would break the build. Switch authDependencies() '
        'back to:\n'
        '     AuthRepositoryImpl(dataSource: sl())\n'
        'first, then re-run this brick.',
      );
      exit(1);
    }
  }

  if (!confirm) {
    logger.err(
      '❌ Not deleting anything — pass --confirm to actually remove '
      'Firebase Auth. This will delete:\n'
      '   lib/core/networks/firebase/\n'
      '   lib/core/networks/exceptions/firebase_auth_exceptions.dart\n'
      '   lib/features/auth/data/repository_impl/firebase_auth_repository_impl.dart\n'
      'and revert the pubspec.yaml/Gradle/main.dart/injection_container.dart '
      'wiring add_firebase added.',
    );
    exit(1);
  }
}
