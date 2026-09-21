import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_template/core/widgets/feedback/loading_indicator.dart';

/////////////////////////////////////  WIDGETS EXTENSIONS ////////////////////////////////////////
extension WidgetExtensions on Widget {
  // Add padding to a widget
  Widget withPadding(EdgeInsets padding) {
    return Padding(padding: padding, child: this);
  }

  // Add margin to a widget
  Widget withMargin(EdgeInsets margin) {
    return Container(margin: margin, child: this);
  }

  // Conditionally show a widget
  Widget showIf(bool condition) {
    return condition ? this : const SizedBox.shrink();
  }

  // Add a gesture detector (e.g., onTap)
  Widget onTap(VoidCallback onTap, {bool opaque = true}) {
    return GestureDetector(
      onTap: onTap,
      behavior: opaque ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
      child: this,
    );
  }

  // Center a widget
  Widget center() {
    return Center(child: this);
  }

  // Add a border to a widget
  Widget withBorder({
    Color color = Colors.black,
    double width = 1.0,
    BorderRadius? borderRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: width),
        borderRadius: borderRadius,
      ),
      child: this,
    );
  }

  // Add a background color to a widget
  Widget withBackground(Color color, {BorderRadius? borderRadius}) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: borderRadius),
      child: this,
    );
  }

  // Add a tooltip to a widget
  Widget withTooltip(String message, {Decoration? decoration, double? height}) {
    return Tooltip(
      message: message,
      decoration: decoration,
      constraints: BoxConstraints(minHeight: height!),
      child: this,
    );
  }

  // Wrap a widget in a SizedBox with a specific width and height
  Widget withSize({double? width, double? height}) {
    return SizedBox(width: width, height: height, child: this);
  }

  // Wrap a widget in an Expanded widget
  Widget expanded({int flex = 1}) {
    return Expanded(flex: flex, child: this);
  }

  // Wrap a widget in a Flexible widget
  Widget flexible({int flex = 1, FlexFit fit = FlexFit.loose}) {
    return Flexible(flex: flex, fit: fit, child: this);
  }

  // Add a hero animation to a widget
  Widget withHero({required String tag}) {
    return Hero(tag: tag, child: this);
  }

  // Add a rotation to a widget
  Widget withRotation(double angle, {Offset? origin}) {
    return Transform.rotate(angle: angle, origin: origin, child: this);
  }

  // Add a scale transformation to a widget
  Widget withScale(double scale, {Offset? origin}) {
    return Transform.scale(scale: scale, origin: origin, child: this);
  }

  // Add a translation transformation to a widget
  Widget withTranslation(Offset offset) {
    return Transform.translate(offset: offset, child: this);
  }

  // Add a fade animation to a widget
  Widget withFadeAnimation(AnimationController controller) {
    return FadeTransition(opacity: controller, child: this);
  }

  // Add opacity to a widget
  Widget withOpacity(double opacity) {
    return Opacity(opacity: opacity, child: this);
  }

  // Add alignment to a widget
  Widget align(Alignment alignment) {
    return Align(alignment: alignment, child: this);
  }

  // Add shadow to a widget
  Widget withShadow({
    Color color = Colors.black26,
    double blurRadius = 4.0,
    Offset offset = Offset.zero,
    double spreadRadius = 0.0,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: blurRadius,
            offset: offset,
            spreadRadius: spreadRadius,
          ),
        ],
      ),
      child: this,
    );
  }

  // Add rounded corners
  Widget withRoundedCorners(double radius) {
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: this);
  }

  // Add gesture detector for long press
  Widget onLongPress(VoidCallback onLongPress, {bool opaque = true}) {
    return GestureDetector(
      onLongPress: onLongPress,
      behavior: opaque ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
      child: this,
    );
  }

  // Add gesture detector for double tap
  Widget onDoubleTap(VoidCallback onDoubleTap, {bool opaque = true}) {
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      behavior: opaque ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
      child: this,
    );
  }

  // Add InkWell for material ripple effect
  Widget withInkWell({
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onDoubleTap,
    BorderRadius? borderRadius,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      borderRadius: borderRadius,
      child: this,
    );
  }

  // Add positioned (for Stack)
  Widget positioned({
    double? top,
    double? bottom,
    double? left,
    double? right,
    double? width,
    double? height,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      width: width,
      height: height,
      child: this,
    );
  }

  // Add aspect ratio
  Widget withAspectRatio(double aspectRatio) {
    return AspectRatio(aspectRatio: aspectRatio, child: this);
  }

  // Add constrained box
  Widget constrained({
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth ?? 0.0,
        maxWidth: maxWidth ?? double.infinity,
        minHeight: minHeight ?? 0.0,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: this,
    );
  }

  // Add fitted box
  Widget fitted({
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
  }) {
    return FittedBox(fit: fit, alignment: alignment, child: this);
  }

  // Add clip oval
  Widget clipOval() {
    return ClipOval(child: this);
  }

  // Add card wrapper
  Widget asCard({
    Color? color,
    double? elevation,
    ShapeBorder? shape,
    EdgeInsets? margin,
    Clip? clipBehavior,
  }) {
    return Card(
      color: color,
      elevation: elevation,
      shape: shape,
      margin: margin,
      clipBehavior: clipBehavior,
      child: this,
    );
  }

  // Add SafeArea wrapper
  Widget safeArea({
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
    EdgeInsets minimum = EdgeInsets.zero,
  }) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      minimum: minimum,
      child: this,
    );
  }

  // Add scrollable wrapper
  Widget scrollable({
    Axis scrollDirection = Axis.vertical,
    ScrollPhysics? physics,
    EdgeInsets? padding,
  }) {
    return SingleChildScrollView(
      scrollDirection: scrollDirection,
      physics: physics,
      padding: padding,
      child: this,
    );
  }

  // Add visibility wrapper
  Widget visible(bool visible, {Widget? replacement}) {
    return Visibility(
      visible: visible,
      replacement: replacement ?? const SizedBox.shrink(),
      child: this,
    );
  }

  // Add decorated box
  Widget decorated(BoxDecoration decoration) {
    return DecoratedBox(decoration: decoration, child: this);
  }

  // Add gradient background
  Widget withGradient(Gradient gradient, {BorderRadius? borderRadius}) {
    return Container(
      decoration: BoxDecoration(gradient: gradient, borderRadius: borderRadius),
      child: this,
    );
  }

  // Add intrinsic height
  Widget intrinsicHeight() {
    return IntrinsicHeight(child: this);
  }

  // Add intrinsic width
  Widget intrinsicWidth() {
    return IntrinsicWidth(child: this);
  }

  // Add baseline alignment
  Widget baseline({
    required double baseline,
    required TextBaseline baselineType,
  }) {
    return Baseline(
      baseline: baseline,
      baselineType: baselineType,
      child: this,
    );
  }

  // Add absorb pointer (disable touch events)
  Widget absorbPointer({bool absorbing = true}) {
    return AbsorbPointer(absorbing: absorbing, child: this);
  }

  // Add ignore pointer
  Widget ignorePointer({bool ignoring = true}) {
    return IgnorePointer(ignoring: ignoring, child: this);
  }

  // Add slide transition
  Widget withSlideAnimation(Animation<Offset> position) {
    return SlideTransition(position: position, child: this);
  }

  // Add scale transition
  Widget withScaleAnimation(Animation<double> scale) {
    return ScaleTransition(scale: scale, child: this);
  }

  // Add rotation transition
  Widget withRotationAnimation(Animation<double> turns) {
    return RotationTransition(turns: turns, child: this);
  }

  // Wrap widget in a Container (box) with optional parameters
  Widget container({
    double? width,
    double? height,
    Color? color,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BoxDecoration? decoration,
    AlignmentGeometry? alignment,
    BoxConstraints? constraints,
  }) {
    return Container(
      width: width,
      height: height,
      color: decoration == null ? color : null,
      padding: padding,
      margin: margin,
      decoration: decoration,
      alignment: alignment,
      constraints: constraints,
      child: this,
    );
  }

  // Change widget color by wrapping in a ColoredBox or Container
  Widget color(Color color) {
    return ColoredBox(color: color, child: this);
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////

// ============== Focus Management ==============

class UnfocusWrapper extends StatelessWidget {
  final Widget child;

  const UnfocusWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

// ============== Keyboard Dismisser ==============

class KeyboardDismisser extends StatelessWidget {
  final Widget child;
  final bool dismissOnTap;
  final bool dismissOnVerticalDrag;

  const KeyboardDismisser({
    super.key,
    required this.child,
    this.dismissOnTap = true,
    this.dismissOnVerticalDrag = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: dismissOnTap ? () => FocusScope.of(context).unfocus() : null,
      onVerticalDragStart: dismissOnVerticalDrag
          ? (_) => FocusScope.of(context).unfocus()
          : null,
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

// ============== Loading Overlay ==============

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? overlayColor;
  final Widget? loadingWidget;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.overlayColor,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: overlayColor ?? Colors.black54,
            child: Center(
              child: loadingWidget ?? const LoadingIndicator(size: 30),
            ),
          ),
      ],
    );
  }
}

