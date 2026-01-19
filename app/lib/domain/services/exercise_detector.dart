import 'dart:async';
import 'package:fitness_coach/core/constants/app_constants.dart';
import 'package:fitness_coach/domain/models/exercise.dart';
import 'package:fitness_coach/domain/models/pose_landmark.dart';

/// Service for detecting and counting exercises from pose data
class ExerciseDetector {
  ExerciseType _currentExercise = ExerciseType.pushUp;
  ExercisePhase _phase = ExercisePhase.idle;
  int _repCount = 0;
  int _plankHoldSeconds = 0;
  
  // For plank stability tracking
  double? _lastHipY;
  DateTime? _plankStartTime;
  Timer? _plankTimer;
  
  // Anti-cheat: require full range of motion
  bool _hasReachedDown = false;
  bool _hasReachedUp = true; // Start in up position
  
  // Callbacks
  Function(ExerciseTrackingState)? onStateChanged;
  
  ExerciseDetector();

  ExerciseType get currentExercise => _currentExercise;
  int get repCount => _repCount;
  int get plankHoldSeconds => _plankHoldSeconds;

  /// Set the exercise type to detect
  void setExercise(ExerciseType type) {
    _currentExercise = type;
    reset();
  }

  /// Reset counters
  void reset() {
    _phase = ExercisePhase.idle;
    _repCount = 0;
    _plankHoldSeconds = 0;
    _activitySeconds = 0;
    _hasReachedDown = false;
    _hasReachedUp = true;
    _lastHipY = null;
    _lastWristY = null;
    _lastAnkleY = null;
    _plankStartTime = null;
    _activityStartTime = null;
    _lastMovementTime = null;
    _movementCount = 0;
    _plankTimer?.cancel();
    _plankTimer = null;
    _activityTimer?.cancel();
    _activityTimer = null;
    _emitState();
  }

  /// Process pose detection result
  void processPose(PoseDetectionResult pose) {
    if (!pose.hasEnoughLandmarks) {
      _emitState(feedback: 'Встаньте так, чтобы камера видела всё тело');
      return;
    }

    switch (_currentExercise) {
      case ExerciseType.pushUp:
        _processPushUp(pose);
        break;
      case ExerciseType.squat:
      case ExerciseType.lunge:
        _processSquat(pose);
        break;
      case ExerciseType.plank:
        _processPlank(pose);
        break;
      case ExerciseType.jumpingJack:
        _processJumpingJack(pose);
        break;
      case ExerciseType.highKnees:
        _processHighKnees(pose);
        break;
      case ExerciseType.freeActivity:
        _processFreeActivity(pose);
        break;
    }
  }

  /// Process push-up detection
  void _processPushUp(PoseDetectionResult pose) {
    final elbowAngle = pose.getAverageElbowAngle();
    
    if (elbowAngle == null) {
      _emitState(feedback: 'Локти не видны камере');
      return;
    }

    String? feedback;
    bool isValidForm = true;

    // Check if in down position (elbow bent)
    if (elbowAngle <= AppConstants.pushUpDownAngle) {
      if (_phase != ExercisePhase.down) {
        _phase = ExercisePhase.down;
        _hasReachedDown = true;
      }
      feedback = 'Хорошо! Теперь поднимитесь';
    }
    // Check if in up position (arms extended)
    else if (elbowAngle >= AppConstants.pushUpUpAngle) {
      if (_phase == ExercisePhase.down && _hasReachedDown) {
        // Complete rep - anti-cheat: must have gone down first
        _repCount++;
        _hasReachedDown = false;
        _phase = ExercisePhase.up;
        feedback = 'Отлично! +1 отжимание';
      } else if (_phase != ExercisePhase.up) {
        _phase = ExercisePhase.up;
        feedback = 'Опуститесь до угла 90° в локтях';
      }
    }
    // In between positions
    else {
      if (_hasReachedDown) {
        feedback = 'Продолжайте подниматься';
      } else {
        feedback = 'Опуститесь ниже';
        isValidForm = false;
      }
    }

    _emitState(
      angle: elbowAngle,
      isValid: isValidForm,
      feedback: feedback,
    );
  }

  /// Process squat detection
  void _processSquat(PoseDetectionResult pose) {
    final kneeAngle = pose.getAverageKneeAngle();
    
    if (kneeAngle == null) {
      _emitState(feedback: 'Колени не видны камере');
      return;
    }

    String? feedback;
    bool isValidForm = true;

    // Check if in down position (squat)
    if (kneeAngle <= AppConstants.squatDownAngle) {
      if (_phase != ExercisePhase.down) {
        _phase = ExercisePhase.down;
        _hasReachedDown = true;
      }
      feedback = 'Отлично! Теперь встаньте';
    }
    // Check if in up position (standing)
    else if (kneeAngle >= AppConstants.squatUpAngle) {
      if (_phase == ExercisePhase.down && _hasReachedDown) {
        // Complete rep
        _repCount++;
        _hasReachedDown = false;
        _phase = ExercisePhase.up;
        feedback = 'Отлично! +1 приседание';
      } else if (_phase != ExercisePhase.up) {
        _phase = ExercisePhase.up;
        feedback = 'Присядьте до угла 90° в коленях';
      }
    }
    // In between positions
    else {
      if (_hasReachedDown) {
        feedback = 'Продолжайте вставать';
      } else {
        feedback = 'Присядьте глубже';
        isValidForm = false;
      }
    }

    _emitState(
      angle: kneeAngle,
      isValid: isValidForm,
      feedback: feedback,
    );
  }

