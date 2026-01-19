import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fitness_coach/core/constants/app_constants.dart';
import 'package:fitness_coach/data/repositories/storage_repository.dart';
import 'package:fitness_coach/domain/models/user_stats.dart';
import 'package:fitness_coach/domain/models/app_settings.dart';
import 'package:fitness_coach/domain/models/blocked_app.dart';
import 'package:fitness_coach/domain/models/exercise.dart';
import 'package:fitness_coach/domain/models/daily_balance.dart';
import 'package:fitness_coach/domain/services/notification_service.dart';
import 'package:fitness_coach/native_bridge/native_bridge.dart';

/// Main application state provider
class AppProvider extends ChangeNotifier {
  final StorageRepository _storage = StorageRepository.instance;
  final NativeBridge _native = NativeBridge.instance;
  final NotificationService _notifications = NotificationService.instance;
  Timer? _usageCheckTimer;
  Timer? _midnightResetTimer;
  Duration _usageCheckInterval = const Duration(seconds: 20);

  UserStats _userStats = UserStats();
  AppSettings _settings = AppSettings();
  DailyBalance _dailyBalance = DailyBalance();
  List<BlockedApp> _blockedApps = [];
  List<InstalledApp> _installedApps = [];
  bool _isLoading = true;
  bool _hasAccessibilityPermission = false;
  bool _hasUsageStatsPermission = false;
  int _lastNotifiedBalance = -1; // Track balance for low-balance notification

  // Getters
  UserStats get userStats => _userStats;
  AppSettings get settings => _settings;
  DailyBalance get dailyBalance => _dailyBalance;
  List<BlockedApp> get blockedApps => _blockedApps;
  List<InstalledApp> get installedApps => _installedApps;
  bool get isLoading => _isLoading;
  bool get hasAccessibilityPermission => _hasAccessibilityPermission;
  bool get hasUsageStatsPermission => _hasUsageStatsPermission;
  bool get hasAllPermissions => _hasAccessibilityPermission && _hasUsageStatsPermission;
  StorageRepository get storage => _storage;
  
  // Balance system getters
  int get usableMinutes => _dailyBalance.usableMinutes;
  bool get canUseTime => _dailyBalance.canUseTime;
  int get debtMinutes => _dailyBalance.debtMinutes;
  int get debtCreditRemaining => _dailyBalance.debtCreditRemaining;
  bool get canTakeDebt => _dailyBalance.canTakeDebt(DateTime.now());
  
  @override
  void dispose() {
    _usageCheckTimer?.cancel();
    _midnightResetTimer?.cancel();
    super.dispose();
  }

  /// Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Initialize storage only - notifications init lazily when needed
      await _storage.initialize();
      
      // Load data from storage (fast, synchronous reads)
      _userStats = _storage.getUserStats();
      _settings = _storage.getSettings();
      _blockedApps = _storage.getBlockedApps();
      
      // Check and perform daily reset if needed
      _dailyBalance = await _storage.checkDailyReset(
        _settings.difficulty.freeAllowanceMinutes,
      );
      
      // Quick permission check - don't block UI
      unawaited(refreshPermissions());
      
      // CRITICAL: Sync FROM native first to fix the sync bug
      // Native may have deducted time while Flutter app was closed
      await _syncFromNative();
      
      // Then sync blocked apps to native
      unawaited(_syncBlockedApps());
      
      // Listen for time changes from native
      _native.timeChangedStream.listen(_onNativeTimeChanged);
      
      // Start periodic usage check timer (adaptive interval)
      _startUsageCheckTimer();
      
      // Schedule midnight reset timer
      _scheduleMidnightReset();
      
