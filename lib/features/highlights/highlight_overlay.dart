import 'package:flutter/material.dart';

import '../../shared/db/app_db.dart';

class HighlightOverlay extends StatelessWidget {
  final StepHighlight highlight;

  const HighlightOverlay({super.key, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _HighlightPainter(highlight),
        size: Size.infinite,
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  final StepHighlight h;
  _HighlightPainter(this.h);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      h.x * size.width,
      h.y * size.height,
      h.w * size.width,
      h.h * size.height,
    );

    final fill = Paint()..color = Colors.yellow.withOpacity(0.20);
    final stroke = Paint()
      ..color = Colors.yellow.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, stroke);
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter oldDelegate) {
    return oldDelegate.h != h;
  }
}
