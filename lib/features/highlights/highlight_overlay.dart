import 'package:flutter/material.dart';

import '../../shared/db/app_db.dart';

class HighlightOverlay extends StatelessWidget {
  final List<StepAnnotation> annotations;

  const HighlightOverlay({
    super.key,
    required this.annotations,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _AnnotationsPainter(annotations),
        size: Size.infinite,
      ),
    );
  }
}

class _AnnotationsPainter extends CustomPainter {
  final List<StepAnnotation> anns;

  _AnnotationsPainter(this.anns);

  Color _colorFor(int c) {
    switch (c) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.blue;
      default:
        return Colors.yellow;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final a in anns) {
      final rect = Rect.fromLTWH(
        a.x * size.width,
        a.y * size.height,
        a.w * size.width,
        a.h * size.height,
      );

      final base = _colorFor(a.color);
      final fill = Paint()..color = base.withOpacity(0.20);
      final stroke = Paint()
        ..color = base.withOpacity(0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      if (a.kind == 0) {
        // shape
        final shapeType = a.shapeType ?? 0;
        if (shapeType == 1) {
          // circle (oval)
          canvas.drawOval(rect, fill);
          canvas.drawOval(rect, stroke);
        } else {
          // rect
          canvas.drawRect(rect, fill);
          canvas.drawRect(rect, stroke);
        }
      } else {
        // text label
        final label = (a.label ?? '').trim();
        if (label.isEmpty) continue;

        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: (rect.height * 0.55).clamp(12.0, 28.0),
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 2,
          ellipsis: '…',
        )..layout(maxWidth: rect.width);

        // background pill
        final pad = 6.0;
        final bg = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            rect.left,
            rect.top,
            tp.width + pad * 2,
            tp.height + pad * 2,
          ),
          const Radius.circular(8),
        );

        canvas.drawRRect(bg, Paint()..color = Colors.black.withOpacity(0.55));
        tp.paint(canvas, Offset(rect.left + pad, rect.top + pad));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationsPainter oldDelegate) {
    return oldDelegate.anns != anns;
  }
}
