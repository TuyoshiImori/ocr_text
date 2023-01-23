import 'dart:math';

import 'package:flutter/material.dart';

class FocusPainter extends Decoration {
  const FocusPainter({
    this.backgroundColor = Colors.transparent,
    required this.frameSFactor,
    required this.gap,
  });

  final Color? backgroundColor;
  final double frameSFactor;

  //defalut padding _Need to check
  final double gap;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return CustomDecorationPainter(
      backgroundColor: backgroundColor!,
      frameSFactor: frameSFactor,
      padding: gap,
    );
  }
}

class CustomDecorationPainter extends BoxPainter {
  CustomDecorationPainter({
    required this.backgroundColor,
    required this.frameSFactor,
    required this.padding,
  });

  final Color backgroundColor;
  final double frameSFactor;
  final double padding;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final bounds = offset & configuration.size!;

    const frameHWidth = 15; //configuration.size!.width * frameSFactor;

    final strokeWidth = pow(padding, 2).toDouble();
    final paint = Paint()
      ..color = backgroundColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill
      ..strokeWidth = strokeWidth;

    /// background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bounds,
        const Radius.circular(18),
      ),
      paint,
    );

    paint.color = Colors.purpleAccent;

    /// top left
    canvas
      ..drawLine(
        bounds.topLeft + Offset(padding, padding),
        Offset(bounds.topLeft.dx + frameHWidth, bounds.topLeft.dy) +
            Offset(padding, padding),
        paint,
      )
      ..drawLine(
        bounds.topLeft + Offset(padding, padding),
        Offset(bounds.topLeft.dx, bounds.topLeft.dy + frameHWidth) +
            Offset(padding, padding),
        paint,
      )

      ///top Right
      ..drawLine(
        Offset(bounds.topRight.dx - padding, bounds.topRight.dy + padding),
        Offset(
          bounds.topRight.dx - padding - frameHWidth,
          bounds.topRight.dy + padding,
        ),
        paint,
      )
      ..drawLine(
        Offset(bounds.topRight.dx - padding, bounds.topRight.dy + padding),
        Offset(
          bounds.topRight.dx - padding,
          bounds.topRight.dy + padding + frameHWidth,
        ),
        paint..color,
      )

      ///bottom Right
      ..drawLine(
        Offset(
            bounds.bottomRight.dx - padding, bounds.bottomRight.dy - padding),
        Offset(
          bounds.bottomRight.dx - padding,
          bounds.bottomRight.dy - padding - frameHWidth,
        ),
        paint,
      )
      ..drawLine(
        Offset(
            bounds.bottomRight.dx - padding, bounds.bottomRight.dy - padding),
        Offset(
          bounds.bottomRight.dx - padding - frameHWidth,
          bounds.bottomRight.dy - padding,
        ),
        paint,
      )

      ///bottom Left
      ..drawLine(
        Offset(bounds.bottomLeft.dx + padding, bounds.bottomLeft.dy - padding),
        Offset(
          bounds.bottomLeft.dx + padding,
          bounds.bottomLeft.dy - padding - frameHWidth,
        ),
        paint,
      )
      ..drawLine(
        Offset(bounds.bottomLeft.dx + padding, bounds.bottomLeft.dy - padding),
        Offset(
          bounds.bottomLeft.dx + padding + frameHWidth,
          bounds.bottomLeft.dy - padding,
        ),
        paint,
      );
  }
}
