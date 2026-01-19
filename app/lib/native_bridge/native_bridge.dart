import 'dart:async';
import 'package:flutter/services.dart';
import 'package:fitness_coach/core/constants/app_constants.dart';
import 'package:fitness_coach/domain/models/pose_landmark.dart';
import 'package:fitness_coach/domain/models/blocked_app.dart';

/// Bridge to native Android functionality via MethodChannel
class NativeBridge {
  static NativeBridge? _instance;
  
  final MethodChannel _channel = const MethodChannel(AppConstants.methodChannelName);
  
  // Stream controllers for pose detection
  final StreamController<PoseDetectionResult> _poseStreamController = 
      StreamController<PoseDetectionResult>.broadcast();
  
  // Stream controller for time changes
  final StreamController<int> _timeChangedController = 
      StreamController<int>.broadcast();
  
  NativeBridge._() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static NativeBridge get instance {
    _instance ??= NativeBridge._();
    return _instance!;
  }

  /// Stream of pose detection results
  Stream<PoseDetectionResult> get poseStream => _poseStreamController.stream;
  
  /// Stream of time changes from native (when user uses blocked apps)
  Stream<int> get timeChangedStream => _timeChangedController.stream;

  /// Handle incoming method calls from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPoseDetected':
        final data = Map<String, dynamic>.from(call.arguments as Map);
        final result = PoseDetectionResult.fromMap(data);
        _poseStreamController.add(result);
        break;
      case 'onAppBlocked':
        // App was blocked - can trigger UI update
        break;
      case 'onTimeChanged':
        final data = Map<String, dynamic>.from(call.arguments as Map);
        final minutes = data['minutes'] as int? ?? 0;
        _timeChangedController.add(minutes);
        break;
      default:
        throw PlatformException(
          code: 'NotImplemented',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  // ============ Pose Detection ============

  /// Start pose detection with camera
  Future<bool> startPoseDetection() async {
    try {
      final result = await _channel.invokeMethod<bool>('startPoseDetection');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to start pose detection: ${e.message}');
      return false;
    }
  }

  /// Stop pose detection
  Future<void> stopPoseDetection() async {
    try {
      await _channel.invokeMethod('stopPoseDetection');
    } on PlatformException catch (e) {
      print('Failed to stop pose detection: ${e.message}');
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    try {
      await _channel.invokeMethod('switchCamera');
    } on PlatformException catch (e) {
      print('Failed to switch camera: ${e.message}');
    }
  }

  // ============ App Blocking ============

  /// Get list of installed apps
  Future<List<InstalledApp>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      if (result == null) return [];
      
      return result.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return InstalledApp(
          packageName: map['packageName'] as String,
          appName: map['appName'] as String,
          isSystemApp: map['isSystemApp'] as bool? ?? false,
          todayUsageMinutes: (map['todayUsageMinutes'] as num?)?.toInt() ?? 0,
          iconBase64: map['iconBase64'] as String?,
        );
      }).toList();
    } on PlatformException catch (e) {
      print('Failed to get installed apps: ${e.message}');
      return [];
    }
  }

  /// Set apps to block
  Future<bool> setBlockedApps(List<String> packageNames) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setBlockedApps',
        {'packages': packageNames},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to set blocked apps: ${e.message}');
      return false;
    }
  }

  /// Set available time in minutes
  Future<bool> setAvailableTime(int minutes) async {
    try {
      final result = await _channel.invokeMethod('setAvailableTime', {
        'minutes': minutes,
      });
      return result == true;
    } catch (e) {
      print('Error setting available time: $e');
      return false;
    }
  }

  /// Get available time from native SharedPreferences
  /// Used to sync FROM native on app startup (fixes sync bug)
  Future<int> getAvailableTime() async {
    try {
      final result = await _channel.invokeMethod<int>('getAvailableTime');
      return result ?? 0;
    } catch (e) {
      print('Error getting available time: $e');
      return -1; // Return -1 to indicate error (don't sync)
    }
  }

  /// Get total usage minutes for blocked apps today
  Future<int> getBlockedAppsUsage() async {
    try {
      final result = await _channel.invokeMethod('getBlockedAppsUsage');
      return (result as int?) ?? 0;
    } catch (e) {
      print('Error getting blocked apps usage: $e');
      return 0;
    }
  }

  /// Check usage stats and deduct time spent in blocked apps
  /// Returns the number of minutes deducted
  Future<int> checkAndDeductTime() async {
    try {
      final result = await _channel.invokeMethod('checkAndDeductTime');
      return (result as int?) ?? 0;
    } catch (e) {
      print('Error checking and deducting time: $e');
      return 0;
    }
  }

  /// Check if accessibility service is enabled
  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to check accessibility service: ${e.message}');
      return false;
    }
  }

  /// Open accessibility settings
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      print('Failed to open accessibility settings: ${e.message}');
    }
  }

  /// Check if usage stats permission is granted
  Future<bool> isUsageStatsPermissionGranted() async {
    try {
      final result = await _channel.invokeMethod<bool>('isUsageStatsPermissionGranted');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to check usage stats permission: ${e.message}');
      return false;
    }
  }

  /// Open usage stats settings
  Future<void> openUsageStatsSettings() async {
    try {
      await _channel.invokeMethod('openUsageStatsSettings');
    } on PlatformException catch (e) {
      print('Failed to open usage stats settings: ${e.message}');
    }
  }

  /// Start blocking service
  Future<bool> startBlockingService() async {
    try {
      final result = await _channel.invokeMethod<bool>('startBlockingService');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to start blocking service: ${e.message}');
      return false;
    }
  }

  /// Stop blocking service
  Future<void> stopBlockingService() async {
    try {
      await _channel.invokeMethod('stopBlockingService');
    } on PlatformException catch (e) {
      print('Failed to stop blocking service: ${e.message}');
    }
  }

  /// Get current foreground app package name
  Future<String?> getCurrentForegroundApp() async {
    try {
      final result = await _channel.invokeMethod<String>('getCurrentForegroundApp');
      return result;
    } on PlatformException catch (e) {
      print('Failed to get foreground app: ${e.message}');
      return null;
    }
  }

  // ============ Cleanup ============

  void dispose() {
    _poseStreamController.close();
    _timeChangedController.close();
  }
}
