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
                const Positioned(
                  top: 28,
                  left: 24,
                  right: 24,
                  child: Center(child: AppLogo(height: 120, width: 120)),
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
                Positioned.fill(
                  top: 130,
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: SingleChildScrollView(
        padding: const .fromLTRB(24, 20, 24, 28),
        child: AutofillGroup(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Text(
                  'Create your account',
                  style: context.headlineSmall.copyWith(fontWeight: .w700),
                  textAlign: .center,
                ),
                const SizedBox(height: 6),
                Text(
                  'A secure home for the documents that matter.',
                  style: context.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CustomTextFormField(
                  prefixIcon: Iconsax.user,
                  hintText: 'Your full name',
                  controller: nameController,
                  label: 'Full name',
                  validator: Validator.validateName,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: 18),
                CustomTextFormField(
                  prefixIcon: Iconsax.sms,
                  hintText: 'you@example.com',
                  controller: emailController,
                  label: 'Email address',
                  validator: Validator.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.email,
                    AutofillHints.username,
                  ],
                ),
                const SizedBox(height: 18),
                CustomTextFormField(
                  hintText: 'Create a strong password',
                  prefixIcon: Iconsax.lock,
                  controller: passwordController,
                  obscureText: true,
                  label: 'Password',
                  validator: Validator.validatePassword,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 26),
                Consumer<SignupViewModel>(
                  builder: (context, vm, _) => CustomButton(
                    radius: 12,
                    onPressed: vm.isAnyLoading ? null : () => onSubmit(vm),
                    isLoading: vm.isEmailLoading,
                    text: 'Create account',
                  ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                Consumer<SignupViewModel>(
                  builder: (context, vm, _) {
                    final loading = vm.isGoogleLoading;
                    return SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: vm.isAnyLoading ? null : vm.signUpWithGoogle,
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
                  Consumer<SignupViewModel>(
                    builder: (context, vm, _) => SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: vm.isAnyLoading ? null : vm.signUpWithApple,
                        icon: const Icon(Icons.apple),
                        label: Text(
                          vm.isAppleLoading
                              ? 'Connecting to Apple…'
                              : 'Continue with Apple',
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => AppNavigator.goNamed(RouteNames.signin),
                  child: const Text('Already have an account? Sign in'),
                ),
              ],
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
