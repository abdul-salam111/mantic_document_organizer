import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/categories/presentation/add_category/view/add_category_view.dart';
import 'route_names.dart';
import 'route_paths.dart';
import '../core/localization/localization_exports.dart';
import '../core/theme/theme_exports.dart';
import '../core/widgets/widgets_exports.dart';
import '../features/auth/auth_exports.dart';
import '../features/backup/backup_exports.dart';

import '../features/documents/presentation/add_document/add_document_exports.dart';
import '../features/categories/presentation/manage_categories/manage_categories_exports.dart';
import '../features/navbar/navbar_exports.dart';
import '../features/onboarding/onboarding_exports.dart';
import '../features/settings/settings_exports.dart';
import '../features/splash/splash_exports.dart';
import '../features/documents/presentation/category_documents/category_documents_exports.dart';
import '../features/documents/presentation/document_viewer/document_viewer_exports.dart';
import '../features/documents/presentation/trash/trash_exports.dart';
import '../features/documents/presentation/expiring_soon/expiring_soon_exports.dart';
import '../features/bulk_import/bulk_import_exports.dart';

// GENERATED_IMPORTS_START

import '../features/ai_assistant/ai_assistant_exports.dart';

// GENERATED_IMPORTS_END

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Safe navigation methods
  static void goNamed(String name, {Object? extra}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      context.goNamed(name, extra: extra);
    }
  }

  static void pushNamed(String name, {Object? extra}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      context.pushNamed(name, extra: extra);
    }
  }

  static void replaceTo(String name, {Object? extra}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      context.replaceNamed(name, extra: extra);
    }
  }

  static void pop() {
    final context = navigatorKey.currentContext;
    if (context != null && context.canPop()) {
      context.pop();
    }
  }
}

class AppRoutes {
  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.initialRoute,
    navigatorKey: AppNavigator.navigatorKey,
    errorBuilder: (context, state) => _RouteErrorPage(state: state),
    routes: [
      GoRoute(
        path: RoutePaths.signin,
        name: RouteNames.signin,
        builder: (context, state) => const SigninPage(),
      ),
      GoRoute(
        path: RoutePaths.signup,
        name: RouteNames.signup,
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: RoutePaths.backupSetup,
        name: RouteNames.backupSetup,
        builder: (context, state) => const BackupSetupPage(),
      ),
      GoRoute(
        path: RoutePaths.verifyEmail,
        name: RouteNames.verifyEmail,
        builder: (context, state) => EmailVerificationPage(
          email: state.extra is String ? state.extra! as String : '',
        ),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => NavbarView(
          initialIndex: state.extra is int ? state.extra! as int : 0,
        ),
      ),
      GoRoute(
        path: RoutePaths.addDocument,
        name: RouteNames.addDocument,
        builder: (context, state) {
          final extra = state.extra;
          if (extra case (DocumentItem document, AttachmentSource source)) {
            return AddDocumentView(
              editingDocument: document,
              initialSource: source,
            );
          }
          return AddDocumentView(
            initialCategory: extra is CategoryItem ? extra : null,
            editingDocument: extra is DocumentItem ? extra : null,
            initialSharedFilePaths: extra is List<String> ? extra : null,
            initialSource: extra is AttachmentSource ? extra : null,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingView(),
      ),
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsView(),
      ),
      GoRoute(
        path: RoutePaths.addCategory,
        name: RouteNames.addCategory,
        builder: (context, state) =>
            AddCategoryView(category: state.extra as CategoryItem?),
      ),
      GoRoute(
        path: RoutePaths.manageCategories,
        name: RouteNames.manageCategories,
        builder: (context, state) => const ManageCategoriesView(),
      ),
      GoRoute(
        path: RoutePaths.categoryDocuments,
        name: RouteNames.categoryDocuments,
        builder: (context, state) =>
            CategoryDocumentsView(category: state.extra as CategoryItem),
      ),
      GoRoute(
        path: RoutePaths.documentViewer,
        name: RouteNames.documentViewer,
        builder: (context, state) =>
            DocumentViewerView(document: state.extra as DocumentItem),
      ),
      GoRoute(
        path: RoutePaths.filePreview,
        name: RouteNames.filePreview,
        builder: (context, state) {
          final (filePaths, initialIndex) = state.extra as (List<String>, int);
          return FilePreviewView(
            filePaths: filePaths,
            initialIndex: initialIndex,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.trash,
        name: RouteNames.trash,
        builder: (context, state) => const TrashView(),
      ),
      GoRoute(
        path: RoutePaths.expiringSoon,
        name: RouteNames.expiringSoon,
        builder: (context, state) => const ExpiringSoonView(),
      ),
      GoRoute(
        path: RoutePaths.bulkImport,
        name: RouteNames.bulkImport,
        builder: (context, state) => const BulkImportIntroView(),
      ),
      GoRoute(
        path: RoutePaths.bulkImportReview,
        name: RouteNames.bulkImportReview,
        builder: (context, state) => state.extra is BulkImportViewModel
            ? BulkImportReviewView(
                viewModel: state.extra! as BulkImportViewModel,
              )
            : const BulkImportIntroView(),
      ),

      // GENERATED_ROUTES_START
      GoRoute(
        path: RoutePaths.aiAssistant,
        name: RouteNames.aiAssistant,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AiAssistantView(),
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: _fadeScaleTransition,
        ),
      ),
      // GENERATED_ROUTES_END
    ],
  );
}

/// Fade + subtle scale-up used for [RouteNames.aiAssistant] — reads like
/// the search field expanding into the chat screen instead of go_router's
/// default platform slide, which feels like an unrelated new page rather
/// than a continuation of the tap that opened it.
Widget _fadeScaleTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
  return FadeTransition(
    opacity: curved,
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
      child: child,
    ),
  );
}

/// Shown for any unmatched route/deep link instead of go_router's default,
/// unstyled error page. `goNamed`/`pushNamed` calls with an unknown *name*
/// (as opposed to an unmatched path) throw a `GoError` synchronously and
/// don't reach this builder — this only covers unresolvable paths.
class _RouteErrorPage extends StatelessWidget {
  final GoRouterState state;

  const _RouteErrorPage({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).pageNotFound,
                  style: context.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(
                    context,
                  ).pageNotFoundSubtitle(state.uri.toString()),
                  textAlign: TextAlign.center,
                  style: context.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: AppLocalizations.of(context).goBack,
                  onPressed: () => context.goNamed(RouteNames.home),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