// ============== Responsive Builder ==============

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints)?
  builder;
  final Widget Function(BuildContext context)? mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;
  final double mobileBreakpoint;
  final double tabletBreakpoint;

  const ResponsiveBuilder({
    super.key,
    this.builder,
    this.mobile,
    this.tablet,
    this.desktop,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 900,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (builder != null) {
          return builder!(context, constraints);
        }

        if (constraints.maxWidth < mobileBreakpoint) {
          return mobile?.call(context) ?? const SizedBox.shrink();
        } else if (constraints.maxWidth < tabletBreakpoint) {
          return tablet?.call(context) ??
              mobile?.call(context) ??
              const SizedBox.shrink();
        } else {
          return desktop?.call(context) ??
              tablet?.call(context) ??
              mobile?.call(context) ??
              const SizedBox.shrink();
        }
      },
    );
  }
}

// ============== Conditional Wrapper ==============

class ConditionalWrapper extends StatelessWidget {
  final bool condition;
  final Widget Function(Widget child) wrapper;
  final Widget child;

  const ConditionalWrapper({
    super.key,
    required this.condition,
    required this.wrapper,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return condition ? wrapper(child) : child;
  }
}

// ============== Safe Area Wrapper ==============

class SafeAreaWrapper extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final EdgeInsets minimum;