      // Schedule morning notification
      _scheduleMorningNotification();
    } catch (e) {
      debugPrint('Error initializing app: $e');
    }

    _isLoading = false;
    notifyListeners();
    
    // Don't load installed apps on startup - defer to when AppsScreen is opened
    // This significantly improves startup time
  }
  
  /// Start timer to periodically check usage stats (fast interval for responsiveness)
  void _startUsageCheckTimer() {
    _usageCheckTimer?.cancel();
    _usageCheckTimer = Timer.periodic(_usageCheckInterval, (_) {
      checkAndDeductUsageTime();
    });
    // Delay first check by 5 seconds to not block startup
    Future.delayed(const Duration(seconds: 5), checkAndDeductUsageTime);
  }

  void setUsageCheckMode(UsageCheckMode mode) {
    final nextInterval = switch (mode) {
      UsageCheckMode.foreground => const Duration(seconds: 20),
      UsageCheckMode.background => const Duration(seconds: 45),
      UsageCheckMode.workout => const Duration(seconds: 60),
    };
    if (_usageCheckInterval == nextInterval) return;
    _usageCheckInterval = nextInterval;
    _startUsageCheckTimer();
  }
  
  /// Force immediate time sync (call when app comes to foreground)
  Future<void> forceTimeSync() async {
    await _syncFromNative();
    await checkAndDeductUsageTime();
  }
  
  /// Sync time FROM native SharedPreferences
  /// This fixes the bug where native deducted time while Flutter was closed
  Future<void> _syncFromNative() async {
    try {
      final nativeMinutes = await _native.getAvailableTime();
      
      // -1 means error, don't sync
      if (nativeMinutes < 0) return;
      
      final flutterMinutes = _dailyBalance.usableMinutes;
      
      // If native has less time than Flutter, native deducted while app was closed
      // We need to consume the difference in Flutter's Hive storage
      if (nativeMinutes < flutterMinutes) {
        final isFreshSession = nativeMinutes == 0 &&
            _userStats.totalSpentMinutes == 0 &&
            _dailyBalance.earnedBalance == 0 &&
            _dailyBalance.debtMinutes == 0 &&
            _dailyBalance.debtCreditRemaining == 0 &&
            _dailyBalance.freeBalance == _settings.difficulty.freeAllowanceMinutes;
        if (isFreshSession) {
          debugPrint('Syncing TO native: setting $flutterMinutes minutes (fresh start)');
          await _native.setAvailableTime(flutterMinutes);
        } else {
          final diff = flutterMinutes - nativeMinutes;
          debugPrint('Syncing FROM native: consuming $diff minutes (native=$nativeMinutes, flutter=$flutterMinutes)');
          final consumed = await _storage.consumeBalanceTime(diff);
          if (consumed > 0) {
            await _storage.addSpentMinutesToDaily(consumed);
          }
          _dailyBalance = _storage.getDailyBalance();
          _userStats = _storage.getUserStats();
          notifyListeners();
        }
      } else if (nativeMinutes > flutterMinutes) {
        // Flutter has less - sync TO native (Flutter is source of truth for earned time)
        debugPrint('Syncing TO native: setting $flutterMinutes minutes');
        await _native.setAvailableTime(flutterMinutes);
      }
      // If equal, no sync needed
    } catch (e) {
      debugPrint('Error syncing from native: $e');
    }
  }
  
  /// Schedule timer for midnight reset
  void _scheduleMidnightReset() {
    _midnightResetTimer?.cancel();
    
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 1); // 00:01
    final duration = tomorrow.difference(now);
    
    _midnightResetTimer = Timer(duration, () async {
      await _performDailyReset();
      // Reschedule for next day
      _scheduleMidnightReset();
    });
  }
  
  /// Perform daily reset at midnight
  Future<void> _performDailyReset() async {
    _dailyBalance = await _storage.checkDailyReset(
      _settings.difficulty.freeAllowanceMinutes,
    );
    
    // Sync with native
    await _native.setAvailableTime(_dailyBalance.usableMinutes);
    
    // Schedule morning notification
    _scheduleMorningNotification();
    
    notifyListeners();
  }
  
  /// Schedule morning notification
  void _scheduleMorningNotification() {
    if (!_settings.notificationsEnabled) return;
    
    _notifications.scheduleMorningNotification(
      availableMinutes: _dailyBalance.usableMinutes,
    );
  }
  
  /// Check usage stats and deduct time spent in blocked apps
  Future<void> checkAndDeductUsageTime() async {
    if (!_hasUsageStatsPermission || _blockedApps.isEmpty) return;
    if (!_dailyBalance.canUseTime) return; // Can't use time if debt needs paying
    
    // Get deducted time from native (based on UsageStats)
    final deducted = await _native.checkAndDeductTime();
    
    if (deducted > 0) {
      // Use the new balance system - consumes from freeBalance first, then earnedBalance
      final consumed = await _storage.consumeBalanceTime(deducted);
      _dailyBalance = _storage.getDailyBalance();
      _userStats = _storage.getUserStats();
      
      // Also update daily stats for proper tracking
      if (consumed > 0) {
        await _storage.addSpentMinutesToDaily(consumed);
      }
      
      // Sync updated balance with native
      await _native.setAvailableTime(_dailyBalance.usableMinutes);
      
      // Check for low balance notification
      _checkLowBalanceNotification();
      
      notifyListeners();
    }
    // Don't sync TO native if no deduction - _syncFromNative already handles sync
  }
  
  /// Check and show low balance notification
  void _checkLowBalanceNotification() {
    if (!_settings.notificationsEnabled) return;
    
    final balance = _dailyBalance.usableMinutes;
    if (balance <= AppConstants.lowBalanceThreshold && 
        balance > 0 && 
        _lastNotifiedBalance != balance) {
      _lastNotifiedBalance = balance;
      _notifications.showLowBalanceNotification(balance);
    }
  }
  
  /// Handle time changes from native side
  void _onNativeTimeChanged(int newMinutes) {
    // Sync with our balance system
    final currentUsable = _dailyBalance.usableMinutes;
    if (currentUsable != newMinutes && newMinutes < currentUsable) {
      final diff = currentUsable - newMinutes;
      _storage.consumeBalanceTime(diff).then((consumed) {
        if (consumed > 0) {
          _storage.addSpentMinutesToDaily(consumed);
        }
      });
      _dailyBalance = _storage.getDailyBalance();
      notifyListeners();
    }
  }

  /// Refresh permission status
  Future<void> refreshPermissions() async {
    _hasAccessibilityPermission = await _native.isAccessibilityServiceEnabled();
    _hasUsageStatsPermission = await _native.isUsageStatsPermissionGranted();
    notifyListeners();
  }

  /// Load installed apps in background isolate
  Future<void> _loadInstalledAppsInBackground() async {
    try {
      final rawApps = await _native.getInstalledApps();
      // Process filtering and sorting in isolate to avoid UI jank
      _installedApps = await compute(_processInstalledApps, rawApps);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading installed apps: $e');
    }
  }
  
  /// Process installed apps list (runs in isolate)
  static List<InstalledApp> _processInstalledApps(List<InstalledApp> apps) {
    // Filter out system apps for cleaner list
    final filtered = apps.where((app) => !app.isSystemApp).toList();
    // Sort alphabetically
    filtered.sort((a, b) => a.appName.compareTo(b.appName));
    return filtered;
  }

  /// Load installed apps from system (public API)
  Future<void> loadInstalledApps() async {
    await _loadInstalledAppsInBackground();
  }

  /// Open accessibility settings
  Future<void> openAccessibilitySettings() async {
    await _native.openAccessibilitySettings();
  }

  /// Open usage stats settings
  Future<void> openUsageStatsSettings() async {
    await _native.openUsageStatsSettings();
  }

  // ============ Settings ============

  /// Update difficulty preset
  Future<void> setDifficulty(DifficultyPreset preset) async {
    _settings.difficulty = preset;
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  /// Toggle strike mode
  Future<void> setStrikeModeEnabled(bool enabled) async {
    _settings.strikeModeEnabled = enabled;
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  /// Toggle sound feedback
  Future<void> setSoundEnabled(bool enabled) async {
    _settings.soundEnabled = enabled;
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  /// Toggle notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    _settings.notificationsEnabled = enabled;
    await _storage.saveSettings(_settings);
    
    if (enabled) {
      // Request notification permission and schedule notifications
      final granted = await _notifications.requestPermission();
      if (granted) {
        _scheduleMorningNotification();
      }
    } else {
      // Cancel all scheduled notifications
      await _notifications.cancelAllNotifications();
    }
    
    notifyListeners();
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    return await _notifications.requestPermission();
  }

  /// Check if notification permission is granted (system level)
  Future<bool> checkNotificationPermission() async {
    return await _notifications.checkPermissionStatus();
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding() async {
    _settings.hasCompletedOnboarding = true;
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  /// Mark permissions as granted
  Future<void> markPermissionsGranted() async {
    _settings.hasGrantedPermissions = true;
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  // ============ Blocked Apps ============

  /// Add app to blocked list
  Future<void> addBlockedApp(InstalledApp app) async {
    final blockedApp = BlockedApp(
      packageName: app.packageName,
      appName: app.appName,
      isBlocked: true,
      iconBase64: app.iconBase64,
    );
    
    await _storage.addBlockedApp(blockedApp);
    _blockedApps = _storage.getBlockedApps();
    await _syncBlockedApps();
    notifyListeners();
  }

  /// Add app to blocked list manually by package name
  Future<void> addBlockedAppManually(String packageName, String appName) async {
    // Check if already blocked
    if (_blockedApps.any((app) => app.packageName == packageName)) {
      return;
    }
    
    final blockedApp = BlockedApp(
      packageName: packageName,
      appName: appName,
      isBlocked: true,
    );
    
    await _storage.addBlockedApp(blockedApp);
    _blockedApps = _storage.getBlockedApps();
    await _syncBlockedApps();
    notifyListeners();
  }

  /// Remove app from blocked list
  Future<void> removeBlockedApp(String packageName) async {
    await _storage.removeBlockedApp(packageName);
    _blockedApps = _storage.getBlockedApps();
    await _syncBlockedApps();
    notifyListeners();
  }

  /// Toggle app block status
  Future<void> toggleAppBlocked(String packageName, bool isBlocked) async {
    await _storage.toggleAppBlocked(packageName, isBlocked);
    _blockedApps = _storage.getBlockedApps();
    await _syncBlockedApps();
    notifyListeners();
  }

  /// Sync blocked apps with native service
  Future<void> _syncBlockedApps() async {
    final packages = _blockedApps.map((app) => app.packageName).toList();
    await _native.setBlockedApps(packages);
  }

  /// Check if app is blocked
  bool isAppBlocked(String packageName) {
    return _blockedApps.any((app) => app.packageName == packageName);
  }

  // ============ Exercise & Rewards ============

  /// Record completed exercise and add earned time
  Future<void> recordExercise(ExerciseSession session) async {
    await _storage.saveExerciseSession(session);
    
    // Add earned minutes to balance
    await _storage.addEarnedMinutesToBalance(session.earnedMinutes);
    
    _dailyBalance = _storage.getDailyBalance();
    _userStats = _storage.getUserStats();
    
    // Sync new available time with native
    await _native.setAvailableTime(_dailyBalance.usableMinutes);
    
    notifyListeners();
  }

  Future<bool> takeDebtMinutes(int minutes) async {
    final result = await _storage.takeDebtMinutes(minutes);
    if (result) {
      _dailyBalance = _storage.getDailyBalance();
      await _native.setAvailableTime(_dailyBalance.usableMinutes);
      notifyListeners();
    }
    return result;
  }

  Future<void> resetAllData() async {
    await _storage.clearAllData();
    _userStats = _storage.getUserStats();
    _settings = _storage.getSettings();
    _blockedApps = _storage.getBlockedApps();
    _dailyBalance = _storage.getDailyBalance();
    await _native.setAvailableTime(_dailyBalance.usableMinutes);
    notifyListeners();
  }

  /// Calculate reward for exercise
  int calculateReward(ExerciseType type, int count) {
    final multiplier = _settings.strikeModeEnabled 
        ? _userStats.streakMultiplier 
        : 1.0;

    switch (type) {
      case ExerciseType.pushUp:
        return _settings.calculatePushUpReward(count, multiplier);
      case ExerciseType.squat:
        return _settings.calculateSquatReward(count, multiplier);
      case ExerciseType.plank:
        return _settings.calculatePlankReward(count, multiplier);
      case ExerciseType.lunge:
        // Lunges: same requirement as squats
        return _settings.calculateSquatReward(count, multiplier);
      case ExerciseType.jumpingJack:
        // Jumping jacks: 20 jacks = same reward as 10 pushups
        final jjSets = count ~/ (_settings.pushUpRequirement * 2);
        return (jjSets * _settings.pushUpRewardMinutes * multiplier).round();
      case ExerciseType.highKnees:
        // High knees: 40 knees = same reward as 10 pushups
        final hkSets = count ~/ (_settings.pushUpRequirement * 4);
        return (hkSets * _settings.pushUpRewardMinutes * multiplier).round();
      case ExerciseType.freeActivity:
        // Free activity: 60 seconds = 1 minute reward (1:1 ratio)
        final minutes = count ~/ 60;
        return (minutes * multiplier).round();
    }
  }
  
  /// Get requirement count for exercise type
  int getRequirementForExercise(ExerciseType type) {
    switch (type) {
      case ExerciseType.pushUp:
        return _settings.pushUpRequirement;
      case ExerciseType.squat:
        return _settings.squatRequirement;
      case ExerciseType.plank:
        return _settings.plankSecondRequirement;
      case ExerciseType.lunge:
        return _settings.squatRequirement;
      case ExerciseType.jumpingJack:
        return _settings.pushUpRequirement * 2; // 20 for default
      case ExerciseType.highKnees:
        return _settings.pushUpRequirement * 4; // 40 for default
      case ExerciseType.freeActivity:
        return 60; // 60 seconds = 1 minute reward
    }
  }
  
  /// Get reward minutes for exercise type (per set)
  int getRewardForExercise(ExerciseType type) {
    switch (type) {
      case ExerciseType.pushUp:
      case ExerciseType.jumpingJack:
      case ExerciseType.highKnees:
        return _settings.pushUpRewardMinutes;
      case ExerciseType.squat:
      case ExerciseType.lunge:
        return _settings.squatRewardMinutes;
      case ExerciseType.plank:
        return _settings.plankRewardMinutes;
      case ExerciseType.freeActivity:
        return 1; // 1 minute per 60 seconds of activity
    }
  }

  /// Spend screen time
  Future<void> spendMinutes(int minutes, String packageName) async {
    await _storage.spendMinutes(minutes);
    await _storage.updateAppUsage(packageName, minutes);
    
    _userStats = _storage.getUserStats();
    await _native.setAvailableTime(_userStats.availableMinutes);
    
    notifyListeners();
  }

  /// Get exercise history for date range
  List<ExerciseSession> getExerciseHistory({DateTime? start, DateTime? end}) {
    if (start != null && end != null) {
      return _storage.getExercisesByDateRange(start, end);
    }
    return _storage.getAllExercises();
  }

  /// Get daily stats for date range
  List<DailyStats> getDailyStats(DateTime start, DateTime end) {
    return _storage.getDailyStatsRange(start, end);
  }

  /// Get all recorded daily stats
  List<DailyStats> getAllDailyStats() {
    return _storage.getAllDailyStats();
  }

  // ============ Blocking Service ============

  /// Start the app blocking service
  Future<bool> startBlockingService() async {
    if (!hasAllPermissions) return false;
    return await _native.startBlockingService();
  }

  /// Stop the app blocking service
  Future<void> stopBlockingService() async {
    await _native.stopBlockingService();
  }
}

enum UsageCheckMode {
  foreground,
  background,
  workout,
}
