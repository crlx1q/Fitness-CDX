import 'package:hive/hive.dart';

part 'daily_balance.g.dart';

/// Daily balance tracking - simple free + earned system
@HiveType(typeId: 6)
class DailyBalance extends HiveObject {
  @HiveField(0)
  String lastResetDate; // Format: yyyy-MM-dd - last daily reset

  @HiveField(1)
  int freeBalance; // Free daily allowance remaining (minutes)

  @HiveField(4)
  int earnedBalance; // Extra balance earned through workouts

  DailyBalance({
    String? lastResetDate,
    this.freeBalance = 0,
    this.earnedBalance = 0,
  }) : lastResetDate = lastResetDate ?? _dateToKey(DateTime.now());

  /// Total available minutes from balance (free + earned)
  int get balanceMinutes => freeBalance + earnedBalance;

  /// Total usable minutes
  int get usableMinutes => freeBalance + earnedBalance;

  /// Check if user can use balance (has usable time)
  bool get canUseTime => usableMinutes > 0;

  /// Consume time - uses free balance first, then earned
  /// Returns actual minutes consumed (may be less if not enough available)
  int consumeTime(int minutes) {
    if (minutes <= 0) return 0;
    
    int remaining = minutes;
    int consumed = 0;
    
    // 1. First consume from free balance
    if (freeBalance > 0 && remaining > 0) {
      final fromFree = remaining.clamp(0, freeBalance);
      freeBalance -= fromFree;
      remaining -= fromFree;
      consumed += fromFree;
    }
    
    // 2. Then consume from earned balance
    if (earnedBalance > 0 && remaining > 0) {
      final fromEarned = remaining.clamp(0, earnedBalance);
      earnedBalance -= fromEarned;
      remaining -= fromEarned;
      consumed += fromEarned;
    }
    
    return consumed;
  }

  /// Add earned minutes to balance
  void addEarnedMinutes(int minutes) {
    if (minutes <= 0) return;
    earnedBalance += minutes;
  }

  /// Check if needs daily reset
  bool needsDailyReset() {
    final now = DateTime.now();
    final today = _dateToKey(now);
    return lastResetDate != today;
  }

  /// Perform daily reset - called at 00:01 or when app opens on new day
  void performDailyReset(int freeAllowance) {
    final now = DateTime.now();
    lastResetDate = _dateToKey(now);
    
    // Reset balances
    freeBalance = freeAllowance;
    earnedBalance = 0;
  }

  /// Format balance for display
  String get balanceFormatted {
    final mins = usableMinutes;
    final hours = mins ~/ 60;
    final minutes = mins % 60;
    if (hours > 0) {
      return '${hours}ч ${minutes}м';
    }
    return '${minutes}м';
  }

  static String _dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DailyBalance copyWith({
    String? lastResetDate,
    int? freeBalance,
    int? earnedBalance,
  }) {
    return DailyBalance(
      lastResetDate: lastResetDate ?? this.lastResetDate,
      freeBalance: freeBalance ?? this.freeBalance,
      earnedBalance: earnedBalance ?? this.earnedBalance,
    );
  }
}