  const SafeAreaWrapper({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.minimum = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      minimum: minimum,
      child: child,
    );
  }
}

// ============== Padding Wrapper ==============

class PaddingWrapper extends StatelessWidget {
  final Widget child;
  final double? all;
  final double? horizontal;
  final double? vertical;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;

  const PaddingWrapper({
    super.key,
    required this.child,
    this.all,
    this.horizontal,
    this.vertical,
    this.left,
    this.right,
    this.top,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: left ?? horizontal ?? all ?? 0,
        right: right ?? horizontal ?? all ?? 0,
        top: top ?? vertical ?? all ?? 0,
        bottom: bottom ?? vertical ?? all ?? 0,
      ),
      child: child,
    );
  }
}

// ============== Empty State Widget ==============

class EmptyStateWidget extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: iconSize, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}

// ============== Error State Widget ==============

class ErrorStateWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message ?? 'Something went wrong',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

// ============== Shimmer Loading ==============

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: GradientRotation(_controller.value * 2 * 3.14159),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// ============== Async Builder ==============

class AsyncBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loading;
  final Widget Function(BuildContext context, Object error)? error;

  const AsyncBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loading?.call(context) ??
              const Center(child: LoadingIndicator(size: 30));
        }

        if (snapshot.hasError) {
          return error?.call(context, snapshot.error!) ??
              ErrorStateWidget(message: snapshot.error.toString());
        }

        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ============== Stream Builder Wrapper ==============

