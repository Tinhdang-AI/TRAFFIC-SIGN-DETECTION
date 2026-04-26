import 'detection_prediction.dart';

class DetectionFrameResult {
  const DetectionFrameResult({
    required this.predictions,
    required this.inferenceTimeMs,
  });

  final List<DetectionPrediction> predictions;
  final int inferenceTimeMs;
}
