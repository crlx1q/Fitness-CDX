import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fitness_coach/domain/models/exercise.dart';
import 'package:fitness_coach/domain/models/pose_landmark.dart';
import 'package:fitness_coach/domain/services/exercise_detector.dart';
import 'package:fitness_coach/presentation/providers/app_provider.dart';

/// Provider for exercise tracking during workout
class ExerciseProvider extends ChangeNotifier {
  final AppProvider _appProvider;
  final ExerciseDetector _detector = ExerciseDetector();
  final Uuid _uuid = const Uuid();
  final AudioPlayer _audioPlayer = AudioPlayer();

  int _lastSoundCount = 0;
  int _savedProgress = 0; // Previously saved progress to continue from
  
  ExerciseType _selectedExercise = ExerciseType.pushUp;
  ExerciseTrackingState _trackingState = const ExerciseTrackingState(
    exerciseType: ExerciseType.pushUp,
  );
  bool _isTracking = false;
  bool _isPaused = false;
  DateTime? _sessionStartTime;
  PoseDetectionResult? _lastPose;

  ExerciseProvider(this._appProvider) {
    _detector.onStateChanged = _onTrackingStateChanged;
  }

  // Getters
  ExerciseType get selectedExercise => _selectedExercise;
  ExerciseTrackingState get trackingState => _trackingState;
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  int get currentCount => _trackingState.currentCount + _savedProgress;
  int get sessionCount => _trackingState.currentCount; // Count from this session only
  PoseDetectionResult? get lastPose => _lastPose;
  bool get soundEnabled => _appProvider.settings.soundEnabled;
  int get savedProgress => _savedProgress;

  /// Play rep completion sound
  Future<void> _playRepSound() async {
    if (!soundEnabled) return;
    try {
      // Use system sound via haptic feedback + tone
      await HapticFeedback.mediumImpact();
      await _audioPlayer.play(AssetSource('sounds/rep_complete.mp3'));
    } catch (_) {
      // Fallback to just haptic feedback
      await HapticFeedback.mediumImpact();
    }
  }

  /// Calculate potential reward for current count (including saved progress)
  int get potentialReward {
    return _appProvider.calculateReward(
      _selectedExercise,
      currentCount,
    );
  }

  /// Select exercise type
  void selectExercise(ExerciseType type) {
    _selectedExercise = type;
    _detector.setExercise(type);
    _trackingState = ExerciseTrackingState(exerciseType: type);
    notifyListeners();
  }

  /// Start exercise tracking
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    // Load saved progress for this exercise
    _savedProgress = await _appProvider.storage.getSavedExerciseProgress(_selectedExercise);
    
    _detector.setExercise(_selectedExercise);
    _isTracking = true;
    _isPaused = false;
    _sessionStartTime = DateTime.now();
    _lastSoundCount = _savedProgress;

    notifyListeners();
    return true;
  }
  
  /// Save current progress (for continuing later)
  Future<void> saveProgress() async {
    if (currentCount > 0) {
      await _appProvider.storage.saveExerciseProgress(_selectedExercise, currentCount);
    }
  }

  /// Pause tracking
  void pauseTracking() {
    _isPaused = true;
    notifyListeners();
  }

  /// Resume tracking
  void resumeTracking() {
    _isPaused = false;
    notifyListeners();
  }

  /// Stop tracking and save session
  Future<ExerciseSession?> stopTracking({bool save = true}) async {
    if (!_isTracking) return null;

    _isTracking = false;

    ExerciseSession? session;

    if (save && currentCount > 0 && _sessionStartTime != null) {
      final earnedMinutes = potentialReward;
      final duration = DateTime.now().difference(_sessionStartTime!).inSeconds;

      session = ExerciseSession(
        id: _uuid.v4(),
        type: _selectedExercise,
        count: currentCount, // Use total count including saved progress
        earnedMinutes: earnedMinutes,
        timestamp: DateTime.now(),
        durationSeconds: duration,
      );

      // Save to storage and update user stats
      await _appProvider.recordExercise(session);
      
      // Clear saved progress since we completed the goal
      await _appProvider.storage.clearExerciseProgress(_selectedExercise);
    }

    // Reset state
    _detector.reset();
    _sessionStartTime = null;
    _lastPose = null;
    _savedProgress = 0;

    notifyListeners();
    return session;
  }

  /// Handle pose detection result
  void _onPoseDetected(PoseDetectionResult pose) {
    if (_isPaused) return;
    
    _lastPose = pose;
    _detector.processPose(pose);
    notifyListeners();
  }

  /// Process pose from external source (ML Kit)
  void processPose(PoseDetectionResult pose) {
    if (_isPaused || !_isTracking) return;
    
    _lastPose = pose;
    _detector.processPose(pose);
    notifyListeners();
  }

  /// Handle tracking state change
  void _onTrackingStateChanged(ExerciseTrackingState state) {
    // Check if count increased for sound feedback
    if (state.currentCount > _lastSoundCount && soundEnabled) {
      _lastSoundCount = state.currentCount;
      _playRepSound();
    }
    _trackingState = state;
    notifyListeners();
  }

  /// Reset current session without saving
  void resetSession() {
    _detector.reset();
    _trackingState = ExerciseTrackingState(exerciseType: _selectedExercise);
    notifyListeners();
  }

  @override
  void dispose() {
    _detector.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
