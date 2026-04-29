import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/detection_frame_result.dart';
import '../models/detection_prediction.dart';

class YoloV8Service {
  YoloV8Service({
    required this.modelAssetPath,
    required this.labelsAssetPath,
    this.confidenceThreshold = 0.12,
    this.iouThreshold = 0.35,
    this.maxDetections = 20,
    this.numThreads = 4,
  });

  final String modelAssetPath;
  final String labelsAssetPath;
  final double confidenceThreshold;
  final double iouThreshold;
  final int maxDetections;
  final int numThreads;

  Interpreter? _interpreter;
  List<String> _labels = const [];
  late int _inputWidth;
  late int _inputHeight;
  late TensorType _inputType;

  bool get isReady => _interpreter != null;

  Future<void> load() async {
    if (isReady) {
      return;
    }

    final options = InterpreterOptions()..threads = numThreads;
    _interpreter = await Interpreter.fromAsset(modelAssetPath, options: options);
    _labels = await _loadLabels(labelsAssetPath);

    final inputShape = _interpreter!.getInputTensor(0).shape;
    if (inputShape.length != 4) {
      throw StateError('Unsupported YOLO input shape: $inputShape');
    }

    _inputHeight = inputShape[1];
    _inputWidth = inputShape[2];
    _inputType = _interpreter!.getInputTensor(0).type;
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
  }

