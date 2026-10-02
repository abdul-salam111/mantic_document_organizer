import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders [text] following the arc of a circle of [radius], centered on
/// [centerAngleDegrees] (90 = the bottom of the circle, Flutter canvas
/// convention: 0 = right, 90 = down, 180 = left, 270 = up). Used to wrap a
/// short wordmark around the bottom of a decorative circle/logo badge.
///
/// Sized to a `radius * 2` square; place it centered over the circle it
/// should hug (e.g. inside a [Stack] with the circle, both centered).
class CurvedText extends StatelessWidget {
  final String text;
  final double radius;
  final TextStyle style;
  final double centerAngleDegrees;

  const CurvedText({
    super.key,
    required this.text,
    required this.radius,
    required this.style,
    this.centerAngleDegrees = 90,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(radius * 2, radius * 2),
    painter: _CurvedTextPainter(
      text: text,
      radius: radius,
      style: style,
      centerAngle: centerAngleDegrees * math.pi / 180,
    ),
  );
}

class _CurvedTextPainter extends CustomPainter {
  final String text;
  final double radius;
  final TextStyle style;
  final double centerAngle;

  _CurvedTextPainter({
    required this.text,
    required this.radius,
    required this.style,
    required this.centerAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty || radius <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);

    final chars = text.characters.toList();
    final painters = <TextPainter>[];
    var totalWidth = 0.0;
    for (final char in chars) {
      final painter = TextPainter(
        text: TextSpan(text: char, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      painters.add(painter);
      totalWidth += painter.width;
    }

    // Canvas angle convention (0 = right, 90 = down, 180 = left) increases
    // clockwise, so the *smaller* angle is further right. For left-to-right
    // reading order, the first character needs the larger angle (left
    // side), walking down to the smaller angle (right side) as the string
    // progresses -- the reverse of a naive increasing-angle walk.
    final totalAngle = totalWidth / radius;
    var angle = centerAngle + totalAngle / 2;

    for (final painter in painters) {
      final charAngle = painter.width / radius;
      final charCenterAngle = angle - charAngle / 2;
      final position =
          center +
          Offset(math.cos(charCenterAngle), math.sin(charCenterAngle)) *
              radius;

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(charCenterAngle - math.pi / 2);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();

      angle -= charAngle;
    }
  }

  @override
  bool shouldRepaint(_CurvedTextPainter oldDelegate) =>
      text != oldDelegate.text ||
      radius != oldDelegate.radius ||
      style != oldDelegate.style ||
      centerAngle != oldDelegate.centerAngle;
}
