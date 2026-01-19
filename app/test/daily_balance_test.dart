import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_coach/domain/models/daily_balance.dart';

void main() {
  group('DailyBalance Tests', () {
    late DailyBalance balance;

    setUp(() {
      balance = DailyBalance(
        lastResetDate: '2025-01-18',
        freeBalance: 30,
        earnedBalance: 0,
      );
    });

    group('Basic Balance Operations', () {
      test('Initial balance values', () {
        expect(balance.freeBalance, 30);
        expect(balance.earnedBalance, 0);
        expect(balance.usableMinutes, 30);
        expect(balance.canUseTime, true);
      });

      test('Consume time from free balance', () {
        final consumed = balance.consumeTime(20);
        expect(consumed, 20);
        expect(balance.freeBalance, 10);
        expect(balance.usableMinutes, 10);
      });

      test('Consume time uses free balance first, then earned', () {
        balance.addEarnedMinutes(20);
        expect(balance.usableMinutes, 50); // 30 free + 20 earned
        
        final consumed = balance.consumeTime(40);
        expect(consumed, 40);
        expect(balance.freeBalance, 0);
        expect(balance.earnedBalance, 10); // 20 - 10 = 10
      });

      test('Cannot consume more than available', () {
        final consumed = balance.consumeTime(50);
        expect(consumed, 30); // Only 30 available
        expect(balance.freeBalance, 0);
        expect(balance.usableMinutes, 0);
      });

      test('Zero or negative consume returns 0', () {
        expect(balance.consumeTime(0), 0);
        expect(balance.consumeTime(-10), 0);
      });
    });

    group('Earned Minutes', () {
      test('Add earned minutes', () {
        balance.addEarnedMinutes(20);
        expect(balance.earnedBalance, 20);
        expect(balance.usableMinutes, 50); // 30 + 20
      });

      test('Add zero or negative earned minutes does nothing', () {
        balance.addEarnedMinutes(0);
        expect(balance.earnedBalance, 0);
        
        balance.addEarnedMinutes(-10);
        expect(balance.earnedBalance, 0);
      });
    });

    group('Daily Reset', () {
      test('Needs daily reset on new day', () {
        balance = DailyBalance(lastResetDate: '2025-01-17');
        expect(balance.needsDailyReset(), true);
      });

      test('Does not need reset on same day', () {
        final today = DateTime.now();
        final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        balance = DailyBalance(lastResetDate: dateKey);
        expect(balance.needsDailyReset(), false);
      });

      test('Perform daily reset restores free balance', () {
        balance.consumeTime(30); // Use all free balance
        balance.addEarnedMinutes(10);
        
        expect(balance.freeBalance, 0);
        expect(balance.earnedBalance, 10);
        
        balance.performDailyReset(60);
        
        expect(balance.freeBalance, 60);
        expect(balance.earnedBalance, 0);
      });
    });

    group('Usable Minutes Calculation', () {
      test('Usable minutes = free + earned', () {
        balance = DailyBalance(freeBalance: 30, earnedBalance: 20);
        expect(balance.usableMinutes, 50);
        expect(balance.balanceMinutes, 50);
      });

      test('Can use time when balance > 0', () {
        expect(balance.canUseTime, true);
        
        balance.consumeTime(30);
        expect(balance.canUseTime, false);
      });
    });

    group('Balance Formatting', () {
      test('Format balance with minutes only', () {
        balance = DailyBalance(freeBalance: 45);
        expect(balance.balanceFormatted, '45м');
      });

      test('Format balance with hours and minutes', () {
        balance = DailyBalance(freeBalance: 90);
        expect(balance.balanceFormatted, '1ч 30м');
      });
    });

    group('Copy With', () {
      test('Copy with new values', () {
        final copy = balance.copyWith(freeBalance: 60, earnedBalance: 30);
        expect(copy.freeBalance, 60);
        expect(copy.earnedBalance, 30);
        expect(copy.lastResetDate, balance.lastResetDate);
      });
    });
  });
}
