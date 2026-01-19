/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'FitLock';
  static const String appVersion = '1.0.0';

  // Time rewards (in minutes) - Default values
  static const int defaultPushUpReward = 30; // 10 push-ups = 30 min
  static const int defaultSquatReward = 30; // 20 squats = 30 min
  static const int defaultPlankReward = 15; // 1 min plank = 15 min

  // Exercise requirements for reward
  static const int pushUpsForReward = 10;
  static const int squatsForReward = 20;
  static const int plankSecondsForReward = 60;

  // Streak multipliers
  static const double streakMultiplier3Days = 1.2;
  static const double streakMultiplier7Days = 1.5;
  static const double streakMultiplier14Days = 1.75;
  static const double streakMultiplier30Days = 2.0;

  // Exercise detection thresholds
  static const double pushUpDownAngle = 90.0; // Elbow angle for "down" position
  static const double pushUpUpAngle = 160.0; // Elbow angle for "up" position
  static const double squatDownAngle = 90.0; // Knee angle for "down" position
  static const double squatUpAngle = 160.0; // Knee angle for "up" position
  static const double plankStabilityThreshold = 0.05; // Max movement allowed

  // Method Channel
  static const String methodChannelName = 'com.fitlock.app/native';
  
  // Hive Box Names
  static const String settingsBox = 'settings';
  static const String exerciseHistoryBox = 'exercise_history';
  static const String blockedAppsBox = 'blocked_apps';
  static const String userStatsBox = 'user_stats';
  static const String dailyStatsBox = 'daily_stats';
  static const String dailyBalanceBox = 'daily_balance';
  static const String monthlyStatsBox = 'monthly_stats';

  // Free daily allowance by difficulty (in minutes)
  static const int freeAllowanceEasy = 90;    // 1h 30min for easy
  static const int freeAllowanceNormal = 60;  // 1h for normal
  static const int freeAllowanceHard = 1;     // 1min for hard (TEMP FOR TESTING)

  // Notification IDs
  static const int morningNotificationId = 1001;
  static const int lowBalanceNotificationId = 1002;
  
  // Low balance warning threshold (minutes)
  static const int lowBalanceThreshold = 5;

  // Debt system
  static const int maxDailyDebtMinutes = 120;
  static const List<int> debtMinuteOptions = [15, 30, 60, 120];
  static const int dailyStatsRetentionDays = 30;
}

/// Difficulty presets
enum DifficultyPreset {
  easy,
  normal,
  hard,
}

extension DifficultyPresetExtension on DifficultyPreset {
  String get displayName {
    switch (this) {
      case DifficultyPreset.easy:
        return 'Лёгкий';
      case DifficultyPreset.normal:
        return 'Нормальный';
      case DifficultyPreset.hard:
        return 'Жёсткий';
    }
  }

  String get description {
    switch (this) {
      case DifficultyPreset.easy:
        return 'Больше времени за меньше упражнений';
      case DifficultyPreset.normal:
        return 'Сбалансированный режим';
      case DifficultyPreset.hard:
        return 'Максимальная дисциплина';
    }
  }

  // Multiplier for rewards (higher = more time per exercise)
  double get rewardMultiplier {
    switch (this) {
      case DifficultyPreset.easy:
        return 1.5;
      case DifficultyPreset.normal:
        return 1.0;
      case DifficultyPreset.hard:
        return 0.7;
    }
  }
  
  // Multiplier for requirements (lower = fewer reps needed)
  double get requirementMultiplier {
    switch (this) {
      case DifficultyPreset.easy:
        return 0.6;  // Easy: 6 pushups, 12 squats, 36s plank
      case DifficultyPreset.normal:
        return 1.0;  // Normal: 10 pushups, 20 squats, 60s plank
      case DifficultyPreset.hard:
        return 1.5;  // Hard: 15 pushups, 30 squats, 90s plank
    }
  }

  // Free daily allowance based on difficulty
  int get freeAllowanceMinutes {
    switch (this) {
      case DifficultyPreset.easy:
        return AppConstants.freeAllowanceEasy;
      case DifficultyPreset.normal:
        return AppConstants.freeAllowanceNormal;
      case DifficultyPreset.hard:
        return AppConstants.freeAllowanceHard;
    }
  }
}
