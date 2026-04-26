import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../models/detection_prediction.dart';
import '../services/yolov8_service.dart';

class DetectionController extends ChangeNotifier {
  DetectionController({required YoloV8Service yoloService}) : _yoloService = yoloService;

  final YoloV8Service _yoloService;

  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;

  bool _isReady = false;
  bool get isReady => _isReady;

  bool _isDetecting = false;
  bool get isDetecting => _isDetecting;

  bool _isProcessingFrame = false;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _lastInferenceMs = 0;
  int get lastInferenceMs => _lastInferenceMs;

  DateTime? _lastFrameAt;
  DateTime? _lastUiUpdateAt;
  final Duration _minFrameInterval = const Duration(milliseconds: 260);
  final Duration _minUiUpdateInterval = const Duration(milliseconds: 220);

  List<DetectionPrediction> _predictions = const [];
  List<DetectionPrediction> get predictions => _predictions;

  DetectionPrediction? get topPrediction =>
      _predictions.isEmpty ? null : _predictions.first;

  Future<void> initialize() async {
    if (_isReady) {
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera found on this device.');
      }

      final rearCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        rearCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();
      await _yoloService.load();

      _cameraController = controller;
      _isReady = true;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isReady = false;
      notifyListeners();
    }
  }

  Future<void> toggleDetection() async {
    if (!_isReady) {
      return;
    }

    if (_isDetecting) {
      await stopDetection();
      return;
    }

    await startDetection();
  }

  Future<void> startDetection() async {
    final controller = _cameraController;
    if (controller == null || _isDetecting) {
      return;
    }

    try {
      _isDetecting = true;
      _errorMessage = null;
      notifyListeners();

      await controller.startImageStream(_onFrame);
    } catch (e) {
      _isDetecting = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> stopDetection() async {
    final controller = _cameraController;
    if (controller == null || !_isDetecting) {
      return;
    }

    try {
      await controller.stopImageStream();
    } catch (_) {
      // Ignore stop stream failures during lifecycle transitions.
    }

    _isDetecting = false;
    _isProcessingFrame = false;
    _predictions = const [];
    notifyListeners();
  }

  Future<void> _onFrame(CameraImage image) async {
    if (!_isDetecting || _isProcessingFrame) {
      return;
    }

    final now = DateTime.now();
    if (_lastFrameAt != null && now.difference(_lastFrameAt!) < _minFrameInterval) {
      return;
    }

    _lastFrameAt = now;
    _isProcessingFrame = true;

    try {
      final result = await _yoloService.runOnFrame(image);
      _predictions = result.predictions;
      _lastInferenceMs = result.inferenceTimeMs;
      _errorMessage = null;

      final nowForUi = DateTime.now();
      if (_lastUiUpdateAt == null ||
          nowForUi.difference(_lastUiUpdateAt!) >= _minUiUpdateInterval) {
        _lastUiUpdateAt = nowForUi;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isProcessingFrame = false;
    }
  }

  @override
  void dispose() {
    unawaited(_disposeAsync());
    super.dispose();
  }

  Future<void> _disposeAsync() async {
    await stopDetection();
    await _cameraController?.dispose();
    await _yoloService.dispose();
  }
}
