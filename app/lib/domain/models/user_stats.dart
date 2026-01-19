import 'package:hive/hive.dart';
import 'package:fitness_coach/core/constants/app_constants.dart';

part 'user_stats.g.dart';

/// User statistics and progress
@HiveType(typeId: 3)
class UserStats extends HiveObject {
  @HiveField(0)
  int availableMinutes; // Current balance of earned screen time

  @HiveField(1)
  int totalEarnedMinutes; // All time earned minutes

  @HiveField(2)
  int totalSpentMinutes; // All time spent minutes

  @HiveField(3)
  int currentStreak; // Current consecutive days

  @HiveField(4)
  int longestStreak; // Best streak ever

  @HiveField(5)
  DateTime? lastWorkoutDate; // Last workout date for streak calculation

  @HiveField(6)
  int totalPushUps;

  @HiveField(7)
  int totalSquats;

  @HiveField(8)
  int totalPlankSeconds;

  @HiveField(9)
  int totalWorkouts;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  int totalLunges;

  @HiveField(12)
  int totalJumpingJacks;

  @HiveField(13)
  int totalHighKnees;

  @HiveField(14)
  int totalFreeActivitySeconds;

  UserStats({
    this.availableMinutes = 0,
    this.totalEarnedMinutes = 0,
    this.totalSpentMinutes = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastWorkoutDate,
    this.totalPushUps = 0,
    this.totalSquats = 0,
    this.totalPlankSeconds = 0,
    this.totalWorkouts = 0,
    this.totalLunges = 0,
    this.totalJumpingJacks = 0,
    this.totalHighKnees = 0,
    this.totalFreeActivitySeconds = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate streak multiplier based on current streak
  double get streakMultiplier {
    if (currentStreak >= 30) return AppConstants.streakMultiplier30Days;
    if (currentStreak >= 14) return AppConstants.streakMultiplier14Days;
    if (currentStreak >= 7) return AppConstants.streakMultiplier7Days;
    if (currentStreak >= 3) return AppConstants.streakMultiplier3Days;
    return 1.0;
  }

  /// Format available time as string
  String get availableTimeFormatted {
    final hours = availableMinutes ~/ 60;
    final mins = availableMinutes % 60;
    if (hours > 0) {
      return '${hours}ч ${mins}м';
    }
    return '${mins}м';
  }

  /// Check if user worked out today
  bool get hasWorkedOutToday {
    if (lastWorkoutDate == null) return false;
    final now = DateTime.now();
    return lastWorkoutDate!.year == now.year &&
        lastWorkoutDate!.month == now.month &&
        lastWorkoutDate!.day == now.day;
  }

  /// Update streak based on workout
  void updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastWorkoutDate == null) {
      currentStreak = 1;
    } else {
      final lastDate = DateTime(
        lastWorkoutDate!.year,
        lastWorkoutDate!.month,
        lastWorkoutDate!.day,
      );
      final difference = today.difference(lastDate).inDays;

      if (difference == 0) {
        // Already worked out today, no change
      } else if (difference == 1) {
        // Consecutive day
        currentStreak++;
      } else {
        // Streak broken
        currentStreak = 1;
      }
    }

    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    lastWorkoutDate = now;
  }

  UserStats copyWith({
    int? availableMinutes,
    int? totalEarnedMinutes,
    int? totalSpentMinutes,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastWorkoutDate,
    int? totalPushUps,
    int? totalSquats,
    int? totalPlankSeconds,
    int? totalWorkouts,
    int? totalLunges,
    int? totalJumpingJacks,
    int? totalHighKnees,
    int? totalFreeActivitySeconds,
    DateTime? createdAt,
  }) {
    return UserStats(
      availableMinutes: availableMinutes ?? this.availableMinutes,
      totalEarnedMinutes: totalEarnedMinutes ?? this.totalEarnedMinutes,
      totalSpentMinutes: totalSpentMinutes ?? this.totalSpentMinutes,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
      totalPushUps: totalPushUps ?? this.totalPushUps,
      totalSquats: totalSquats ?? this.totalSquats,
      totalPlankSeconds: totalPlankSeconds ?? this.totalPlankSeconds,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalLunges: totalLunges ?? this.totalLunges,
      totalJumpingJacks: totalJumpingJacks ?? this.totalJumpingJacks,
      totalHighKnees: totalHighKnees ?? this.totalHighKnees,
      totalFreeActivitySeconds: totalFreeActivitySeconds ?? this.totalFreeActivitySeconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Daily statistics record
@HiveType(typeId: 4)
class DailyStats extends HiveObject {
  @HiveField(0)
  final String dateKey; // Format: yyyy-MM-dd

  @HiveField(1)
  int pushUps;

  @HiveField(2)
  int squats;

  @HiveField(3)
  int plankSeconds;

  @HiveField(4)
  int earnedMinutes;

  @HiveField(5)
  int spentMinutes;

  @HiveField(6)
  int workoutCount;

  @HiveField(7)
  int freeActivitySeconds;

  DailyStats({
    required this.dateKey,
    this.pushUps = 0,
    this.squats = 0,
    this.plankSeconds = 0,
    this.earnedMinutes = 0,
    this.spentMinutes = 0,
    this.workoutCount = 0,
    this.freeActivitySeconds = 0,
  });

  DateTime get date => DateTime.parse(dateKey);

  static String dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
