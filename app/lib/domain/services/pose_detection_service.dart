import 'dart:async';
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' as mlkit;
import 'package:fitness_coach/domain/models/pose_landmark.dart' as models;

/// Service for real-time pose detection using ML Kit
class PoseDetectionService {
  mlkit.PoseDetector? _poseDetector;
  bool _isProcessing = false;
  bool _isClosed = false;

  final StreamController<models.PoseDetectionResult> _poseStreamController =
      StreamController<models.PoseDetectionResult>.broadcast();

  Stream<models.PoseDetectionResult> get poseStream => _poseStreamController.stream;

  /// Initialize the pose detector
  void initialize() {
    _poseDetector = mlkit.PoseDetector(
      options: mlkit.PoseDetectorOptions(
        mode: mlkit.PoseDetectionMode.stream,
        model: mlkit.PoseDetectionModel.base,
      ),
    );
    _isClosed = false;
  }

  /// Process camera image for pose detection
  Future<void> processImage(CameraImage image, int rotation, bool isFrontCamera) async {
    if (_poseDetector == null || _isProcessing || _isClosed) return;
    
    _isProcessing = true;
    _lastRotation = rotation;
    _lastIsFrontCamera = isFrontCamera;
    
    try {
      final inputImage = _convertCameraImage(image, rotation, isFrontCamera);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final poses = await _poseDetector!.processImage(inputImage);
      
      if (poses.isNotEmpty && !_isClosed) {
        final pose = poses.first;
        final result = _convertPose(pose, image.width.toDouble(), image.height.toDouble());
        _poseStreamController.add(result);
      }
    } catch (e) {
      print('Pose detection error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Convert CameraImage to InputImage for ML Kit
  mlkit.InputImage? _convertCameraImage(CameraImage image, int rotation, bool isFrontCamera) {
    try {
      final format = mlkit.InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final plane = image.planes.first;
      
      return mlkit.InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: mlkit.InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: mlkit.InputImageRotationValue.fromRawValue(rotation) ?? mlkit.InputImageRotation.rotation0deg,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }

  int _lastRotation = 0;
  bool _lastIsFrontCamera = true;

  /// Convert ML Kit Pose to our PoseDetectionResult
  models.PoseDetectionResult _convertPose(mlkit.Pose pose, double imageWidth, double imageHeight) {
    final landmarks = <models.PoseLandmark>[];
    
    // For Android with rotation, the image dimensions might be swapped
    // ML Kit returns coordinates in the rotated image space
    final bool isRotated = _lastRotation == 90 || _lastRotation == 270;
    final double normalizeWidth = isRotated ? imageHeight : imageWidth;
    final double normalizeHeight = isRotated ? imageWidth : imageHeight;

    for (final entry in pose.landmarks.entries) {
      final landmarkType = models.LandmarkTypeExtension.fromMediaPipeIndex(entry.key.index);
      if (landmarkType != null) {
        final landmark = entry.value;
        
        double x = landmark.x / normalizeWidth;
        double y = landmark.y / normalizeHeight;
        
        // Clamp to valid range
        x = x.clamp(0.0, 1.0);
        y = y.clamp(0.0, 1.0);
        
        landmarks.add(models.PoseLandmark(
          type: landmarkType,
          x: x,
          y: y,
          z: landmark.z,
          visibility: landmark.likelihood,
        ));
      }
    }

    return models.PoseDetectionResult(
      landmarks: landmarks,
      timestamp: DateTime.now(),
    );
  }

  /// Close and dispose resources
  Future<void> close() async {
    _isClosed = true;
    await _poseDetector?.close();
    _poseDetector = null;
  }

  void dispose() {
    close();
    _poseStreamController.close();
  }
}