  /// Process plank detection
  void _processPlank(PoseDetectionResult pose) {
    final hipY = pose.getHipYPosition();
    final isHorizontal = pose.isBodyHorizontal();
    
    if (hipY == null) {
      _stopPlankTimer();
      _emitState(feedback: 'Таз не виден камере');
      return;
    }

    String? feedback;
    bool isValidForm = false;

    if (isHorizontal) {
      // Check stability
      if (_lastHipY != null) {
        final movement = (hipY - _lastHipY!).abs();
        
        if (movement < AppConstants.plankStabilityThreshold) {
          isValidForm = true;
          
          if (_phase != ExercisePhase.holding) {
            _phase = ExercisePhase.holding;
            _startPlankTimer();
          }
          
          feedback = 'Держите! $_plankHoldSeconds сек';
        } else {
          _stopPlankTimer();
          feedback = 'Держите корпус неподвижно';
        }
      } else {
        feedback = 'Примите позицию планки';
      }
    } else {
      _stopPlankTimer();
      feedback = 'Выровняйте тело горизонтально';
    }

    _lastHipY = hipY;

    _emitState(
      isValid: isValidForm,
      feedback: feedback,
    );
  }

  /// Process jumping jack detection - arms and legs spread
  void _processJumpingJack(PoseDetectionResult pose) {
    final leftWrist = pose.getLandmark(LandmarkType.leftWrist);
    final rightWrist = pose.getLandmark(LandmarkType.rightWrist);
    final leftShoulder = pose.getLandmark(LandmarkType.leftShoulder);
    final rightShoulder = pose.getLandmark(LandmarkType.rightShoulder);
    
    if (leftWrist == null || rightWrist == null || leftShoulder == null || rightShoulder == null) {
      _emitState(feedback: 'Встаньте так, чтобы камера видела руки');
      return;
    }

    String? feedback;
    bool isValidForm = true;

    // Check if arms are up (wrists above shoulders)
    final armsUp = leftWrist.y < leftShoulder.y && rightWrist.y < rightShoulder.y;
    // Check if arms are down (wrists below shoulders)
    final armsDown = leftWrist.y > leftShoulder.y + 0.1 && rightWrist.y > rightShoulder.y + 0.1;

    if (armsUp) {
      if (_phase != ExercisePhase.up) {
        _phase = ExercisePhase.up;
        _hasReachedUp = true;
      }
      feedback = 'Руки вверху! Опустите';
    } else if (armsDown) {
      if (_phase == ExercisePhase.up && _hasReachedUp) {
        _repCount++;
        _hasReachedUp = false;
        _phase = ExercisePhase.down;
        feedback = '+1 джампинг!';
      } else if (_phase != ExercisePhase.down) {
        _phase = ExercisePhase.down;
        feedback = 'Поднимите руки вверх';
      }
    } else {
      feedback = _hasReachedUp ? 'Опустите руки' : 'Поднимите руки выше';
    }

    _emitState(
      isValid: isValidForm,
      feedback: feedback,
    );
  }

  /// Process high knees detection - alternating knee raises
  void _processHighKnees(PoseDetectionResult pose) {
    final leftKnee = pose.getLandmark(LandmarkType.leftKnee);
    final rightKnee = pose.getLandmark(LandmarkType.rightKnee);
    final leftHip = pose.getLandmark(LandmarkType.leftHip);
    final rightHip = pose.getLandmark(LandmarkType.rightHip);
    
    if (leftKnee == null || rightKnee == null || leftHip == null || rightHip == null) {
      _emitState(feedback: 'Встаньте так, чтобы камера видела ноги');
      return;
    }

    String? feedback;
    bool isValidForm = true;

    // Check if either knee is raised high (knee Y above hip Y means knee is up)
    final leftKneeHigh = leftKnee.y < leftHip.y + 0.05;
    final rightKneeHigh = rightKnee.y < rightHip.y + 0.05;
    final anyKneeHigh = leftKneeHigh || rightKneeHigh;

    if (anyKneeHigh) {
      if (_phase != ExercisePhase.up) {
        _phase = ExercisePhase.up;
        _hasReachedUp = true;
      }
      feedback = 'Отлично! Опустите';
    } else {
      if (_phase == ExercisePhase.up && _hasReachedUp) {
        _repCount++;
        _hasReachedUp = false;
        _phase = ExercisePhase.down;
        feedback = '+1 подъём!';
      } else if (_phase != ExercisePhase.down) {
        _phase = ExercisePhase.down;
        feedback = 'Поднимите колено выше';
      }
    }

    _emitState(
      isValid: isValidForm,
      feedback: feedback,
    );
  }

