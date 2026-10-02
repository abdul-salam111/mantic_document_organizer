import 'package:flutter/material.dart';

import '../../../core/di/di_exports.dart';
import '../../../core/localization/localization_exports.dart';
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
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
              color: context.primary,
              child: Stack(
                children: [
                  Positioned(
                    top: -110,
                    right: -100,
                    child: _BackgroundOrb(size: 270, opacity: 0.09),
                  ),
                  Positioned(
                    bottom: -140,
                    left: -120,
                    child: _BackgroundOrb(size: 300, opacity: 0.06),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const .symmetric(horizontal: 28, vertical: 20),
                      child: FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: _slide,
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Dockitly',
                                  style: context.headlineSmall.copyWith(
                                    color: context.white,
                                    fontWeight: .w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const _HeroGraphic(),
                              const Spacer(),
                              Text(
                                AppLocalizations.of(context).onboardingHeadline,
                                textAlign: .center,
                                style: context.headlineSmall.copyWith(
                                  color: context.white,
                                  fontWeight: .w800,
                                  height: 1.18,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              heightBox(14),
                              Text(
                                AppLocalizations.of(context).onboardingSubtitle,
                                textAlign: .center,
                                style: context.bodySmall.copyWith(
                                  color: context.white.withValues(alpha: 0.85),
                                  height: 1.45,
                                ),
                              ),
                              heightBox(30),
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: .circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.black.withValues(
                                        alpha: 0.14,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: vm.completeOnboarding,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.white,
                                    foregroundColor: context.primary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: .circular(18),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: .center,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        ).onboardingGetStarted,
                                        style: context.labelLarge.copyWith(
                                          color: context.primary,
                                          fontWeight: .w800,
                                        ),
                                      ),
                                      widthBox(8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: context.primary,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
      width: 300,
      height: 300,
      child: Stack(
        alignment: .center,
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: .circle,
              color: context.white.withValues(alpha: 0.08),
            ),
          ),
          Container(
            width: 196,
            height: 196,
            decoration: BoxDecoration(
              shape: .circle,
              color: context.white.withValues(alpha: 0.12),
            ),
          ),
          Container(
            width: 128,
            height: 128,
            alignment: .center,
            decoration: BoxDecoration(
              borderRadius: .circular(30),
              color: context.white.withValues(alpha: 0.14),
              border: Border.all(color: context.white.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: context.black.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const AppLogo(
              height: 104,
              width: 104,
            ).withRoundedCorners(24),
          ),
          Positioned(
            top: 12,
            right: 14,
            child: _AccentBadge(icon: FontAwesomeIcons.circleCheck),
          ),
          Positioned(
            bottom: 14,
            left: 10,
            child: _AccentBadge(icon: FontAwesomeIcons.shieldHalved),
          ),
        ],
      ),
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  final double size;
  final double opacity;

  const _BackgroundOrb({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: .circle,
      color: context.white.withValues(alpha: opacity),
    ),
  );
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
