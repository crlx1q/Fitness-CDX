import 'package:hive_flutter/hive_flutter.dart';
import 'package:fitness_coach/core/constants/app_constants.dart';
import 'package:fitness_coach/domain/models/exercise.dart';
import 'package:fitness_coach/domain/models/blocked_app.dart';
import 'package:fitness_coach/domain/models/user_stats.dart';
import 'package:fitness_coach/domain/models/app_settings.dart';
import 'package:fitness_coach/domain/models/daily_balance.dart';

/// Repository for all local storage operations using Hive
class StorageRepository {
  static StorageRepository? _instance;
  
  late Box<ExerciseSession> _exerciseBox;
  late Box<BlockedApp> _blockedAppsBox;
  late Box<UserStats> _userStatsBox;
  late Box<DailyStats> _dailyStatsBox;
  late Box<AppSettings> _settingsBox;
  late Box<DailyBalance> _dailyBalanceBox;

  StorageRepository._();

  static StorageRepository get instance {
    _instance ??= StorageRepository._();
    return _instance!;
  }

  /// Initialize Hive and register adapters
  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(ExerciseTypeAdapter());
    Hive.registerAdapter(ExerciseSessionAdapter());
    Hive.registerAdapter(BlockedAppAdapter());
    Hive.registerAdapter(UserStatsAdapter());
    Hive.registerAdapter(DailyStatsAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    Hive.registerAdapter(DailyBalanceAdapter());

    // Open boxes
    _exerciseBox = await Hive.openBox<ExerciseSession>(AppConstants.exerciseHistoryBox);
    _blockedAppsBox = await Hive.openBox<BlockedApp>(AppConstants.blockedAppsBox);
    _userStatsBox = await Hive.openBox<UserStats>(AppConstants.userStatsBox);
    _dailyStatsBox = await Hive.openBox<DailyStats>(AppConstants.dailyStatsBox);
    _settingsBox = await Hive.openBox<AppSettings>(AppConstants.settingsBox);
    _dailyBalanceBox = await Hive.openBox<DailyBalance>(AppConstants.dailyBalanceBox);

    // Initialize default data if needed
    await _initializeDefaults();
  }

  Future<void> _initializeDefaults() async {
    // Initialize user stats if not exists
    if (_userStatsBox.isEmpty) {
      await _userStatsBox.put('main', UserStats());
    }

    // Initialize settings if not exists
    if (_settingsBox.isEmpty) {
      await _settingsBox.put('main', AppSettings());
    }

    // Initialize daily balance if not exists
    if (_dailyBalanceBox.isEmpty) {
      final settings = getSettings();
      final freeAllowance = settings.difficulty.freeAllowanceMinutes;
      await _dailyBalanceBox.put('main', DailyBalance(freeBalance: freeAllowance));
    }
  }

  // ============ User Stats ============

  UserStats getUserStats() {
    return _userStatsBox.get('main') ?? UserStats();
  }

  Future<void> saveUserStats(UserStats stats) async {
    await _userStatsBox.put('main', stats);
  }

  Future<void> addEarnedMinutes(int minutes) async {
    final stats = getUserStats();
    stats.availableMinutes += minutes;
    stats.totalEarnedMinutes += minutes;
    await saveUserStats(stats);
  }

  Future<void> spendMinutes(int minutes) async {
    final stats = getUserStats();
    stats.availableMinutes = (stats.availableMinutes - minutes).clamp(0, double.maxFinite.toInt());
    stats.totalSpentMinutes += minutes;
    await saveUserStats(stats);
  }

  // ============ App Settings ============

  AppSettings getSettings() {
    return _settingsBox.get('main') ?? AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put('main', settings);
  }

  // ============ Exercise Progress (Unsaved) ============
  
  /// Get saved progress for a specific exercise type
  int getExerciseProgress(ExerciseType type) {
    final key = 'progress_${type.name}';
    return _settingsBox.get(key)?.difficultyIndex ?? 0;
  }
  
  /// Save progress for a specific exercise type (for continuing later)
  Future<void> saveExerciseProgress(ExerciseType type, int count) async {
    // Store in a simple box using a workaround with settings
    final prefs = await Hive.openBox('exercise_progress');
    await prefs.put(type.name, count);
  }
  
  /// Get saved exercise progress
  Future<int> getSavedExerciseProgress(ExerciseType type) async {
    final prefs = await Hive.openBox('exercise_progress');
    return prefs.get(type.name, defaultValue: 0) as int;
  }
  
  /// Clear saved progress for a specific exercise type
  Future<void> clearExerciseProgress(ExerciseType type) async {
    final prefs = await Hive.openBox('exercise_progress');
    await prefs.delete(type.name);
  }

  // ============ Exercise History ============

  List<ExerciseSession> getAllExercises() {
    return _exerciseBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<ExerciseSession> getExercisesByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _exerciseBox.values
        .where((e) => e.timestamp.isAfter(startOfDay) && e.timestamp.isBefore(endOfDay))
        .toList();
  }

