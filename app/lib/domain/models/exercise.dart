import 'package:hive/hive.dart';

part 'exercise.g.dart';

/// Types of supported exercises
@HiveType(typeId: 0)
enum ExerciseType {
  @HiveField(0)
  pushUp,
  
  @HiveField(1)
  squat,
  
  @HiveField(2)
  plank,
  
  @HiveField(3)
  lunge,
  
  @HiveField(4)
  jumpingJack,
  
  @HiveField(5)
  highKnees,
  
  @HiveField(6)
  freeActivity, // Free movement activity - 1 minute = 1 minute reward
}

extension ExerciseTypeExtension on ExerciseType {
  String get displayName {
    switch (this) {
      case ExerciseType.pushUp:
        return 'Отжимания';
      case ExerciseType.squat:
        return 'Приседания';
      case ExerciseType.plank:
        return 'Планка';
      case ExerciseType.lunge:
        return 'Выпады';
      case ExerciseType.jumpingJack:
        return 'Джампинг Джек';
      case ExerciseType.highKnees:
        return 'Высокие колени';
      case ExerciseType.freeActivity:
        return 'Свободная активность';
    }
  }

  String get description {
    switch (this) {
      case ExerciseType.pushUp:
        return 'Полная амплитуда: опуститесь до угла 90° в локтях';
      case ExerciseType.squat:
        return 'Присядьте до угла 90° в коленях';
      case ExerciseType.plank:
        return 'Удерживайте позицию неподвижно';
      case ExerciseType.lunge:
        return 'Шаг вперед, колено до 90°';
      case ExerciseType.jumpingJack:
        return 'Прыжки с разведением рук и ног';
      case ExerciseType.highKnees:
        return 'Бег на месте с высоким подъемом колен';
      case ExerciseType.freeActivity:
        return 'Двигайтесь активно: руки, ноги, тело';
    }
  }

  String get icon {
    switch (this) {
      case ExerciseType.pushUp:
        return '💪';
      case ExerciseType.squat:
        return '🦵';
      case ExerciseType.plank:
        return '🧘';
      case ExerciseType.lunge:
        return '🏃';
      case ExerciseType.jumpingJack:
        return '⭐';
      case ExerciseType.highKnees:
        return '🦿';
      case ExerciseType.freeActivity:
        return '🔥';
    }
  }

  /// Whether this exercise is counted by reps or by time
  bool get isTimeBased {
    return this == ExerciseType.plank || this == ExerciseType.freeActivity;
  }
}

/// A single exercise session record
@HiveType(typeId: 1)
class ExerciseSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ExerciseType type;

  @HiveField(2)
  final int count; // reps for push-ups/squats, seconds for plank

  @HiveField(3)
  final int earnedMinutes;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final int durationSeconds; // Total session duration

  ExerciseSession({
    required this.id,
    required this.type,
    required this.count,
    required this.earnedMinutes,
    required this.timestamp,
    required this.durationSeconds,
  });

  ExerciseSession copyWith({
    String? id,
    ExerciseType? type,
    int? count,
    int? earnedMinutes,
    DateTime? timestamp,
    int? durationSeconds,
  }) {
    return ExerciseSession(
      id: id ?? this.id,
      type: type ?? this.type,
      count: count ?? this.count,
      earnedMinutes: earnedMinutes ?? this.earnedMinutes,
      timestamp: timestamp ?? this.timestamp,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}

/// Exercise detection state during workout
enum ExercisePhase {
  idle,      // Not in exercise position
  down,      // In down position (push-up/squat)
  up,        // In up position
  holding,   // For plank - currently holding
}

/// Real-time exercise tracking state
class ExerciseTrackingState {
  final ExerciseType exerciseType;
  final ExercisePhase phase;
  final int currentCount;
  final int currentHoldSeconds; // For plank
  final double currentAngle; // Current joint angle being tracked
  final bool isValidForm; // Whether current form is correct
  final String? formFeedback; // Feedback message for user

  const ExerciseTrackingState({
    required this.exerciseType,
    this.phase = ExercisePhase.idle,
    this.currentCount = 0,
    this.currentHoldSeconds = 0,
    this.currentAngle = 0.0,
    this.isValidForm = false,
    this.formFeedback,
  });

  ExerciseTrackingState copyWith({
    ExerciseType? exerciseType,
    ExercisePhase? phase,
    int? currentCount,
    int? currentHoldSeconds,
    double? currentAngle,
    bool? isValidForm,
    String? formFeedback,
  }) {
    return ExerciseTrackingState(
      exerciseType: exerciseType ?? this.exerciseType,
      phase: phase ?? this.phase,
      currentCount: currentCount ?? this.currentCount,
      currentHoldSeconds: currentHoldSeconds ?? this.currentHoldSeconds,
      currentAngle: currentAngle ?? this.currentAngle,
      isValidForm: isValidForm ?? this.isValidForm,
      formFeedback: formFeedback ?? this.formFeedback,
    );
  }
}
