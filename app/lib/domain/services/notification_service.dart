import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:fitness_coach/core/constants/app_constants.dart';

/// Service for managing local push notifications
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service (called lazily when needed)
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  /// Public initialize - now just calls _ensureInitialized (kept for compatibility)
  Future<void> initialize() async {
    // No-op on startup - will init lazily when actually needed
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - could navigate to specific screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    await _ensureInitialized();
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Alias for requestPermissions
  Future<bool> requestPermission() async {
    return await requestPermissions();
  }

  /// Check if notification permission is granted
  Future<bool> checkPermissionStatus() async {
    await _ensureInitialized();
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      return enabled ?? false;
    }
    return true;
  }

  /// Cancel all notifications (alias for cancelAll)
  Future<void> cancelAllNotifications() async {
    await cancelAll();
  }

  /// Schedule morning notification about available balance
  Future<void> scheduleMorningNotification({
    required int availableMinutes,
  }) async {
    await _ensureInitialized();
    await _notifications.cancel(AppConstants.morningNotificationId);

    const String title = '🌅 Доброе утро!';
    final String body = 'Сегодня у вас ${_formatMinutes(availableMinutes)} экранного времени';

    // Schedule for tomorrow 8:00 AM
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 8, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      AppConstants.morningNotificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Show low balance warning notification
  Future<void> showLowBalanceNotification(int remainingMinutes) async {
    await _ensureInitialized();
    await _notifications.show(
      AppConstants.lowBalanceNotificationId,
      '⏰ Время заканчивается!',
      'Осталось всего $remainingMinutes мин. Скоро приложения заблокируются.',
      _notificationDetails,
    );
  }

  /// Show notification when balance is refilled
  Future<void> showBalanceRefilledNotification(int minutes) async {
    await _ensureInitialized();
    await _notifications.show(
      1004,
      '✅ Баланс пополнен!',
      'Вы заработали ${_formatMinutes(minutes)} экранного времени.',
      _notificationDetails,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    if (!_isInitialized) return; // Don't init just to cancel
    await _notifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  NotificationDetails get _notificationDetails {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'fitlock_channel',
        'FitLock Notifications',
        channelDescription: 'Уведомления о балансе экранного времени',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '$hoursч $minsм';
    }
    return '$minsм';
  }
}
