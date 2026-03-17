import 'dart:math' as math;

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

  Color _paletteColor(int idx) {
    switch (idx.clamp(0, 4)) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.white;
      case 4:
        return Colors.black;
      default:
        return Colors.yellow;
    }
  }

  ({int border, int fill}) _unpackShapeColor(int packed) {
    if (packed >= 0 && packed <= 4) {
      return (border: packed, fill: packed);
    }
    final border = packed % 10;
    final fill = (packed ~/ 10) % 10;
    return (
    border: border.clamp(0, 4),
    fill: fill.clamp(0, 4),
    );
  }

  ({int border, int bg, int text}) _unpackTextColor(int packed) {
    final border = packed % 10;
    final bg = (packed ~/ 10) % 10;
    final text = (packed ~/ 100) % 10;
    return (
    border: border.clamp(0, 4),
    bg: bg.clamp(0, 4),
    text: text.clamp(0, 4),
    );
  }

  Rect _squareBounds(Size size) {
    final side = math.min(size.width, size.height);
    final left = (size.width - side) / 2;
    final top = (size.height - side) / 2;
    return Rect.fromLTWH(left, top, side, side);
  }

  Rect _normRectToSquare(Rect square, StepAnnotation a) {
    return Rect.fromLTWH(
      square.left + (a.x * square.width),
      square.top + (a.y * square.height),
      a.w * square.width,
      a.h * square.height,
    );
  }

  Rect _circleRect(Rect rect) {
    final d = math.min(rect.width, rect.height);
    return Rect.fromCenter(center: rect.center, width: d, height: d);
  }

  Offset _normPointToSquare(Rect square, double x, double y) {
    return Offset(
      square.left + (x * square.width),
      square.top + (y * square.height),
    );
  }

  double _shapeStroke(double side) => (side * 0.0076).clamp(2.0, 3.0);
  double _arrowStroke(double side) => (side * 0.0080).clamp(2.2, 3.2);
  double _arrowHead(double side) => (side * 0.040).clamp(10.0, 16.0);

  void _drawArrow(Canvas canvas, Rect square, StepAnnotation a) {
    final tip = _normPointToSquare(square, a.x, a.y);
    final tail = _normPointToSquare(square, a.x + a.w, a.y + a.h);

    final paint = Paint()
      ..color = _paletteColor(a.color).withOpacity(0.95)
      ..strokeWidth = _arrowStroke(square.width)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawLine(tail, tip, paint);

    final dir = tip - tail;
    final len = dir.distance;
    if (len <= 0.01) return;

    final u = dir / len;
    final headLen = _arrowHead(square.width);
    const headAngle = 0.55;

    Offset rot(Offset v, double a) {
      return Offset(
        v.dx * math.cos(a) - v.dy * math.sin(a),
        v.dx * math.sin(a) + v.dy * math.cos(a),
      );
    }

    final left = rot(u, headAngle);
    final right = rot(u, -headAngle);

    canvas.drawLine(tip, tip - left * headLen, paint);
    canvas.drawLine(tip, tip - right * headLen, paint);
  }

  TextPainter _fitTextPainter({
    required String label,
    required Color textColor,
    required double baseSize,
    required double maxWidth,
    required bool singleWord,
  }) {
    double fittedSize = baseSize;

    if (singleWord) {
      final natural = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: baseSize,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(minWidth: 0, maxWidth: 10000);

      if (natural.width > maxWidth && natural.width > 0) {
        fittedSize = (baseSize * (maxWidth / natural.width)).clamp(8.0, baseSize);
      }
    }

    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: fittedSize,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: singleWord ? 1 : 5,
    )..layout(maxWidth: maxWidth);

    return painter;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final square = _squareBounds(size);
    final shapeStroke = _shapeStroke(square.width);
    final radius = Radius.circular((square.width * 0.03).clamp(8.0, 10.0));

    for (final a in anns) {
      if (a.kind == 0 && (a.shapeType ?? 0) == 2) {
        _drawArrow(canvas, square, a);
        continue;
      }

      final rect = _normRectToSquare(square, a);

      if (a.kind == 0) {
        final colors = _unpackShapeColor(a.color);
        final borderColor = _paletteColor(colors.border);
        final fillColor = _paletteColor(colors.fill);

        final fill = Paint()
          ..color = fillColor.withOpacity(0.18)
          ..isAntiAlias = true;

        final stroke = Paint()
          ..color = borderColor.withOpacity(0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = shapeStroke
          ..isAntiAlias = true;

        final shapeType = a.shapeType ?? 0;
        if (shapeType == 1) {
          final circle = _circleRect(rect);
          canvas.drawOval(circle, fill);
          canvas.drawOval(circle, stroke);
        } else {
          final rrect = RRect.fromRectAndRadius(rect, radius);
          canvas.drawRRect(rrect, fill);
          canvas.drawRRect(rrect, stroke);
        }
        continue;
      }

      final label = (a.label ?? '').trim();
      if (label.isEmpty) continue;

      final colors = _unpackTextColor(a.color);
      final borderColor = _paletteColor(colors.border);
      final bgColor = _paletteColor(colors.bg);
      final textColor = _paletteColor(colors.text);

      final padX = (square.width * 0.026).clamp(8.0, 12.0);
      final padY = (square.width * 0.018).clamp(5.0, 8.0);

      final isSingleWord = !label.contains(RegExp(r'\s'));
      final maxWidth = math.max(20.0, rect.width - (padX * 2));
      final baseSize = (math.min(rect.width, rect.height) * 0.42).clamp(10.0, 18.0);

      final fitted = _fitTextPainter(
        label: label,
        textColor: textColor,
        baseSize: baseSize,
        maxWidth: maxWidth,
        singleWord: isSingleWord,
      );

      var boxHeight = math.max(rect.height, fitted.height + padY * 2);
      var top = rect.center.dy - boxHeight / 2;
      if (top < square.top) top = square.top;
      if (top + boxHeight > square.bottom) top = square.bottom - boxHeight;

      final boxRect = Rect.fromLTWH(rect.left, top, rect.width, boxHeight);
      final bg = RRect.fromRectAndRadius(boxRect, radius);

      canvas.drawRRect(
        bg,
        Paint()
          ..color = bgColor.withOpacity(0.60)
          ..isAntiAlias = true,
      );

      canvas.drawRRect(
        bg,
        Paint()
          ..color = borderColor.withOpacity(0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = shapeStroke
          ..isAntiAlias = true,
      );

      final offset = Offset(
        boxRect.center.dx - fitted.width / 2,
        boxRect.center.dy - fitted.height / 2,
      );

      fitted.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationsPainter oldDelegate) => true;
}
