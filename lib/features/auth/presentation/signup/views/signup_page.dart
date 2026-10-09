import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/constants_exports.dart';
import '../../../../../core/di/di_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../../../routes/routes_exports.dart';
import '../viewmodels/signup_viewmodel.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(SignupViewModel vm) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await vm.signup(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (vm.user != null) TextInput.finishAutofillContext(shouldSave: true);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    return ChangeNotifierProvider(
      create: (_) => sl<SignupViewModel>(),
      child: UnfocusWrapper(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Stack(
              children: [
                const _SignupBackdrop(),
                // Logo + title stay anchored together at the top, in
                // normal flow — only the space below them (the form) is
                // free to grow/center on a tall screen, via the Expanded
                // below. Fixed pixel offsets here would either overlap
                // this text on a narrow screen or leave it stranded far
                // from the logo on a tall one.
                Column(
                  children: [
                    const SizedBox(height: 28),
                    const Center(child: AppLogo(height: 120, width: 120)),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            'Create your account',
                            style: context.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'A secure home for the documents that matter.',
                            style: context.bodyMedium.copyWith(
                              color: context.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.only(bottom: keyboardHeight),
                        child: _SignupSheet(
                          formKey: _formKey,
                          nameController: _nameController,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          onSubmit: _submit,
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: IconButton.filledTonal(
                    tooltip: 'Back',
                    onPressed: () => AppNavigator.goNamed(RouteNames.signin),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF08254F),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.arrow_back),
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

class _SignupSheet extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Future<void> Function(SignupViewModel) onSubmit;
  const _SignupSheet({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    // Below this width (the smallest logical screen size this app
    // targets), the field captions compete too much with the hint text
    // for vertical space — drop them and rely on the hint + prefix icon.
    final showFieldLabels = context.screenWidth >= 360;
    // On a tall screen (e.g. the iPhone 17 Pro Max simulator at 956pt vs.
    // the Tecno reference device's 800dp), the fields otherwise end up
    // crowded together above all the leftover centered space below them
    // — give them more breathing room between each other too.
    final fieldGap = context.screenHeight > 800 ? 20.0 : 14.0;
    final buttonGap = context.screenHeight > 800 ? 40.0 : 16.0;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      // On a tall screen the form is shorter than the space available
      // below the logo, which otherwise leaves it stuck to the top with
      // a dead gap underneath. Centering it vertically (when it's shorter
      // than the viewport — LayoutBuilder's constraints here, captured
      // before SingleChildScrollView makes the main axis unbounded) turns
      // that gap into breathing room above and below instead.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const .fromLTRB(24, 20, 24, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: AutofillGroup(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: .min,
                    crossAxisAlignment: .stretch,
                    children: [
                      CustomTextFormField(
                        prefixIcon: Iconsax.user,
                        hintText: 'Your full name',
                        fillColor: Colors.transparent,
                        controller: nameController,
                        label: showFieldLabels ? 'Full name' : null,
                        validator: Validator.validateName,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        autofillHints: const [AutofillHints.name],
                      ),
                      SizedBox(height: fieldGap),
                      CustomTextFormField(
                        prefixIcon: Iconsax.sms,
                        hintText: 'you@example.com',
                        fillColor: Colors.transparent,
                        controller: emailController,
                        label: showFieldLabels ? 'Email address' : null,
                        validator: Validator.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        autofillHints: const [
                          AutofillHints.email,
                          AutofillHints.username,
                        ],
                      ),
                      SizedBox(height: fieldGap),
                      CustomTextFormField(
                        hintText: 'Create a strong password',
                        prefixIcon: Iconsax.lock,
                        fillColor: Colors.transparent,
                        controller: passwordController,
                        obscureText: true,
                        label: showFieldLabels ? 'Password' : null,
                        validator: Validator.validatePassword,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        autofillHints: const [AutofillHints.newPassword],
                      ),
                       SizedBox(height:   buttonGap),
                      Consumer<SignupViewModel>(
                        builder: (context, vm, _) => CustomButton(
                          radius: 12,
                          size: const Size(double.infinity, 44),
                          onPressed: vm.isAnyLoading
                              ? null
                              : () => onSubmit(vm),
                          isLoading: vm.isEmailLoading,
                          text: 'Create account',
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'or sign up with',
                              style: context.bodySmall.copyWith(
                                color: context.textSecondary,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Consumer<SignupViewModel>(
                        builder: (context, vm, _) => Row(
                          children: [
                            Expanded(
                              child: SocialSignInButton(
                                icon: AppIcons.google,
                                label: 'Continue with Google',
                                loading: vm.isGoogleLoading,
                                onPressed: vm.isAnyLoading
                                    ? null
                                    : vm.signUpWithGoogle,
                              ),
                            ),
                            if (Platform.isIOS) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: SocialSignInButton(
                                  icon: AppIcons.apple,
                                  label: 'Continue with Apple',
                                  loading: vm.isAppleLoading,
                                  tintIcon: true,
                                  onPressed: vm.isAnyLoading
                                      ? null
                                      : vm.signUpWithApple,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            AppNavigator.goNamed(RouteNames.signin),
                        child: const Text('Already have an account? Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignupBackdrop extends StatelessWidget {
  const _SignupBackdrop();
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
