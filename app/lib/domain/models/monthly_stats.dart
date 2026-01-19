import 'package:hive/hive.dart';
import 'package:fitness_coach/domain/models/user_stats.dart';

part 'monthly_stats.g.dart';

/// Monthly statistics aggregation for long-term storage
@HiveType(typeId: 7)
class MonthlyStats extends HiveObject {
  @HiveField(0)
  final String monthKey; // Format: yyyy-MM

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

  MonthlyStats({
    required this.monthKey,
    this.pushUps = 0,
    this.squats = 0,
    this.plankSeconds = 0,
    this.earnedMinutes = 0,
    this.spentMinutes = 0,
    this.workoutCount = 0,
    this.freeActivitySeconds = 0,
  });

  static String monthToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  void addDaily(DailyStats daily) {
    pushUps += daily.pushUps;
    squats += daily.squats;
    plankSeconds += daily.plankSeconds;
    earnedMinutes += daily.earnedMinutes;
    spentMinutes += daily.spentMinutes;
    workoutCount += daily.workoutCount;
    freeActivitySeconds += daily.freeActivitySeconds;
  }
}
