import 'dart:math' as math;

/// Represents a single pose landmark point
class PoseLandmark {
  final LandmarkType type;
  final double x; // 0.0 to 1.0 (normalized)
  final double y; // 0.0 to 1.0 (normalized)
  final double z; // Depth (can be negative)
  final double visibility; // 0.0 to 1.0

  const PoseLandmark({
    required this.type,
    required this.x,
    required this.y,
    this.z = 0.0,
    this.visibility = 1.0,
  });

  /// Check if landmark is visible enough to use
  bool get isVisible => visibility > 0.5;

  /// Convert to screen coordinates
  Offset toScreenPosition(double screenWidth, double screenHeight) {
    return Offset(x * screenWidth, y * screenHeight);
  }

  factory PoseLandmark.fromMap(Map<String, dynamic> map) {
    return PoseLandmark(
      type: LandmarkType.values[map['type'] as int],
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      z: (map['z'] as num?)?.toDouble() ?? 0.0,
      visibility: (map['visibility'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'x': x,
      'y': y,
      'z': z,
      'visibility': visibility,
    };
  }
}

/// Simple offset class for screen positions
class Offset {
  final double dx;
  final double dy;

  const Offset(this.dx, this.dy);

  static const Offset zero = Offset(0, 0);
}

/// Landmark types we track (minimal set as required)
/// Only tracking: shoulders, elbows, wrists, hips, knees, ankles
enum LandmarkType {
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

extension LandmarkTypeExtension on LandmarkType {
  /// Map from MediaPipe landmark indices to our minimal set
  static LandmarkType? fromMediaPipeIndex(int index) {
    // MediaPipe pose landmark indices
    const mapping = {
      11: LandmarkType.leftShoulder,
      12: LandmarkType.rightShoulder,
      13: LandmarkType.leftElbow,
      14: LandmarkType.rightElbow,
      15: LandmarkType.leftWrist,
      16: LandmarkType.rightWrist,
      23: LandmarkType.leftHip,
      24: LandmarkType.rightHip,
      25: LandmarkType.leftKnee,
      26: LandmarkType.rightKnee,
      27: LandmarkType.leftAnkle,
      28: LandmarkType.rightAnkle,
    };
    return mapping[index];
  }

  String get displayName {
    switch (this) {
      case LandmarkType.leftShoulder:
        return 'Левое плечо';
      case LandmarkType.rightShoulder:
        return 'Правое плечо';
      case LandmarkType.leftElbow:
        return 'Левый локоть';
      case LandmarkType.rightElbow:
        return 'Правый локоть';
      case LandmarkType.leftWrist:
        return 'Левое запястье';
      case LandmarkType.rightWrist:
        return 'Правое запястье';
      case LandmarkType.leftHip:
        return 'Левый таз';
      case LandmarkType.rightHip:
        return 'Правый таз';
      case LandmarkType.leftKnee:
        return 'Левое колено';
      case LandmarkType.rightKnee:
        return 'Правое колено';
      case LandmarkType.leftAnkle:
        return 'Левая щиколотка';
      case LandmarkType.rightAnkle:
        return 'Правая щиколотка';
    }
  }
}

/// Full pose detection result with all tracked landmarks
class PoseDetectionResult {
  final List<PoseLandmark> landmarks;
  final DateTime timestamp;

  const PoseDetectionResult({
    required this.landmarks,
    required this.timestamp,
  });

  /// Get landmark by type
  PoseLandmark? getLandmark(LandmarkType type) {
    try {
      return landmarks.firstWhere((l) => l.type == type);
    } catch (_) {
      return null;
    }
  }

  /// Check if we have enough landmarks for exercise detection
  bool get hasEnoughLandmarks => landmarks.length >= 6;

  /// Calculate angle between three points (in degrees)
  /// Returns angle at point B in triangle ABC
  static double calculateAngle(
    PoseLandmark a,
    PoseLandmark b,
    PoseLandmark c,
  ) {
    final radians = math.atan2(c.y - b.y, c.x - b.x) -
        math.atan2(a.y - b.y, a.x - b.x);
    var angle = (radians * 180 / math.pi).abs();
    if (angle > 180) {
      angle = 360 - angle;
    }
    return angle;
  }

  /// Get elbow angle (for push-ups)
  double? getLeftElbowAngle() {
    final shoulder = getLandmark(LandmarkType.leftShoulder);
    final elbow = getLandmark(LandmarkType.leftElbow);
    final wrist = getLandmark(LandmarkType.leftWrist);

    if (shoulder == null || elbow == null || wrist == null) return null;
    if (!shoulder.isVisible || !elbow.isVisible || !wrist.isVisible) return null;

    return calculateAngle(shoulder, elbow, wrist);
  }

  double? getRightElbowAngle() {
    final shoulder = getLandmark(LandmarkType.rightShoulder);
    final elbow = getLandmark(LandmarkType.rightElbow);
    final wrist = getLandmark(LandmarkType.rightWrist);

    if (shoulder == null || elbow == null || wrist == null) return null;
    if (!shoulder.isVisible || !elbow.isVisible || !wrist.isVisible) return null;

    return calculateAngle(shoulder, elbow, wrist);
  }

  /// Get average elbow angle
  double? getAverageElbowAngle() {
    final left = getLeftElbowAngle();
    final right = getRightElbowAngle();

    if (left != null && right != null) {
      return (left + right) / 2;
    }
    return left ?? right;
  }

  /// Get knee angle (for squats)
  double? getLeftKneeAngle() {
    final hip = getLandmark(LandmarkType.leftHip);
    final knee = getLandmark(LandmarkType.leftKnee);
    final ankle = getLandmark(LandmarkType.leftAnkle);

    if (hip == null || knee == null || ankle == null) return null;
    if (!hip.isVisible || !knee.isVisible || !ankle.isVisible) return null;

    return calculateAngle(hip, knee, ankle);
  }

  double? getRightKneeAngle() {
    final hip = getLandmark(LandmarkType.rightHip);
    final knee = getLandmark(LandmarkType.rightKnee);
    final ankle = getLandmark(LandmarkType.rightAnkle);

    if (hip == null || knee == null || ankle == null) return null;
    if (!hip.isVisible || !knee.isVisible || !ankle.isVisible) return null;

    return calculateAngle(hip, knee, ankle);
  }

  /// Get average knee angle
  double? getAverageKneeAngle() {
    final left = getLeftKneeAngle();
    final right = getRightKneeAngle();

    if (left != null && right != null) {
      return (left + right) / 2;
    }
    return left ?? right;
  }

  /// Get hip position for plank stability
  double? getHipYPosition() {
    final leftHip = getLandmark(LandmarkType.leftHip);
    final rightHip = getLandmark(LandmarkType.rightHip);

    if (leftHip != null && rightHip != null) {
      return (leftHip.y + rightHip.y) / 2;
    }
    return leftHip?.y ?? rightHip?.y;
  }

  /// Check if body is in horizontal position (for plank)
  bool isBodyHorizontal() {
    final shoulder = getLandmark(LandmarkType.leftShoulder) ?? 
                     getLandmark(LandmarkType.rightShoulder);
    final hip = getLandmark(LandmarkType.leftHip) ?? 
                getLandmark(LandmarkType.rightHip);
    final ankle = getLandmark(LandmarkType.leftAnkle) ?? 
                  getLandmark(LandmarkType.rightAnkle);

    if (shoulder == null || hip == null || ankle == null) return false;

    // Check if shoulder, hip, and ankle are roughly at the same Y level
    final maxDiff = 0.15; // Allow 15% difference
    final shoulderHipDiff = (shoulder.y - hip.y).abs();
    final hipAnkleDiff = (hip.y - ankle.y).abs();

    return shoulderHipDiff < maxDiff && hipAnkleDiff < maxDiff;
  }

  factory PoseDetectionResult.fromMap(Map<String, dynamic> map) {
    final landmarksList = map['landmarks'] as List<dynamic>;
    return PoseDetectionResult(
      landmarks: landmarksList
          .map((l) => PoseLandmark.fromMap(l as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}