class StreamBuilderWrapper<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loading;
  final Widget Function(BuildContext context, Object error)? error;
  final T? initialData;

  const StreamBuilderWrapper({
    super.key,
    required this.stream,
    required this.builder,
    this.loading,
    this.error,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return loading?.call(context) ??
              const Center(child: LoadingIndicator(size: 30));
        }

        if (snapshot.hasError) {
          return error?.call(context, snapshot.error!) ??
              ErrorStateWidget(message: snapshot.error.toString());
        }

        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ============== Debounced TextField ==============

class DebouncedTextField extends StatefulWidget {
  final Duration debounceDuration;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? hintText;

  const DebouncedTextField({
    super.key,
    required this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.controller,
    this.decoration,
    this.keyboardType,
    this.maxLines,
    this.hintText,
  });

  @override
  State<DebouncedTextField> createState() => _DebouncedTextFieldState();
}

class _DebouncedTextFieldState extends State<DebouncedTextField> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onChanged(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      decoration:
          widget.decoration ??
          InputDecoration(
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
          ),
      onChanged: _onSearchChanged,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
    );
  }
}

// ============== Animated Visibility ==============

class AnimatedVisibility extends StatelessWidget {
  final bool visible;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AnimatedVisibility({
    super.key,
    required this.visible,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: duration,
      curve: curve,
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        height: visible ? null : 0,
        child: child,
      ),
    );
  }
}

// ============== Divider with Text ==============

class DividerWithText extends StatelessWidget {
  final String text;
  final double thickness;
  final Color? color;
  final double spacing;

  const DividerWithText({
    super.key,
    required this.text,
    this.thickness = 1.0,
    this.color,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(thickness: thickness, color: color ?? Colors.grey),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: Text(text, style: TextStyle(color: color ?? Colors.grey)),
        ),
        Expanded(
          child: Divider(thickness: thickness, color: color ?? Colors.grey),
        ),
      ],
    );
  }
}

// ============== Card Wrapper ==============

class CardWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final double borderRadius;
  final VoidCallback? onTap;

  const CardWrapper({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius = 12.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      elevation: elevation,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      );
    }

    return card;
  }
}

// ============== Scroll to Hide/Show ==============

class ScrollToHide extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final Duration duration;

  const ScrollToHide({
    super.key,
    required this.child,
    required this.controller,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<ScrollToHide> createState() => _ScrollToHideState();
}

class _ScrollToHideState extends State<ScrollToHide> {
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listen);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listen);
    super.dispose();
  }

  void _listen() {
    final direction = widget.controller.position.userScrollDirection;
    if (direction == ScrollDirection.forward) {
      _show();
    } else if (direction == ScrollDirection.reverse) {
      _hide();
    }
  }

  void _show() {
    if (!_isVisible) setState(() => _isVisible = true);
  }

  void _hide() {
    if (_isVisible) setState(() => _isVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: widget.duration,
      height: _isVisible ? kToolbarHeight : 0.0,
      child: Wrap(children: [widget.child]),
    );
  }
}

// ============== Pull to Refresh Wrapper ==============

class PullToRefreshWrapper extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;

  const PullToRefreshWrapper({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: onRefresh, color: color, child: child);
  }
}

// ============== Status Bar Color ==============

class StatusBarColor extends StatelessWidget {
  final Widget child;
  final Color color;
  final Brightness brightness;

  const StatusBarColor({
    super.key,
    required this.child,
    required this.color,
    this.brightness = Brightness.dark,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: color,
        statusBarIconBrightness: brightness,
      ),
      child: child,
    );
  }
}

// ============== Gradient Container ==============

class GradientContainer extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final double? borderRadius;
  final EdgeInsets? padding;

  const GradientContainer({
    super.key,
    required this.child,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: begin, end: end),
        borderRadius: borderRadius != null
            ? BorderRadius.circular(borderRadius!)
            : null,
      ),
      child: child,
    );
  }
}

// ============== Placeholder Widget ==============

class PlaceholderBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final String? text;

  const PlaceholderBox({
    super.key,
    this.width,
    this.height,
    this.color,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 200,
      color: color ?? Colors.grey[300],
      child: Center(
        child: Text(
          text ?? 'Placeholder',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }
}