  List<ExerciseSession> getExercisesByDateRange(DateTime start, DateTime end) {
    return _exerciseBox.values
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end))
        .toList();
  }

  Future<void> saveExerciseSession(ExerciseSession session) async {
    await _exerciseBox.put(session.id, session);
    
    // Update daily stats
    await _updateDailyStats(session);
    
    // Update user stats
    final stats = getUserStats();
    stats.totalWorkouts++;
    
    switch (session.type) {
      case ExerciseType.pushUp:
        stats.totalPushUps += session.count;
        break;
      case ExerciseType.squat:
      case ExerciseType.lunge:
        stats.totalSquats += session.count;
        break;
      case ExerciseType.plank:
        stats.totalPlankSeconds += session.count;
        break;
      case ExerciseType.jumpingJack:
      case ExerciseType.highKnees:
        stats.totalPushUps += session.count; // Count as cardio reps
        break;
      case ExerciseType.freeActivity:
        stats.totalFreeActivitySeconds += session.count;
        break;
    }
    
    stats.updateStreak();
    await saveUserStats(stats);
  }

  // ============ Daily Stats ============

  Future<void> _updateDailyStats(ExerciseSession session) async {
    final dateKey = DailyStats.dateToKey(session.timestamp);
    var dailyStats = _dailyStatsBox.get(dateKey);

    if (dailyStats == null) {
      dailyStats = DailyStats(dateKey: dateKey);
    }

    switch (session.type) {
      case ExerciseType.pushUp:
      case ExerciseType.jumpingJack:
      case ExerciseType.highKnees:
        dailyStats.pushUps += session.count;
        break;
      case ExerciseType.squat:
      case ExerciseType.lunge:
        dailyStats.squats += session.count;
        break;
      case ExerciseType.plank:
        dailyStats.plankSeconds += session.count;
        break;
      case ExerciseType.freeActivity:
        dailyStats.freeActivitySeconds += session.count;
        break;
    }

    dailyStats.earnedMinutes += session.earnedMinutes;
    dailyStats.workoutCount++;

    await _dailyStatsBox.put(dateKey, dailyStats);
  }

  DailyStats? getDailyStats(DateTime date) {
    final dateKey = DailyStats.dateToKey(date);
    return _dailyStatsBox.get(dateKey);
  }

  /// Add spent minutes to today's daily stats
  Future<void> addSpentMinutesToDaily(int minutes) async {
    final dateKey = DailyStats.dateToKey(DateTime.now());
    var dailyStats = _dailyStatsBox.get(dateKey);

    if (dailyStats == null) {
      dailyStats = DailyStats(dateKey: dateKey);
    }

    dailyStats.spentMinutes += minutes;
    await _dailyStatsBox.put(dateKey, dailyStats);
  }

  List<DailyStats> getDailyStatsRange(DateTime start, DateTime end) {
    final stats = <DailyStats>[];
    var current = start;

    while (current.isBefore(end)) {
      final dailyStats = getDailyStats(current);
      if (dailyStats != null) {
        stats.add(dailyStats);
      }
      current = current.add(const Duration(days: 1));
    }

    return stats;
  }

  // ============ Blocked Apps ============

  List<BlockedApp> getBlockedApps() {
    return _blockedAppsBox.values.where((app) => app.isBlocked).toList();
  }

  List<BlockedApp> getAllTrackedApps() {
    return _blockedAppsBox.values.toList();
  }

  Future<void> addBlockedApp(BlockedApp app) async {
    await _blockedAppsBox.put(app.packageName, app);
  }

  Future<void> removeBlockedApp(String packageName) async {
    await _blockedAppsBox.delete(packageName);
  }

  Future<void> toggleAppBlocked(String packageName, bool isBlocked) async {
    final app = _blockedAppsBox.get(packageName);
    if (app != null) {
      await _blockedAppsBox.put(
        packageName,
        app.copyWith(isBlocked: isBlocked),
      );
    }
  }

  Future<void> updateAppUsage(String packageName, int minutesUsed) async {
    final app = _blockedAppsBox.get(packageName);
    if (app != null) {
      await _blockedAppsBox.put(
        packageName,
        app.copyWith(totalUsedMinutes: app.totalUsedMinutes + minutesUsed),
      );
    }
  }

  // ============ Daily Balance ============

  DailyBalance getDailyBalance() {
    return _dailyBalanceBox.get('main') ?? DailyBalance();
  }

  Future<void> saveDailyBalance(DailyBalance balance) async {
    await _dailyBalanceBox.put('main', balance);
  }

  /// Check and perform daily reset if needed
  Future<DailyBalance> checkDailyReset(int freeAllowance) async {
    final balance = getDailyBalance();
    if (balance.needsDailyReset()) {
      balance.performDailyReset(freeAllowance);
      await saveDailyBalance(balance);
    }
    return balance;
  }

  /// Add earned minutes to balance
  Future<void> addEarnedMinutesToBalance(int minutes) async {
    final balance = getDailyBalance();
    balance.addEarnedMinutes(minutes);
    await saveDailyBalance(balance);
    
    // Also update user stats for historical tracking
    final stats = getUserStats();
    stats.totalEarnedMinutes += minutes;
    await saveUserStats(stats);
  }

  /// Consume time from balance (uses balance first, then debt if active)
  Future<void> consumeBalanceTime(int minutes) async {
    final balance = getDailyBalance();
    // Use the unified consumeTime method that handles balance→debt order
    balance.consumeTime(minutes);
    await saveDailyBalance(balance);
    
    // Also update user stats
    final stats = getUserStats();
    stats.totalSpentMinutes += minutes;
    await saveUserStats(stats);
  }

  // ============ Cleanup ============

  Future<void> clearAllData() async {
    await _exerciseBox.clear();
    await _blockedAppsBox.clear();
    await _dailyStatsBox.clear();
    await _userStatsBox.clear();
    await _settingsBox.clear();
    await _dailyBalanceBox.clear();
    await _initializeDefaults();
  }
}