  Future<DetectionFrameResult> runOnFrame(CameraImage frame) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('YOLO interpreter is not loaded');
    }

    final startedAt = DateTime.now();
    final resized = _cameraImageToModelInput(frame);

    final input = _buildInputTensor(resized);
    final outputTensor = interpreter.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    final output = _createOutputBuffer(outputShape, outputTensor.type);

    interpreter.run(input, output);

    final rawPredictions = _decodeYoloPredictions(output, outputShape);
    final predictions = rawPredictions.where((p) => p.score >= confidenceThreshold).toList();
    final effectivePredictions = predictions.isNotEmpty
      ? predictions
      : (rawPredictions.isNotEmpty ? [rawPredictions.first] : const <DetectionPrediction>[]);

    final suppressed = _applyNms(effectivePredictions, iouThreshold)
        .take(maxDetections)
        .toList(growable: false);

    return DetectionFrameResult(
      predictions: suppressed,
      inferenceTimeMs: DateTime.now().difference(startedAt).inMilliseconds,
    );
  }

  List<dynamic> _buildInputTensor(img.Image image) {
    if (_inputType == TensorType.float32) {
      return [
        List.generate(_inputHeight, (y) {
          return List.generate(_inputWidth, (x) {
            final pixel = image.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          });
        }),
      ];
    }

    return [
      List.generate(_inputHeight, (y) {
        return List.generate(_inputWidth, (x) {
          final pixel = image.getPixel(x, y);
          return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
        });
      }),
    ];
  }

  List<DetectionPrediction> _decodeYoloPredictions(dynamic output, List<int> shape) {
    if (shape.length != 3 || shape[0] != 1) {
      throw StateError('Unsupported YOLO output shape: $shape');
    }

    final rows = shape[1];
    final cols = shape[2];
    final List<DetectionPrediction> predictions = [];
    final hasObjectness = rows == _labels.length + 5 || cols == _labels.length + 5;
    // Debug: print raw output shape
    try {
      // ignore: avoid_print
      print('YOLO raw output shape: $shape');
    } catch (_) {}

    // Handle common compact export format [1, N, 6] where each row is
    // [cx, cy, w, h, score, classIndex]. Many TFLite YOLO exports use this.
    if (cols == 6) {
      try {
        // print first few rows for debugging
        for (var j = 0; j < math.min(rows, 3); j++) {
          final a0 = _asDouble(output[0][j][0]);
          final a1 = _asDouble(output[0][j][1]);
          final a2 = _asDouble(output[0][j][2]);
          final a3 = _asDouble(output[0][j][3]);
          final a4 = _asDouble(output[0][j][4]);
          final a5 = _asDouble(output[0][j][5]);
          // ignore: avoid_print
          print('YOLO row $j -> cx:$a0 cy:$a1 w:$a2 h:$a3 score:$a4 cls:$a5');
        }
      } catch (_) {}
      for (var i = 0; i < rows; i++) {
        final cx = _asDouble(output[0][i][0]);
        final cy = _asDouble(output[0][i][1]);
        final w = _asDouble(output[0][i][2]);
        final h = _asDouble(output[0][i][3]);
        final score = _normalizeScore(_asDouble(output[0][i][4]));
        final clsVal = _asDouble(output[0][i][5]);
        final classIndex = clsVal.isFinite ? clsVal.round() : -1;
        if (score >= confidenceThreshold && classIndex >= 0) {
          final rect = _toNormalizedRect(cx, cy, w, h);
          final label = _labelForClass(classIndex);
          // ignore: avoid_print
          print('Decoded detection -> class:$classIndex label:$label score:$score');
          predictions.add(DetectionPrediction(
            label: label,
            classIndex: classIndex,
            score: score,
            boundingBox: rect,
          ));
        }
      }
      return predictions;
    }

    // YOLOv8 TFLite commonly exports [1, 84, 8400] or [1, 8400, 84].
    if (rows <= 128 && cols > rows) {
      final numClasses = hasObjectness ? rows - 5 : rows - 4;
      for (var i = 0; i < cols; i++) {
        final cx = _asDouble(output[0][0][i]);
        final cy = _asDouble(output[0][1][i]);
        final w = _asDouble(output[0][2][i]);
        final h = _asDouble(output[0][3][i]);
        final objectness = hasObjectness ? _normalizeScore(_asDouble(output[0][4][i])) : 1.0;

        var bestClass = -1;
        var bestScore = 0.0;
        for (var c = 0; c < numClasses; c++) {
          final scoreIndex = hasObjectness ? c + 5 : c + 4;
          final score = _normalizeScore(_asDouble(output[0][scoreIndex][i]));
          if (score > bestScore) {
            bestScore = score;
            bestClass = c;
          }
        }

        if (bestClass >= 0) {
          final rect = _toNormalizedRect(cx, cy, w, h);
          predictions.add(
            DetectionPrediction(
              label: _labelForClass(bestClass),
              classIndex: bestClass,
              score: (bestScore * objectness).clamp(0.0, 1.0),
              boundingBox: rect,
            ),
          );
        }
      }
      return predictions;
    }

    final numClasses = hasObjectness ? cols - 5 : cols - 4;
    for (var i = 0; i < rows; i++) {
      final cx = _asDouble(output[0][i][0]);
      final cy = _asDouble(output[0][i][1]);
      final w = _asDouble(output[0][i][2]);
      final h = _asDouble(output[0][i][3]);
      final objectness = hasObjectness ? _normalizeScore(_asDouble(output[0][i][4])) : 1.0;

      var bestClass = -1;
      var bestScore = 0.0;
      for (var c = 0; c < numClasses; c++) {
        final scoreIndex = hasObjectness ? c + 5 : c + 4;
        final score = _normalizeScore(_asDouble(output[0][i][scoreIndex]));
        if (score > bestScore) {
          bestScore = score;
          bestClass = c;
        }
      }

      if (bestClass >= 0) {
        final rect = _toNormalizedRect(cx, cy, w, h);
        predictions.add(
          DetectionPrediction(
            label: _labelForClass(bestClass),
            classIndex: bestClass,
            score: (bestScore * objectness).clamp(0.0, 1.0),
            boundingBox: rect,
          ),
        );
      }
    }

    return predictions;
  }

  List<DetectionPrediction> _applyNms(List<DetectionPrediction> input, double iouThreshold) {
    if (input.isEmpty) {
      return const [];
    }

    final sorted = [...input]..sort((a, b) => b.score.compareTo(a.score));
    final selected = <DetectionPrediction>[];

    while (sorted.isNotEmpty) {
      final current = sorted.removeAt(0);
      selected.add(current);
      sorted.removeWhere((candidate) {
        if (candidate.classIndex != current.classIndex) {
          return false;
        }
        return _iou(current.boundingBox, candidate.boundingBox) >= iouThreshold;
      });
    }

    return selected;
  }

  double _iou(Rect a, Rect b) {
    final intersection = a.intersect(b);
    if (intersection.isEmpty) {
      return 0.0;
    }

    final intersectionArea = intersection.width * intersection.height;
    final unionArea = (a.width * a.height) + (b.width * b.height) - intersectionArea;
    if (unionArea <= 0) {
      return 0.0;
    }
    return intersectionArea / unionArea;
  }

  Rect _toNormalizedRect(double cx, double cy, double w, double h) {
    final left = ((cx - w / 2) / _inputWidth).clamp(0.0, 1.0);
    final top = ((cy - h / 2) / _inputHeight).clamp(0.0, 1.0);
    final right = ((cx + w / 2) / _inputWidth).clamp(0.0, 1.0);
    final bottom = ((cy + h / 2) / _inputHeight).clamp(0.0, 1.0);
    return Rect.fromLTRB(left, top, right, bottom);
  }

  img.Image _cameraImageToRgb(CameraImage image) {
    return _cameraImageToModelInput(image);
  }

  img.Image _cameraImageToModelInput(CameraImage image) {
    if (image.format.group == ImageFormatGroup.yuv420) {
      return _yuv420ToModelInput(image);
    }

    if (image.format.group == ImageFormatGroup.bgra8888) {
      return _bgra8888ToModelInput(image);
    }

    throw UnsupportedError('Unsupported camera image format: ${image.format.group}');
  }

  img.Image _bgra8888ToImage(CameraImage image) {
    return _bgra8888ToModelInput(image);
  }

  img.Image _bgra8888ToModelInput(CameraImage image) {
    final plane = image.planes.first;
    final bytes = plane.bytes;
    final srcWidth = image.width;
    final srcHeight = image.height;
    final out = img.Image(width: _inputWidth, height: _inputHeight);
    final rowStride = plane.bytesPerRow;

    for (var y = 0; y < _inputHeight; y++) {
      final sy = (y * srcHeight) ~/ _inputHeight;
      final rowOffset = sy * rowStride;
      for (var x = 0; x < _inputWidth; x++) {
        final sx = (x * srcWidth) ~/ _inputWidth;
        final pixelIndex = rowOffset + sx * 4;
        final b = bytes[pixelIndex];
        final g = bytes[pixelIndex + 1];
        final r = bytes[pixelIndex + 2];
        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return out;
  }

  img.Image _yuv420ToImage(CameraImage image) {
    return _yuv420ToModelInput(image);
  }

  img.Image _yuv420ToModelInput(CameraImage image) {
    final srcWidth = image.width;
    final srcHeight = image.height;
    final out = img.Image(width: _inputWidth, height: _inputHeight);

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (var y = 0; y < _inputHeight; y++) {
      final sy = (y * srcHeight) ~/ _inputHeight;
      final yRow = sy * yRowStride;
      final uvRow = (sy >> 1) * uvRowStride;

      for (var x = 0; x < _inputWidth; x++) {
        final sx = (x * srcWidth) ~/ _inputWidth;
        final uvOffset = uvRow + (sx >> 1) * uvPixelStride;
        final yp = yBytes[yRow + sx];
        final up = uBytes[uvOffset];
        final vp = vBytes[uvOffset];

        final r = (yp + 1.402 * (vp - 128)).round().clamp(0, 255);
        final g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128))
            .round()
            .clamp(0, 255);
        final b = (yp + 1.772 * (up - 128)).round().clamp(0, 255);

        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return out;
  }

  dynamic _createOutputBuffer(List<int> shape, TensorType type) {
    if (shape.isEmpty) {
      throw StateError('Invalid output tensor shape');
    }

    if (shape.length == 1) {
        return type == TensorType.float32
          ? List<double>.filled(shape[0], 0.0)
          : List<int>.filled(shape[0], 0);
    }

    final dim = shape.first;
    final subShape = shape.sublist(1);
    return List.generate(dim, (_) => _createOutputBuffer(subShape, type));
  }

  Future<List<String>> _loadLabels(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  String _labelForClass(int classIndex) {
    if (classIndex >= 0 && classIndex < _labels.length) {
      return _labels[classIndex];
    }
    return 'class_$classIndex';
  }

  double _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is Uint8List) {
      return value.first.toDouble();
    }
    throw StateError('Unsupported tensor value type: ${value.runtimeType}');
  }

  double _normalizeScore(double value) {
    if (!value.isFinite) {
      return 0.0;
    }

    if (value >= 0.0 && value <= 1.0) {
      return value;
    }

    return 1.0 / (1.0 + math.exp(-value));
  }
}
