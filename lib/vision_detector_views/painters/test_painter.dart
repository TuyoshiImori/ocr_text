import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_text/vision_detector_views/painters/coordinates_translator.dart';

class TestPainter extends CustomPainter {
  TestPainter(
    this.textBlock,
    this.absoluteImageSize,
    this.rotation,
  );

  final TextBlock textBlock;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    var path = Path();
    final right = translateX(
      textBlock.boundingBox.right,
      rotation,
      size,
      absoluteImageSize,
    );
    final bottom = translateY(
      textBlock.boundingBox.bottom,
      rotation,
      size,
      absoluteImageSize,
    );
    paint = Paint()
      ..color = Colors.lightGreenAccent
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, bottom);
    path.lineTo(right, bottom);
    path.lineTo(right, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  //   final paint = Paint()
  //     ..style = PaintingStyle.stroke
  //     ..strokeWidth = 3.0
  //     ..color = Colors.lightGreenAccent;
  //
  //   final background = Paint()..color = const Color(0x99000000);
  //
  //   final builder = ParagraphBuilder(
  //     ParagraphStyle(
  //       textAlign: TextAlign.left,
  //       fontSize: 16,
  //       textDirection: TextDirection.ltr,
  //     ),
  //   )
  //     ..pushStyle(
  //       ui.TextStyle(
  //         color: Colors.lightGreenAccent,
  //         background: background,
  //       ),
  //     )
  //     //..addText(textBlock.text)
  //     ..pop();
  //
  //   final left = translateX(
  //     textBlock.boundingBox.left,
  //     rotation,
  //     size,
  //     absoluteImageSize,
  //   );
  //   final top = translateY(
  //     textBlock.boundingBox.top,
  //     rotation,
  //     size,
  //     absoluteImageSize,
  //   );
  //   final right = translateX(
  //     textBlock.boundingBox.right,
  //     rotation,
  //     size,
  //     absoluteImageSize,
  //   );
  //   final bottom = translateY(
  //     textBlock.boundingBox.bottom,
  //     rotation,
  //     size,
  //     absoluteImageSize,
  //   );
  //
  //   canvas
  //     ..drawRect(
  //       Rect.fromLTRB(left, top, right, bottom),
  //       paint,
  //     )
  //     ..drawParagraph(
  //       builder.build()
  //         ..layout(
  //           ParagraphConstraints(
  //             width: right - left,
  //           ),
  //         ),
  //       Offset(left, top),
  //     );
  // }

  @override
  bool shouldRepaint(TestPainter oldDelegate) {
    return oldDelegate.textBlock != textBlock;
  }
}