  // For free activity movement tracking
  double? _lastWristY;
  double? _lastAnkleY;
  int _activitySeconds = 0;
  DateTime? _activityStartTime;
  Timer? _activityTimer;
  int _movementCount = 0;
  DateTime? _lastMovementTime;

  /// Process free activity - detect any active movement
  void _processFreeActivity(PoseDetectionResult pose) {
    final hipY = pose.getHipYPosition();
    final leftWrist = pose.getLandmark(LandmarkType.leftWrist);
    final rightWrist = pose.getLandmark(LandmarkType.rightWrist);
    final leftAnkle = pose.getLandmark(LandmarkType.leftAnkle);
    final rightAnkle = pose.getLandmark(LandmarkType.rightAnkle);
    
    if (hipY == null) {
      _emitState(feedback: 'Встаньте так, чтобы камера видела тело');
      return;
    }

    // Get average positions
    final wristY = (leftWrist != null && rightWrist != null) 
        ? (leftWrist.y + rightWrist.y) / 2 
        : leftWrist?.y ?? rightWrist?.y;
    final ankleY = (leftAnkle != null && rightAnkle != null)
        ? (leftAnkle.y + rightAnkle.y) / 2
        : leftAnkle?.y ?? rightAnkle?.y;

    bool isMoving = false;
    int movingParts = 0;
    
    // Detect movement from any body part - moderate thresholds
    if (_lastHipY != null) {
      final hipMovement = (hipY - _lastHipY!).abs();
      if (hipMovement > 0.025) movingParts++;
    }
    if (_lastWristY != null && wristY != null) {
      final wristMovement = (wristY - _lastWristY!).abs();
      if (wristMovement > 0.03) movingParts++;
    }
    if (_lastAnkleY != null && ankleY != null) {
      final ankleMovement = (ankleY - _lastAnkleY!).abs();
      if (ankleMovement > 0.025) movingParts++;
    }
    
    // Require at least 1 body part moving to count as activity
    isMoving = movingParts >= 1;

    _lastHipY = hipY;
    _lastWristY = wristY;
    _lastAnkleY = ankleY;

    String? feedback;
    bool isValidForm = false;

    if (isMoving) {
      _movementCount++;
      _lastMovementTime = DateTime.now();
      
      if (_phase != ExercisePhase.holding) {
        _phase = ExercisePhase.holding;
        _startActivityTimer();
      }
      isValidForm = true;
      feedback = 'Отлично! Продолжайте двигаться! $_activitySeconds сек';
    } else {
      // Check if movement stopped for more than 0.5 seconds - immediate stop
      if (_lastMovementTime != null && 
          DateTime.now().difference(_lastMovementTime!).inMilliseconds > 500) {
        _stopActivityTimer();
        feedback = 'Двигайтесь активнее!';
      } else if (_activityStartTime != null) {
        isValidForm = true;
        feedback = 'Продолжайте движение! $_activitySeconds сек';
      } else {
        feedback = 'Начните активно двигаться';
      }
    }

    _emitState(
      isValid: isValidForm,
      feedback: feedback,
    );
  }

  void _startActivityTimer() {
    _activityStartTime ??= DateTime.now();
    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activityStartTime != null && _lastMovementTime != null) {
        // Only count if actively moving in the last 0.5 seconds
        if (DateTime.now().difference(_lastMovementTime!).inMilliseconds <= 500) {
          _activitySeconds++;
          _emitState(feedback: 'Активность: $_activitySeconds сек');
        }
      }
    });
  }

  void _stopActivityTimer() {
    _activityTimer?.cancel();
    _activityTimer = null;
    if (_phase == ExercisePhase.holding) {
      _phase = ExercisePhase.idle;
    }
  }

  void _startPlankTimer() {
    _plankStartTime = DateTime.now();
    _plankTimer?.cancel();
    _plankTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_plankStartTime != null) {
        _plankHoldSeconds = DateTime.now().difference(_plankStartTime!).inSeconds;
        _emitState(feedback: 'Держите! $_plankHoldSeconds сек');
      }
    });
  }

  void _stopPlankTimer() {
    _plankTimer?.cancel();
    _plankTimer = null;
    if (_phase == ExercisePhase.holding) {
      _phase = ExercisePhase.idle;
    }
  }

  void _emitState({
    double? angle,
    bool isValid = false,
    String? feedback,
  }) {
    int count;
    if (_currentExercise == ExerciseType.plank) {
      count = _plankHoldSeconds;
    } else if (_currentExercise == ExerciseType.freeActivity) {
      count = _activitySeconds;
    } else {
      count = _repCount;
    }
    
    final state = ExerciseTrackingState(
      exerciseType: _currentExercise,
      phase: _phase,
      currentCount: count,
      currentHoldSeconds: _currentExercise == ExerciseType.freeActivity ? _activitySeconds : _plankHoldSeconds,
      currentAngle: angle ?? 0.0,
      isValidForm: isValid,
      formFeedback: feedback,
    );
    
    onStateChanged?.call(state);
  }

  void dispose() {
    _plankTimer?.cancel();
    _activityTimer?.cancel();
  }
}
