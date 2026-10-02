import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/constants_exports.dart';
import '../../../../../core/di/di_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../../../routes/routes_exports.dart';
import '../viewmodels/signin_viewmodel.dart';

class SigninPage extends StatefulWidget {
  final String? initialEmail;
  const SigninPage({super.key, this.initialEmail});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(SigninViewModel vm) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await vm.signin(_emailController.text.trim(), _passwordController.text);
    if (vm.user != null) TextInput.finishAutofillContext(shouldSave: true);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    return ChangeNotifierProvider(
      create: (_) => sl<SigninViewModel>(),
      child: UnfocusWrapper(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Stack(
              children: [
                const _AuthBackdrop(),
                Positioned(
                  top: 28,
                  left: 24,
                  right: 24,
                  child: Column(
                    children: [const AppLogo(height: 120, width: 120)],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.only(bottom: keyboardHeight),
                    child: _SigninSheet(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      onSubmit: _submit,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SigninSheet extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Future<void> Function(SigninViewModel) onSubmit;

  const _SigninSheet({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Material(
        color: colors.surface,
        elevation: 16,
        borderRadius: const .vertical(top: Radius.circular(32)),
        child: SingleChildScrollView(
          padding: const .fromLTRB(24, 12, 24, 28),
          child: AutofillGroup(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: .circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome back',
                    style: context.headlineSmall.copyWith(fontWeight: .w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to continue organizing with confidence.',
                    style: context.bodyMedium.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextFormField(
                    prefixIcon: Iconsax.sms,
                    hintText: 'you@example.com',
                    controller: emailController,
                    label: 'Email address',
                    validator: Validator.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                  ),
                  const SizedBox(height: 18),
                  CustomTextFormField(
                    hintText: 'Enter your password',
                    prefixIcon: Iconsax.lock,
                    controller: passwordController,
                    obscureText: true,
                    label: 'Password',
                    validator: Validator.validatePassword,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                  ),
                  const SizedBox(height: 26),
                  Consumer<SigninViewModel>(
                    builder: (context, vm, _) => CustomButton(
                      radius: 12,
                      onPressed: vm.isAnyLoading ? null : () => onSubmit(vm),
                      isLoading: vm.isEmailLoading,
                      text: 'Sign In',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or continue with',
                          style: context.bodySmall.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer<SigninViewModel>(
                    builder: (context, vm, _) {
                      final loading = vm.isGoogleLoading;
                      return SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: vm.isAnyLoading
                              ? null
                              : vm.signInWithGoogle,
                          icon: loading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Image.asset(
                                  AppIcons.google,
                                  width: 20,
                                  height: 20,
                                ),
                          label: Text(
                            loading
                                ? 'Connecting to Google…'
                                : 'Continue with Google',
                          ),
                        ),
                      );
                    },
                  ),
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 12),
                    Consumer<SigninViewModel>(
                      builder: (context, vm, _) => SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: vm.isAnyLoading
                              ? null
                              : vm.signInWithApple,
                          icon: Image.asset(
                            AppIcons.apple,
                            width: 20,
                            height: 20,
                            color: IconTheme.of(context).color,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                          label: Text(
                            vm.isAppleLoading
                                ? 'Connecting to Apple…'
                                : 'Continue with Apple',
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => AppNavigator.goNamed(RouteNames.signup),
                    child: const Text("Don't have an account? Sign up"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();
  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF08254F);
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -110,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .11),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .07),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
