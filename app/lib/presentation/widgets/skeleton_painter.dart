import 'package:flutter/material.dart';
import 'package:fitness_coach/domain/models/pose_landmark.dart' as pose;
import 'package:fitness_coach/core/theme/app_theme.dart';

/// Custom painter for drawing stick figure skeleton overlay
class SkeletonPainter extends CustomPainter {
  final pose.PoseDetectionResult? poseResult;
  final bool mirrorMode;

  SkeletonPainter({
    this.poseResult,
    this.mirrorMode = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (poseResult == null || poseResult!.landmarks.isEmpty) return;

    final pointPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final linePaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final landmarks = poseResult!.landmarks;
    
    // Widget is now properly sized via AspectRatio wrapper, so we use full size
    final drawWidth = size.width;
    final drawHeight = size.height;

    // Draw connections (bones)
    _drawConnections(canvas, landmarks, linePaint, drawWidth, drawHeight);

    // Draw joint points
    for (final landmark in landmarks) {
      if (!landmark.isVisible) continue;

      final x = mirrorMode ? (1 - landmark.x) * drawWidth : landmark.x * drawWidth;
      final y = landmark.y * drawHeight;

      canvas.drawCircle(Offset(x, y), 6, pointPaint);
    }
  }

  void _drawConnections(
    Canvas canvas,
    List<pose.PoseLandmark> landmarks,
    Paint paint,
    double drawWidth,
    double drawHeight,
  ) {
    // Define bone connections for stick figure
    final connections = [
      // Torso
      [pose.LandmarkType.leftShoulder, pose.LandmarkType.rightShoulder],
      [pose.LandmarkType.leftShoulder, pose.LandmarkType.leftHip],
      [pose.LandmarkType.rightShoulder, pose.LandmarkType.rightHip],
      [pose.LandmarkType.leftHip, pose.LandmarkType.rightHip],
      
      // Left arm
      [pose.LandmarkType.leftShoulder, pose.LandmarkType.leftElbow],
      [pose.LandmarkType.leftElbow, pose.LandmarkType.leftWrist],
      
      // Right arm
      [pose.LandmarkType.rightShoulder, pose.LandmarkType.rightElbow],
      [pose.LandmarkType.rightElbow, pose.LandmarkType.rightWrist],
      
      // Left leg
      [pose.LandmarkType.leftHip, pose.LandmarkType.leftKnee],
      [pose.LandmarkType.leftKnee, pose.LandmarkType.leftAnkle],
      
      // Right leg
      [pose.LandmarkType.rightHip, pose.LandmarkType.rightKnee],
      [pose.LandmarkType.rightKnee, pose.LandmarkType.rightAnkle],
    ];

    for (final connection in connections) {
      final start = _getLandmark(landmarks, connection[0]);
      final end = _getLandmark(landmarks, connection[1]);

      if (start == null || end == null) continue;
      if (!start.isVisible || !end.isVisible) continue;

      final startX = mirrorMode ? (1 - start.x) * drawWidth : start.x * drawWidth;
      final startY = start.y * drawHeight;
      final endX = mirrorMode ? (1 - end.x) * drawWidth : end.x * drawWidth;
      final endY = end.y * drawHeight;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  pose.PoseLandmark? _getLandmark(
    List<pose.PoseLandmark> landmarks,
    pose.LandmarkType type,
  ) {
    try {
      return landmarks.firstWhere((l) => l.type == type);
    } catch (_) {
      return null;
    }
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) {
    return oldDelegate.poseResult != poseResult;
  }
}

/// Widget for skeleton overlay on camera preview
class SkeletonOverlay extends StatelessWidget {
  final pose.PoseDetectionResult? poseResult;
  final bool mirrorMode;

  const SkeletonOverlay({
    super.key,
    this.poseResult,
    this.mirrorMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SkeletonPainter(
        poseResult: poseResult,
        mirrorMode: mirrorMode,
      ),
      size: Size.infinite,
    );
  }
}
