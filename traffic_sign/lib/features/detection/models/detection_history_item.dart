class DetectionHistoryItem {
  const DetectionHistoryItem({
    required this.id,
    required this.label,
    required this.classIndex,
    required this.confidence,
    required this.capturedAt,
    required this.imagePath,
  });

  final String id;
  final String label;
  final int classIndex;
  final double confidence;
  final DateTime capturedAt;
  final String imagePath;

  factory DetectionHistoryItem.fromJson(Map<String, dynamic> json) {
    return DetectionHistoryItem(
      id: json['id'] as String,
      label: json['label'] as String,
      classIndex: (json['classIndex'] as num).toInt(),
      confidence: (json['confidence'] as num).toDouble(),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      imagePath: json['imagePath'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'classIndex': classIndex,
      'confidence': confidence,
      'capturedAt': capturedAt.toIso8601String(),
      'imagePath': imagePath,
    };
  }
}
