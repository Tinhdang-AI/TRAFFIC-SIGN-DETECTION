import 'dart:ui';

class DetectionPrediction {
  const DetectionPrediction({
    required this.label,
    required this.classIndex,
    required this.score,
    required this.boundingBox,
  });

  final String label;
  final int classIndex;
  final double score;

  // Normalized coordinates in [0, 1].
  final Rect boundingBox;
}
