import 'package:flutter/material.dart';
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
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<SignupViewModel>(),
      child: UnfocusWrapper(
        child: Scaffold(
          body: Stack(
            children: [
              Form(
                key: formKey,
                child: Padding(
                  padding: .all(12),
                  child: ListView(
                    children: [
                      heightBox(context.screenHeight * 0.05),
                      AppLogo(),
                      heightBox(context.screenHeight * 0.05),
                      CustomTextFormField(
                        prefixIcon: Iconsax.user,
                        hintText: "Enter your name",
                        controller: _nameController,
                        label: "Name",
                        validator: Validator.validateName,
                        keyboardType: TextInputType.name,
                      ),
                      heightBox(20),
                      CustomTextFormField(
                        prefixIcon: Iconsax.sms,
                        hintText: "Enter your email",
                        controller: _emailController,
                        label: "Email",
                        validator: Validator.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      heightBox(20),
                      CustomTextFormField(
                        hintText: "Enter your Password",
                        prefixIcon: Iconsax.lock,
                        controller: _passwordController,
                        obscureText: true,
                        label: "Password",
                        validator: Validator.validatePassword,
                        keyboardType: TextInputType.visiblePassword,
                      ),
                      heightBox(40),
                      Consumer<SignupViewModel>(
                        builder: (context, vm, _) {
                          return CustomButton(
                            radius: 10,
                            onPressed: vm.isLoading
                                ? null
                                : () {
                                    if (!(formKey.currentState?.validate() ??
                                        false)) {
                                      return;
                                    }
                                    vm.signup(
                                      _nameController.text,
                                      _emailController.text,
                                      _passwordController.text,
                                    );
                                  },
                            isLoading: vm.isLoading,
                            text: "Sign Up",
                          );
                        },
                      ),
                      heightBox(16),
                      TextButton(
                        onPressed: () =>
                            AppNavigator.goNamed(RouteNames.signin),
                        child: const Text('Already have an account? Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: SafeArea(
                  child: Consumer<ThemeController>(
                    builder: (context, themeController, _) {
                      return IconButton(
                        tooltip: 'Toggle theme',
                        icon: Icon(
                          themeController.isDarkMode
                              ? Iconsax.sun_1
                              : Iconsax.moon,
                        ),
                        onPressed: () => themeController.toggleTheme(context),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
