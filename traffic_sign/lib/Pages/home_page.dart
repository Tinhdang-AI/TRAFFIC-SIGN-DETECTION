import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traffic_sign/features/detection/models/detection_history_item.dart';
import 'package:traffic_sign/features/detection/controllers/detection_controller.dart';
import 'package:traffic_sign/features/detection/services/detection_history_service.dart';
import 'package:traffic_sign/features/detection/services/yolov8_service.dart';
import 'package:traffic_sign/features/detection/widgets/detection_overlay.dart';
import '../apps/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;
  late DetectionController _detectionController;
  late DetectionHistoryService _historyService;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );

    _historyService = DetectionHistoryService(maxItems: 8);

    _detectionController = DetectionController(
      yoloService: YoloV8Service(
        modelAssetPath: 'assets/models/best59_float16.tflite',
        labelsAssetPath: 'assets/models/labels_59.txt',
      ),
      historyService: _historyService,
    );
    _initializeDetection();
  }

  Future<void> _initializeDetection() async {
    await _detectionController.initialize();
  }

  @override
  void dispose() {
    _detectionController.dispose();
    _historyService.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _detectionController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildCameraSection(),
                    _buildDetectionCard(),
                    _buildQuickLookup(),
                    _buildRecentHistory(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.traffic_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Traffic Sign Detection',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCameraSection() {
    final cameraController = _detectionController.cameraController;
    final isReady = _detectionController.isReady && cameraController != null;
    final isDetecting = _detectionController.isDetecting;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.darkOverlay,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isReady)
              Center(
                child: AspectRatio(
                  aspectRatio: cameraController.value.aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(cameraController),
                      DetectionOverlay(predictions: _detectionController.predictions),
                      CustomPaint(painter: GridPainter()),
                      Center(child: _buildDetectionFrame()),
                    ],
                  ),
                ),
              )
            else
              _buildCameraLoadingState(),

            if (isDetecting)
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: _scanAnimation.value * 180,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.cameraFrame.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            Positioned(
              top: 16,
              right: 16,
              child: _buildDetectionBadge(),
            ),

            if (_detectionController.errorMessage != null)
              Positioned(
                top: 16,
                left: 16,
                right: 120,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _detectionController.errorMessage!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ScaleTransition(
                        scale: isDetecting ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _detectionController.toggleDetection();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDetecting
                                ? AppColors.danger
                                : AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          icon: Icon(
                            isDetecting ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            size: 20,
                          ),
                          label: Text(
                            isDetecting ? 'Dừng nhận diện' : 'Bắt đầu nhận diện',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.flip_camera_ios_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionFrame() {
    return SizedBox(
      width: 140,
      height: 100,
      child: CustomPaint(
        painter: DetectionFramePainter(color: AppColors.cameraFrame),
      ),
    );
  }

  Widget _buildCameraLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D1410),
            Color(0xFF1A2B20),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Đang khởi tạo camera & model...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionBadge() {
    final prediction = _detectionController.topPrediction;
    final isDetecting = _detectionController.isDetecting;
    final hasPrediction = prediction != null;

    final badgeText = hasPrediction
        ? '${_formatLabel(prediction.label)} ${(prediction.score * 100).toStringAsFixed(0)}%'
        : (isDetecting ? 'Đang quét...' : 'Sẵn sàng nhận diện');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasPrediction ? AppColors.primary : Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        boxShadow: hasPrediction
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isDetecting ? Colors.white : Colors.white70,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String label) {
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .where((segment) => segment.isNotEmpty)
        .map((segment) {
          if (segment.length == 1) {
            return segment.toUpperCase();
          }
          return segment[0].toUpperCase() + segment.substring(1);
        })
        .join(' ');
  }

  Widget _buildDetectionCard() {
    final prediction = _detectionController.topPrediction;
    final isDetecting = _detectionController.isDetecting;

    final signLabel = prediction != null ? _formatLabel(prediction.label) : 'Chưa có biển báo nào';
    final signSubLabel = prediction != null
        ? 'Độ tin cậy ${(prediction.score * 100).toStringAsFixed(1)}%'
        : (isDetecting ? 'Đang phân tích khung hình...' : 'Nhấn Bắt đầu nhận diện để chạy YOLOv8');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'VỪA PHÁT HIỆN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 11,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${_detectionController.lastInferenceMs}ms',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Sign icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: prediction != null ? AppColors.primarySurface : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: prediction != null
                        ? AppColors.primary.withOpacity(0.25)
                        : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Icon(
                    prediction != null ? Icons.traffic_rounded : Icons.remove_red_eye_outlined,
                    size: 30,
                    color: prediction != null ? AppColors.primary : AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signLabel,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      signSubLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    prediction != null ? 'Xem chi tiết' : 'Chưa có dữ liệu',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLookup() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tra cứu nhanh',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickChip('Cấm', AppColors.danger, Icons.do_not_disturb_alt_rounded),
              _buildQuickChip('Nguy', AppColors.warning, Icons.warning_amber_rounded),
              _buildQuickChip('Chỉ dẫn', AppColors.info, Icons.info_outline_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHistory() {
    final history = _detectionController.historyItems;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Lịch sử gần đây',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'Tất cả',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: history.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Chưa có lịch sử phát hiện. Khi có biển báo đầu tiên, app sẽ lưu ảnh chụp và thời gian ở đây.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: history.asMap().entries.map((e) {
                      final i = e.key;
                      final item = e.value;
                      return Column(
                        children: [
                          _buildHistoryItem(item: item),
                          if (i < history.length - 1)
                            const Divider(height: 1, indent: 56, endIndent: 16),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({required DetectionHistoryItem item}) {
    final timeText = _formatHistoryTime(item.capturedAt);
    final title = _formatLabel(item.label);
    final previewExists = true;

    return InkWell(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(item.imagePath),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: AppColors.surfaceVariant,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_rounded),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Độ tin cậy ${(item.confidence * 100).toStringAsFixed(1)}% · $timeText',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            );
          },
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 48,
                child: previewExists
                    ? Image.file(
                      File(item.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.primarySurface,
                            child: Icon(
                              Icons.traffic_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppColors.primarySurface,
                        child: Icon(
                          Icons.traffic_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        timeText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        ' · ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        'Tin cậy ${(item.confidence * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatHistoryTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// Custom Painters
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DetectionFramePainter extends CustomPainter {
  final Color color;
  DetectionFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 16.0;
    const radius = 4.0;

    // Top-left
    canvas.drawLine(Offset(radius, 0), Offset(cornerLen, 0), paint);
    canvas.drawLine(Offset(0, radius), Offset(0, cornerLen), paint);
    canvas.drawArc(const Rect.fromLTWH(0, 0, radius * 2, radius * 2), 3.14159, -1.5708, false, paint);

    // Top-right
    canvas.drawLine(Offset(size.width - cornerLen, 0), Offset(size.width - radius, 0), paint);
    canvas.drawLine(Offset(size.width, radius), Offset(size.width, cornerLen), paint);
    canvas.drawArc(Rect.fromLTWH(size.width - radius * 2, 0, radius * 2, radius * 2), -1.5708, -1.5708, false, paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height - cornerLen), Offset(0, size.height - radius), paint);
    canvas.drawLine(Offset(radius, size.height), Offset(cornerLen, size.height), paint);
    canvas.drawArc(Rect.fromLTWH(0, size.height - radius * 2, radius * 2, radius * 2), 1.5708, 1.5708, false, paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height - cornerLen), Offset(size.width, size.height - radius), paint);
    canvas.drawLine(Offset(size.width - cornerLen, size.height), Offset(size.width - radius, size.height), paint);
    canvas.drawArc(Rect.fromLTWH(size.width - radius * 2, size.height - radius * 2, radius * 2, radius * 2), 0, 1.5708, false, paint);
  }

  @override
  bool shouldRepaint(covariant DetectionFramePainter oldDelegate) => false;
}
