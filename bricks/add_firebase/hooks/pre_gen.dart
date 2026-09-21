import 'dart:io';
import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final logger = context.logger;

  final projectRoot = Directory.current.path;
  final libDir = Directory('$projectRoot/lib');
  final authDir = Directory('${libDir.path}/features/auth');

  // This brick implements the existing IAuthRepository/AuthEntity/
  // LoginUser/SignupUser contracts rather than generating a new feature,
  // so it only makes sense against a project that already has this
  // template's auth feature.
  if (!authDir.existsSync() ||
      !Directory('${authDir.path}/data').existsSync() ||
      !Directory('${authDir.path}/domain').existsSync()) {
    logger.err(
      '❌ lib/features/auth (with data/ and domain/) not found — this '
      'brick adds a Firebase-backed alternative to the existing REST auth '
      'feature, so that feature needs to exist first. Run '
      '`mason make setup_project_architecture` first if this is a fresh '
      'project.',
    );
    exit(1);
  }

  if (!File('${authDir.path}/domain/repositories/auth_repository.dart')
      .existsSync()) {
    logger.err(
      '❌ lib/features/auth/domain/repositories/auth_repository.dart not '
      'found — can\'t implement IAuthRepository without it.',
    );
    exit(1);
  }

  final firebaseImplFile = File(
    '${authDir.path}/data/repository_impl/firebase_auth_repository_impl.dart',
  );
  if (firebaseImplFile.existsSync()) {
    logger.err(
      '❌ ${firebaseImplFile.path} already exists — add_firebase has '
      'already been run on this project.',
    );
    exit(1);
  }

  if (!Directory('${libDir.path}/routes').existsSync() ||
      !Directory('${libDir.path}/core/di').existsSync() ||
      !File('${libDir.path}/main.dart').existsSync() ||
      !File('$projectRoot/pubspec.yaml').existsSync()) {
    logger.err(
      '❌ Could not find lib/routes, lib/core/di, lib/main.dart, or '
      'pubspec.yaml — this doesn\'t look like a project scaffolded from '
      'this template.',
    );
    exit(1);
  }

  final mainContent = File('${libDir.path}/main.dart').readAsStringSync();
  if (!mainContent.contains('await setupLocator();')) {
    logger.err(
      '❌ lib/main.dart doesn\'t contain the expected '
      '"await setupLocator();" line — this brick inserts '
      '"await Firebase.initializeApp();" right before it, and can\'t do '
      'that safely if main.dart has been restructured.',
    );
    exit(1);
  }
}
