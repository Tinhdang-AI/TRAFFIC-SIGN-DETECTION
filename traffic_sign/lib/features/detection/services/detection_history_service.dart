import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/detection_history_item.dart';

class DetectionHistoryService extends ChangeNotifier {
  DetectionHistoryService({this.maxItems = 20});

  final int maxItems;

  Directory? _historyDirectory;
  File? _indexFile;
  bool _isInitialized = false;
  final List<DetectionHistoryItem> _items = [];

  List<DetectionHistoryItem> get items => List.unmodifiable(_items);

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    _historyDirectory = Directory('${documentsDirectory.path}/traffic_sign_history');
    if (!await _historyDirectory!.exists()) {
      await _historyDirectory!.create(recursive: true);
    }

    _indexFile = File('${_historyDirectory!.path}/history_index.json');
    if (await _indexFile!.exists()) {
      final raw = await _indexFile!.readAsString();
      if (raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _items
          ..clear()
          ..addAll(
            decoded
                .whereType<Map<String, dynamic>>()
                .map(DetectionHistoryItem.fromJson),
          );
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<DetectionHistoryItem> addEntry({
    required String label,
    required int classIndex,
    required double confidence,
    required DateTime capturedAt,
    required List<int> imageBytes,
  }) async {
    await initialize();

    final historyDirectory = _historyDirectory;
    if (historyDirectory == null) {
      throw StateError('History directory is not available');
    }

    final id = capturedAt.microsecondsSinceEpoch.toString();
    final imageFile = File('${historyDirectory.path}/$id.jpg');
    await imageFile.writeAsBytes(imageBytes, flush: true);

    final item = DetectionHistoryItem(
      id: id,
      label: label,
      classIndex: classIndex,
      confidence: confidence,
      capturedAt: capturedAt,
      imagePath: imageFile.path,
    );

    _items.insert(0, item);
    while (_items.length > maxItems) {
      final removed = _items.removeLast();
      await _deleteFile(removed.imagePath);
    }

    await _persistIndex();
    notifyListeners();
    return item;
  }

  Future<void> clear() async {
    await initialize();

    for (final item in _items) {
      await _deleteFile(item.imagePath);
    }

    _items.clear();
    await _persistIndex();
    notifyListeners();
  }

  Future<void> _persistIndex() async {
    final indexFile = _indexFile;
    if (indexFile == null) {
      return;
    }

    final encoded = jsonEncode(_items.map((item) => item.toJson()).toList());
    await indexFile.writeAsString(encoded, flush: true);
  }

  Future<void> _deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
