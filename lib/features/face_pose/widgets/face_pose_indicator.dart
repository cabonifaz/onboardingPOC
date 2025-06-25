import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FacePoseIndicator extends StatelessWidget {
  final Face? face;
  final Size imageSize;
  final bool isImageInverted;
  final double rotation;

  const FacePoseIndicator({
    super.key,
    required this.face,
    required this.imageSize,
    this.isImageInverted = false,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (face == null) {
      return const Center(
        child: Text(
          'Coloca tu cara en el marco',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CustomPaint(
      painter: FacePosePainter(
        face: face!,
        imageSize: imageSize,
        isImageInverted: isImageInverted,
        rotation: rotation,
      ),
    );
  }
}

class FacePosePainter extends CustomPainter {
  final Face face;
  final Size imageSize;
  final bool isImageInverted;
  final double rotation;

  FacePosePainter({
    required this.face,
    required this.imageSize,
    required this.isImageInverted,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.green;

    final rect = _calculateRect(
      size: size,
      imageSize: imageSize,
      rotation: rotation,
      isImageInverted: isImageInverted,
      face: face,
    );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(FacePosePainter oldDelegate) => false;

  Rect _calculateRect({
    required Size size,
    required Size imageSize,
    required double rotation,
    required bool isImageInverted,
    required Face face,
  }) {
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    final double x = face.boundingBox.left * scaleX;
    final double y = face.boundingBox.top * scaleY;
    final double width = face.boundingBox.width * scaleX;
    final double height = face.boundingBox.height * scaleY;

    return Rect.fromLTWH(x, y, width, height);
  }
}
