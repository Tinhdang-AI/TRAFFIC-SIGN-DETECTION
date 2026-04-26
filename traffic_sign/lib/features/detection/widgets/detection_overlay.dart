import 'package:flutter/material.dart';

import '../models/detection_prediction.dart';

class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({
    super.key,
    required this.predictions,
  });

  final List<DetectionPrediction> predictions;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DetectionOverlayPainter(predictions),
      size: Size.infinite,
    );
  }
}

class _DetectionOverlayPainter extends CustomPainter {
  _DetectionOverlayPainter(this.predictions);

  final List<DetectionPrediction> predictions;

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = const Color(0xFF2ECC71)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final bgPaint = Paint()..color = const Color(0xCC1B6B3A);

    for (final prediction in predictions) {
      final rect = Rect.fromLTRB(
        prediction.boundingBox.left * size.width,
        prediction.boundingBox.top * size.height,
        prediction.boundingBox.right * size.width,
        prediction.boundingBox.bottom * size.height,
      );

      if (rect.width <= 2 || rect.height <= 2) {
        continue;
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        boxPaint,
      );

      final label = '${prediction.label} ${(prediction.score * 100).toStringAsFixed(1)}%';
      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - 8);

      final tagWidth = textPainter.width + 10;
      final tagHeight = textPainter.height + 6;
      final tagRect = Rect.fromLTWH(
        rect.left,
        (rect.top - tagHeight - 2).clamp(0, size.height - tagHeight),
        tagWidth,
        tagHeight,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(tagRect, const Radius.circular(6)),
        bgPaint,
      );
      textPainter.paint(canvas, Offset(tagRect.left + 5, tagRect.top + 3));
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionOverlayPainter oldDelegate) {
    return oldDelegate.predictions != predictions;
  }
}
