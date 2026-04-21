import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class CustomCameraScreen extends StatefulWidget {
  const CustomCameraScreen({super.key});

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  CameraController? _controller;
  bool _loading = true;
  bool _takingPhoto = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await Permission.camera.request();
    await Permission.photos.request();

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No camera found on this device.')),
      );
      Navigator.pop(context);
      return;
    }

    final controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller.initialize();

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _controller = controller;
      _loading = false;
    });
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _takingPhoto) {
      return;
    }

    setState(() => _takingPhoto = true);

    try {
      final file = await controller.takePicture();

      final bytes = await File(file.path).readAsBytes();
      final original = img.decodeImage(bytes);

      if (original == null) {
        if (!mounted) return;
        Navigator.pop(context, File(file.path));
        return;
      }

      final media = MediaQuery.of(context);
      final screenW = media.size.width;
      final screenH = media.size.height - media.padding.top - media.padding.bottom;

      final previewAspect = 1 / controller.value.aspectRatio;

      double previewW = screenW;
      double previewH = previewW / previewAspect;

      if (previewH < screenH) {
        previewH = screenH;
        previewW = previewH * previewAspect;
      }

      final squareSize = screenW * 0.80;
      final squareLeftOnScreen = (screenW - squareSize) / 2;
      final squareTopOnScreen = (screenH - squareSize) / 2;

      final previewLeft = (screenW - previewW) / 2;
      final previewTop = (screenH - previewH) / 2;

      final cropLeftInPreview = squareLeftOnScreen - previewLeft;
      final cropTopInPreview = squareTopOnScreen - previewTop;

      final scaleX = original.width / previewW;
      final scaleY = original.height / previewH;

      int cropX = (cropLeftInPreview * scaleX).round();
      int cropY = (cropTopInPreview * scaleY).round();
      int cropW = (squareSize * scaleX).round();
      int cropH = (squareSize * scaleY).round();

      cropX = cropX.clamp(0, original.width - 1);
      cropY = cropY.clamp(0, original.height - 1);
      cropW = cropW.clamp(1, original.width - cropX);
      cropH = cropH.clamp(1, original.height - cropY);

      final cropSize = cropW < cropH ? cropW : cropH;

      final cropped = img.copyCrop(
        original,
        x: cropX,
        y: cropY,
        width: cropSize,
        height: cropSize,
      );

      final outPath = file.path.replaceFirst(
        RegExp(r'\.(jpg|jpeg)$', caseSensitive: false),
        '_cropped.jpg',
      );
      final finalPath = outPath == file.path ? '${file.path}_cropped.jpg' : outPath;

      final croppedFile = File(finalPath);
      await croppedFile.writeAsBytes(img.encodeJpg(cropped), flush: true);

      try {
        await Gal.putImage(croppedFile.path);
      } catch (_) {
        // Keep workflow going even if gallery save fails.
      }

      if (!mounted) return;
      Navigator.pop(context, croppedFile);
    } finally {
      if (mounted) {
        setState(() => _takingPhoto = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (_loading || controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenW = constraints.maxWidth;
            final screenH = constraints.maxHeight;

            final previewAspect = 1 / controller.value.aspectRatio;

            double previewW = screenW;
            double previewH = previewW / previewAspect;

            if (previewH < screenH) {
              previewH = screenH;
              previewW = previewH * previewAspect;
            }

            final squareSize = screenW * 0.80;

            return Stack(
              children: [
                Positioned.fill(
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.center,
                      minWidth: previewW,
                      maxWidth: previewW,
                      minHeight: previewH,
                      maxHeight: previewH,
                      child: SizedBox(
                        width: previewW,
                        height: previewH,
                        child: CameraPreview(controller),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _CameraOverlayPainter(squareSize: squareSize),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 28,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Keep the important part inside the square',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _takingPhoto ? null : _takePhoto,
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: _takingPhoto ? Colors.white54 : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black26, width: 4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CameraOverlayPainter extends CustomPainter {
  final double squareSize;

  const _CameraOverlayPainter({
    required this.squareSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.45);
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final left = (size.width - squareSize) / 2;
    final top = (size.height - squareSize) / 2;
    final squareRect = Rect.fromLTWH(left, top, squareSize, squareSize);

    final fullPath = Path()..addRect(Offset.zero & size);
    final squarePath = Path()..addRect(squareRect);
    final overlayPath = Path.combine(
      PathOperation.difference,
      fullPath,
      squarePath,
    );

    canvas.drawPath(overlayPath, overlayPaint);
    canvas.drawRect(squareRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CameraOverlayPainter oldDelegate) {
    return oldDelegate.squareSize != squareSize;
  }
}
