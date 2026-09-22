import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';
import 'route_paths.dart';
import '../core/theme/theme_exports.dart';
import '../core/widgets/widgets_exports.dart';
import '../features/auth/auth_exports.dart';
import '../features/add_document/add_document_exports.dart';
import '../features/navbar/navbar_exports.dart';
import '../features/onboarding/onboarding_exports.dart';
import '../features/splash/splash_exports.dart';
// GENERATED_IMPORTS_START

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
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const NavbarView(),
      ),
      GoRoute(
        path: RoutePaths.addDocument,
        name: RouteNames.addDocument,
        builder: (context, state) => const AddDocumentView(),
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

      // GENERATED_ROUTES_START
      // GENERATED_ROUTES_END
    ],
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
                Text('Page not found', style: context.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  "We couldn't find \"${state.uri}\".",
                  textAlign: TextAlign.center,
                  style: context.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Go back',
                  onPressed: () => context.goNamed(RouteNames.signin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
