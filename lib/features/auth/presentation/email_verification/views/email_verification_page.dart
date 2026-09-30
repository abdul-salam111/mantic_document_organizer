import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../../../routes/routes_exports.dart';
import '../viewmodels/email_verification_viewmodel.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({super.key, required this.email});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.email.isEmpty) {
      return const _MissingVerificationEmailPage();
    }

    return ChangeNotifierProvider(
      create: (_) => sl<EmailVerificationViewModel>()..beginResendCooldown(),
      child: UnfocusWrapper(
        child: Scaffold(
          appBar: AppBar(title: const Text('Verify your email')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ListView(
                  children: [
                    Icon(
                      Icons.mark_email_read_outlined,
                      size: 64,
                      color: context.primary,
                    ),
                    heightBox(24),
                    Text('Check your inbox', style: context.headlineSmall),
                    heightBox(8),
                    Text(
                      'Enter the six-digit code we sent to ${widget.email}.',
                      style: context.bodyMedium.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    heightBox(32),
                    CustomTextFormField(
                      autofocus: true,
                      controller: _codeController,
                      label: 'Verification code',
                      hintText: '000000',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      validator: (value) {
                        if ((value ?? '').length != 6) {
                          return 'Enter the six-digit code from your email.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _verify(context),
                    ),
                    heightBox(24),
                    Consumer<EmailVerificationViewModel>(
                      builder: (context, vm, _) => CustomButton(
                        text: 'Verify email',
                        isLoading: vm.isLoading,
                        onPressed: vm.isLoading ? null : () => _verify(context),
                      ),
                    ),
                    heightBox(16),
                    Consumer<EmailVerificationViewModel>(
                      builder: (context, vm, _) => TextButton(
                        onPressed: vm.isLoading || !vm.canResend
                            ? null
                            : () => vm.resend(email: widget.email),
                        child: Text(
                          vm.canResend
                              ? 'Resend code'
                              : 'Resend code in ${vm.secondsUntilResend}s',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verify(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final viewModel = context.read<EmailVerificationViewModel>();
    await viewModel.verify(email: widget.email, code: _codeController.text);
    // verify() keeps the result in its state; only navigate after its request
    // succeeded, and never persist the sign-up password for an automatic login.
    if (!mounted) return;
    if (viewModel.isSuccess) {
      AppToastsUtils.success('Email verified. Sign in to continue.');
      AppNavigator.goNamed(RouteNames.signin, extra: widget.email);
    }
  }
}

class _MissingVerificationEmailPage extends StatelessWidget {
  const _MissingVerificationEmailPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => AppNavigator.goNamed(RouteNames.signup),
        child: const Text('Start sign-up to verify your email.'),
      ),
    ),
  );
}
