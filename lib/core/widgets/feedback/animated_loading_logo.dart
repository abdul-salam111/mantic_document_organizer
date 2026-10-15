import 'package:flutter/material.dart';

import '../../constants/app_images.dart';
import '../../theme/theme_exports.dart';

/// The shared "big" loading visual -- a soft glow overlay behind a gently
/// pulsing Dockitly mark, instead of a bare spinner. Used wherever a loader
/// is prominent enough to notice (the blocking [showLoadingPopup], a
/// default-sized [LoadingIndicator]) rather than tucked inside a button or
/// an inline status line, where this much motion would be distracting.
class AnimatedLoadingLogo extends StatefulWidget {
  final double size;

  const AnimatedLoadingLogo({super.key, this.size = 64});

  @override
  State<AnimatedLoadingLogo> createState() => _AnimatedLoadingLogoState();
}

class _AnimatedLoadingLogoState extends State<AnimatedLoadingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    // The overlay is sized larger than the mark itself so the glow reads as
    // a backdrop it's sitting on, not a ring hugging its edges.
    final overlaySize = widget.size * 1.7;
    return SizedBox(
      width: overlaySize,
      height: overlaySize,
      child: Stack(
        alignment: .center,
        children: [
          AnimatedBuilder(
            animation: curve,
            builder: (context, child) => Opacity(
              opacity: 0.25 + (curve.value * 0.2),
              child: Transform.scale(
                scale: 0.9 + (curve.value * 0.15),
                child: child,
              ),
            ),
            child: Container(
              width: overlaySize,
              height: overlaySize,
              decoration: BoxDecoration(
                shape: .circle,
                gradient: RadialGradient(
                  colors: [
                    context.primary.withValues(alpha: 0.35),
                    context.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: curve,
            builder: (context, child) => Opacity(
              opacity: 0.78 + (curve.value * 0.22),
              child: Transform.scale(
                scale: 0.94 + (curve.value * 0.08),
                child: child,
              ),
            ),
            child: ClipRRect(
              borderRadius: .circular(widget.size * 0.22),
              child: Image.asset(
                AppImages.dockitlyOrganizing,
                width: widget.size,
                height: widget.size,
                fit: .cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
