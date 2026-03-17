import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Image;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../db/app_db.dart';

class GuidePdfExporter {
  static Future<void> exportAndShare({
    required AppDatabase db,
    required int guideId,
  }) async {
    final guide = await db.getGuideById(guideId);
    if (guide == null) throw Exception('Guide not found');

    final steps = await db.getStepsForGuide(guideId);
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              guide.title,
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Exported: ${_formatDateTime(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Spacer(),
            pw.Text(
              'Steps: ${steps.length}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );

    for (final step in steps) {
      final payload = _StepImagesPayload.fromPhotoPath(step.photoPath);
      final allAnns = await db.getAnnotationsForStep(step.id);
      final anns1 = _annsForSlot(allAnns, 1);
      final anns2 = _annsForSlot(allAnns, 2);

      Uint8List? img1;
      Uint8List? img2;

      if (payload.a != null && payload.a!.path.trim().isNotEmpty) {
        img1 = await _renderAnnotatedSquare(
          file: File(payload.a!.path),
          annotations: anns1,
        );
      }
      if (payload.b != null && payload.b!.path.trim().isNotEmpty) {
        img2 = await _renderAnnotatedSquare(
          file: File(payload.b!.path),
          annotations: anns2,
        );
      }

      final blocks = <_PdfStepBlock>[
        _PdfStepBlock(text: step.instructionText, imageBytes: img1),
      ];

      final secondText = (step.instructionText2 ?? '').trim();
      if (secondText.isNotEmpty || img2 != null) {
        blocks.add(_PdfStepBlock(text: secondText, imageBytes: img2));
      }

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 24),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Step ${step.stepIndex}',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 14),
              for (int i = 0; i < blocks.length; i++) ...[
                _pdfStepBlock(blocks[i]),
                if (i != blocks.length - 1) pw.SizedBox(height: 18),
              ],
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Step ${step.stepIndex} of ${steps.length}',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final safeTitle = _safeFilename(guide.title);
    final file = File('${dir.path}/$safeTitle.pdf');
    await file.writeAsBytes(bytes, flush: true);

    await Printing.sharePdf(bytes: bytes, filename: '$safeTitle.pdf');
  }

  static pw.Widget _pdfStepBlock(_PdfStepBlock block) {
    return pw.Container(
      height: 320,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              padding: const pw.EdgeInsets.only(right: 14),
              child: pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  block.text.trim().isEmpty ? ' ' : block.text,
                  style: const pw.TextStyle(
                    fontSize: 18,
                    lineSpacing: 3,
                  ),
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            flex: 6,
            child: block.imageBytes == null
                ? pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey600),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text('No image'),
            )
                : pw.ClipRRect(
              horizontalRadius: 10,
              verticalRadius: 10,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey600),
                ),
                child: pw.Image(
                  pw.MemoryImage(block.imageBytes!),
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfStepBlock {
  final String text;
  final Uint8List? imageBytes;

  const _PdfStepBlock({
    required this.text,
    required this.imageBytes,
  });
}

const int _slot2SortOrderBase = 1000;

List<StepAnnotation> _annsForSlot(List<StepAnnotation> all, int slot) {
  if (slot == 1) {
    final filtered =
    all.where((a) => a.sortOrder < _slot2SortOrderBase).toList();
    filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return filtered;
  }
  final filtered =
  all.where((a) => a.sortOrder >= _slot2SortOrderBase).toList();
  filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return filtered;
}

Color _paletteColor(int idx) {
  switch (idx.clamp(0, 4)) {
    case 1:
      return const Color(0xFFE53935);
    case 2:
      return const Color(0xFF1E88E5);
    case 3:
      return const Color(0xFFFFFFFF);
    case 4:
      return const Color(0xFF000000);
    default:
      return const Color(0xFFFFD54F);
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

ui.Rect _circleRect(ui.Rect rect) {
  final d = math.min(rect.width, rect.height);
  return ui.Rect.fromCenter(center: rect.center, width: d, height: d);
}

double _shapeStroke(double side) => (side * 0.0105).clamp(6.0, 10.0);
double _arrowStroke(double side) => (side * 0.0110).clamp(6.5, 11.0);
double _arrowHead(double side) => (side * 0.046).clamp(20.0, 32.0);

Future<Uint8List> _renderAnnotatedSquare({
  required File file,
  required List<StepAnnotation> annotations,
}) async {
  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final img = frame.image;

  const outSize = 1024;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  final src = _centerCropSquare(img);
  final dst = ui.Rect.fromLTWH(0, 0, outSize.toDouble(), outSize.toDouble());
  final paint = ui.Paint()..filterQuality = ui.FilterQuality.high;
  canvas.drawImageRect(img, src, dst, paint);

  _drawAnnotations(canvas, outSize.toDouble(), annotations);

  final picture = recorder.endRecording();
  final outImage = await picture.toImage(outSize, outSize);
  final png = await outImage.toByteData(format: ui.ImageByteFormat.png);
  if (png == null) throw Exception('Failed to encode image');
  return png.buffer.asUint8List();
}

ui.Rect _centerCropSquare(ui.Image img) {
  final w = img.width.toDouble();
  final h = img.height.toDouble();
  final size = math.min(w, h);
  final left = (w - size) / 2.0;
  final top = (h - size) / 2.0;
  return ui.Rect.fromLTWH(left, top, size, size);
}

void _drawArrow(ui.Canvas canvas, double side, StepAnnotation a) {
  final tip = ui.Offset(a.x * side, a.y * side);
  final tail = ui.Offset((a.x + a.w) * side, (a.y + a.h) * side);

  final paint = ui.Paint()
    ..color = _paletteColor(a.color).withOpacity(0.95)
    ..strokeWidth = _arrowStroke(side)
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..isAntiAlias = true;

  canvas.drawLine(tail, tip, paint);

  final dir = tip - tail;
  final len = dir.distance;
  if (len <= 0.01) return;

  final u = dir / len;
  final headLen = _arrowHead(side);
  const headAngle = 0.55;

  ui.Offset rot(ui.Offset v, double a) {
    return ui.Offset(
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
      fittedSize = (baseSize * (maxWidth / natural.width)).clamp(16.0, baseSize);
    }
  }

  return TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: textColor,
        fontSize: fittedSize,
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: singleWord ? 1 : 5,
  )..layout(maxWidth: maxWidth);
}

void _drawAnnotations(
    ui.Canvas canvas,
    double side,
    List<StepAnnotation> annotations,
    ) {
  final stroke = _shapeStroke(side);
  final radius = ui.Radius.circular((side * 0.03).clamp(12.0, 16.0));

  for (final a in annotations) {
    if (a.kind == 0) {
      if ((a.shapeType ?? 0) == 2) {
        _drawArrow(canvas, side, a);
        continue;
      }

      final rect = ui.Rect.fromLTWH(
        a.x * side,
        a.y * side,
        a.w * side,
        a.h * side,
      );

      final colors = _unpackShapeColor(a.color);
      final borderColor = _paletteColor(colors.border);
      final fillColor = _paletteColor(colors.fill);

      final fillPaint = ui.Paint()
        ..style = ui.PaintingStyle.fill
        ..isAntiAlias = true
        ..color = fillColor.withOpacity(0.18);

      final strokePaint = ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = stroke
        ..isAntiAlias = true
        ..color = borderColor.withOpacity(0.95);

      if ((a.shapeType ?? 0) == 1) {
        final circle = _circleRect(rect);
        canvas.drawOval(circle, fillPaint);
        canvas.drawOval(circle, strokePaint);
      } else {
        final rrect = ui.RRect.fromRectAndRadius(rect, radius);
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, strokePaint);
      }
      continue;
    }

    final label = (a.label ?? '').trim();
    if (label.isEmpty) continue;

    final rect = ui.Rect.fromLTWH(
      a.x * side,
      a.y * side,
      a.w * side,
      a.h * side,
    );

    final colors = _unpackTextColor(a.color);
    final borderColor = _paletteColor(colors.border);
    final bgColor = _paletteColor(colors.bg);
    final textColor = _paletteColor(colors.text);

    final fillPaint = ui.Paint()
      ..style = ui.PaintingStyle.fill
      ..isAntiAlias = true
      ..color = bgColor.withOpacity(0.60);

    final strokePaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true
      ..color = borderColor.withOpacity(0.95);

    final padX = (side * 0.026).clamp(12.0, 18.0);
    final padY = (side * 0.018).clamp(8.0, 12.0);
    final isSingleWord = !label.contains(RegExp(r'\s'));
    final maxWidth = math.max(20.0, rect.width - (padX * 2));
    final baseSize = (math.min(rect.width, rect.height) * 0.58).clamp(26.0, 42.0);

    final fitted = _fitTextPainter(
      label: label,
      textColor: textColor,
      baseSize: baseSize,
      maxWidth: maxWidth,
      singleWord: isSingleWord,
    );

    var boxHeight = math.max(rect.height, fitted.height + padY * 2);
    var top = rect.center.dy - boxHeight / 2;
    if (top < 0) top = 0;
    if (top + boxHeight > side) top = side - boxHeight;

    final boxRect = ui.Rect.fromLTWH(rect.left, top, rect.width, boxHeight);
    final rrect = ui.RRect.fromRectAndRadius(boxRect, radius);

    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, strokePaint);

    final offset = ui.Offset(
      boxRect.center.dx - fitted.width / 2,
      boxRect.center.dy - fitted.height / 2,
    );
    fitted.paint(canvas, offset);
  }
}

String _safeFilename(String s) {
  final trimmed = s.trim().isEmpty ? 'guide' : s.trim();
  final cleaned = trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
  return cleaned.length > 80 ? cleaned.substring(0, 80) : cleaned;
}

String _formatDateTime(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
}

class _StepImagesPayload {
  final _StepImageRef? a;
  final _StepImageRef? b;

  const _StepImagesPayload({required this.a, required this.b});

  static _StepImagesPayload fromPhotoPath(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const _StepImagesPayload(a: null, b: null);
    }

    final s = raw.trim();

    if (!s.startsWith('{') && s.contains('||')) {
      final parts = s.split('||');
      final a = parts.isNotEmpty && parts[0].trim().isNotEmpty
          ? _StepImageRef(path: parts[0].trim())
          : null;
      final b = parts.length >= 2 && parts[1].trim().isNotEmpty
          ? _StepImageRef(path: parts[1].trim())
          : null;
      return _StepImagesPayload(a: a, b: b);
    }

    if (!s.startsWith('{')) {
      return _StepImagesPayload(a: _StepImageRef(path: s), b: null);
    }

    try {
      final map = jsonDecode(s) as Map<String, dynamic>;
      final aMap = map['a'] as Map<String, dynamic>?;
      final bMap = map['b'] as Map<String, dynamic>?;
      return _StepImagesPayload(
        a: aMap == null ? null : _StepImageRef.fromJson(aMap),
        b: bMap == null ? null : _StepImageRef.fromJson(bMap),
      );
    } catch (_) {
      return _StepImagesPayload(a: _StepImageRef(path: s), b: null);
    }
  }
}

class _StepImageRef {
  final String path;

  const _StepImageRef({required this.path});

  factory _StepImageRef.fromJson(Map<String, dynamic> json) {
    return _StepImageRef(
      path: (json['p'] as String?) ?? '',
    );
  }
}
