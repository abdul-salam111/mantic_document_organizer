import 'package:flutter/material.dart';

import '../../../core/di/di_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../viewmodel/onboarding_viewmodel.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<OnboardingViewModel>(),
      child: Consumer<OnboardingViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: .topLeft,
                  end: .bottomRight,
                  colors: [
                    context.primaryDark,
                    context.primary,
                    context.primaryLight,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const .symmetric(horizontal: 28, vertical: 20),
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Column(
                        children: [
                          const Spacer(),
                          const _HeroGraphic(),
                          const Spacer(),
                          Text(
                            'MANTIC',
                            style: context.labelLarge.copyWith(
                              color: context.white,
                              fontWeight: .bold,
                              letterSpacing: 4,
                            ),
                          ),
                          heightBox(18),
                          Text(
                            'All Your Documents,\nBeautifully Organized',
                            textAlign: .center,
                            style: context.headlineMedium.copyWith(
                              color: context.white,
                              fontWeight: .bold,
                              height: 1.25,
                            ),
                          ),
                          heightBox(12),
                          Text(
                            'Scan, categorize, and find every important '
                            'document in seconds — all stored securely on '
                            'your device, even offline.',
                            textAlign: .center,
                            style: context.bodyMedium.copyWith(
                              color: context.white.withValues(alpha: 0.85),
                              height: 1.5,
                            ),
                          ),
                          heightBox(32),
                          CustomButton(
                            text: 'Get Started',
                            backgroundColor: context.white,
                            textColor: context.primary,
                            radius: 16,
                            onPressed: vm.completeOnboarding,
                          ),
                          heightBox(14),
                          Text(
                            'No sign-in required — your documents stay on '
                            'this device.',
                            textAlign: .center,
                            style: context.labelSmall.copyWith(
                              color: context.white.withValues(alpha: 0.7),
                            ),
                          ),
                          heightBox(4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroGraphic extends StatelessWidget {
  const _HeroGraphic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: .center,
        children: [
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: .circle,
              color: context.white.withValues(alpha: 0.08),
            ),
          ),
          Container(
            width: 202,
            height: 202,
            decoration: BoxDecoration(
              shape: .circle,
              color: context.white.withValues(alpha: 0.12),
            ),
          ),
          Transform.rotate(
            angle: -0.22,
            child: _DocCard(color: context.white.withValues(alpha: 0.55)),
          ),
          Transform.rotate(
            angle: 0.16,
            child: _DocCard(color: context.white.withValues(alpha: 0.85)),
          ),
          Container(
            width: 104,
            height: 104,
            alignment: .center,
            decoration: BoxDecoration(
              shape: .circle,
              color: context.white,
              boxShadow: [
                BoxShadow(
                  color: context.black.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FaIcon(
              FontAwesomeIcons.folderTree,
              size: 46,
              color: context.primary,
            ),
          ),
          Positioned(
            top: 4,
            right: 14,
            child: _AccentBadge(icon: FontAwesomeIcons.circleCheck),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: _AccentBadge(icon: FontAwesomeIcons.shieldHalved),
          ),
        ],
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final Color color;

  const _DocCard({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 118,
      padding: .all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: .circular(16),
        boxShadow: [
          BoxShadow(
            color: context.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: .start,
        mainAxisAlignment: .center,
        children: [
          _line(context, width: double.infinity),
          heightBox(8),
          _line(context, width: 40),
          heightBox(8),
          _line(context, width: 56),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, {required double width}) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: context.black.withValues(alpha: 0.12),
        borderRadius: .circular(3),
      ),
    );
  }
}

class _AccentBadge extends StatelessWidget {
  final FaIconData icon;

  const _AccentBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: .center,
      decoration: BoxDecoration(
        shape: .circle,
        color: context.white,
        boxShadow: [
          BoxShadow(
            color: context.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FaIcon(icon, size: 15, color: context.primary),
    );
  }
}
