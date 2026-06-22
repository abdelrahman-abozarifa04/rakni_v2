import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

class ImageCropScreen extends StatefulWidget {
  final XFile imageFile;

  const ImageCropScreen({super.key, required this.imageFile});

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final TransformationController _transformationController = TransformationController();
  bool _isProcessing = false;
  Uint8List? _imageBytes;
  int _imageWidth = 0;
  int _imageHeight = 0;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        setState(() {
          _imageBytes = bytes;
          _imageWidth = decoded.width;
          _imageHeight = decoded.height;
        });
      } else {
        _showErrorAndPop('Failed to decode the selected image.');
      }
    } catch (e) {
      _showErrorAndPop('Error loading image: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showErrorAndPop(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
    Navigator.pop(context);
  }

  Future<void> _cropImage(double displayedWidth, double displayedHeight) async {
    if (_imageBytes == null || _imageWidth == 0 || _imageHeight == 0) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Get InteractiveViewer scale and translation matrix values
      final Matrix4 matrix = _transformationController.value;
      final double scale = matrix.getMaxScaleOnAxis();
      final double tx = matrix.entry(0, 3);
      final double ty = matrix.entry(1, 3);

      // 2. Define crop circle size and offsets on screen
      const double cropSize = 280.0;
      final double cropLeft = (displayedWidth - cropSize) / 2;
      final double cropTop = (displayedHeight - cropSize) / 2;

      // 3. Map screen viewport coords back to the displayed image coordinate space
      final double leftInDisplayed = (cropLeft - tx) / scale;
      final double topInDisplayed = (cropTop - ty) / scale;
      final double sizeInDisplayed = cropSize / scale;

      // 4. Calculate ratio between original high-res image and displayed image
      // Note: the displayed image inside InteractiveViewer is fit to screen width
      final double fitScale = _imageWidth / displayedWidth;

      // 5. Crop box in original high-resolution image space
      int x = (leftInDisplayed * fitScale).round();
      int y = (topInDisplayed * fitScale).round();
      int w = (sizeInDisplayed * fitScale).round();
      int h = w; // Keep it square

      // Bound checks to ensure we don't crop outside image edges
      if (x < 0) x = 0;
      if (y < 0) y = 0;
      if (x + w > _imageWidth) w = _imageWidth - x;
      if (y + h > _imageHeight) h = _imageHeight - y;

      // 6. Perform the crop and resize asynchronously using 'image' package
      final decoded = img.decodeImage(_imageBytes!);
      if (decoded != null) {
        final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
        // Resize to 400x400 for fast upload and storage savings
        final resized = img.copyResize(cropped, width: 400, height: 400);
        final croppedJpg = img.encodeJpg(resized, quality: 85);

        if (!mounted) return;
        Navigator.pop(context, croppedJpg);
      } else {
        _showErrorAndPop('Could not process image cropping.');
      }
    } catch (e) {
      _showErrorAndPop('Error cropping image: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double screenWidth = mediaQuery.size.width;
    final double screenHeight = mediaQuery.size.height;

    // We preserve the image aspect ratio when fit to screen width
    final double displayedWidth = screenWidth;
    final double displayedHeight = _imageWidth > 0 
        ? (screenWidth * (_imageHeight / _imageWidth)) 
        : screenHeight * 0.6;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crop Profile Photo',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_imageBytes != null)
            Center(
              child: SizedBox(
                width: displayedWidth,
                height: displayedHeight,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 5.0,
                  boundaryMargin: const EdgeInsets.all(120),
                  child: Image.memory(
                    _imageBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          
          // Custom circular crop mask overlay
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CircularCropMaskPainter(cropCircleSize: 280.0),
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing 
                      ? null 
                      : () => _cropImage(displayedWidth, displayedHeight),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CircularCropMaskPainter extends CustomPainter {
  final double cropCircleSize;

  CircularCropMaskPainter({required this.cropCircleSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Viewport path spanning the entire screen
    final rectPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Circular crop path in the center
    final circlePath = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: cropCircleSize,
          height: cropCircleSize,
        ),
      );

    // Subtract the circular area from the screen overlay
    final differencePath = Path.combine(PathOperation.difference, rectPath, circlePath);
    canvas.drawPath(differencePath, paint);

    // Draw circular border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), cropCircleSize / 2, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CircularCropMaskPainter oldDelegate) =>
      oldDelegate.cropCircleSize != cropCircleSize;
}
