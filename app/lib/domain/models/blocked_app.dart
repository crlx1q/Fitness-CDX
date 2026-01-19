import 'package:hive/hive.dart';

part 'blocked_app.g.dart';

/// Represents an app that can be blocked
@HiveType(typeId: 2)
class BlockedApp extends HiveObject {
  @HiveField(0)
  final String packageName;

  @HiveField(1)
  final String appName;

  @HiveField(2)
  final bool isBlocked;

  @HiveField(3)
  final int totalBlockedMinutes; // Total time this app was blocked

  @HiveField(4)
  final int totalUsedMinutes; // Total earned time used on this app

  @HiveField(5)
  final String? iconBase64; // Base64 encoded app icon

  BlockedApp({
    required this.packageName,
    required this.appName,
    this.isBlocked = true,
    this.totalBlockedMinutes = 0,
    this.totalUsedMinutes = 0,
    this.iconBase64,
  });

  BlockedApp copyWith({
    String? packageName,
    String? appName,
    bool? isBlocked,
    int? totalBlockedMinutes,
    int? totalUsedMinutes,
    String? iconBase64,
  }) {
    return BlockedApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isBlocked: isBlocked ?? this.isBlocked,
      totalBlockedMinutes: totalBlockedMinutes ?? this.totalBlockedMinutes,
      totalUsedMinutes: totalUsedMinutes ?? this.totalUsedMinutes,
      iconBase64: iconBase64 ?? this.iconBase64,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlockedApp && other.packageName == packageName;
  }

  @override
  int get hashCode => packageName.hashCode;
}

/// App info from the system
class InstalledApp {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  final int todayUsageMinutes;
  final String? iconBase64;

  const InstalledApp({
    required this.packageName,
    required this.appName,
    this.isSystemApp = false,
    this.todayUsageMinutes = 0,
    this.iconBase64,
  });
  
  /// Format usage time for display
  String get formattedUsage {
    if (todayUsageMinutes == 0) return 'Не использовалось';
    if (todayUsageMinutes < 60) return '$todayUsageMinutes мин сегодня';
    final hours = todayUsageMinutes ~/ 60;
    final mins = todayUsageMinutes % 60;
    if (mins == 0) return '$hours ч сегодня';
    return '$hours ч $mins мин сегодня';
  }

  /// Common apps that users might want to block
  static const List<String> commonBlockedPackages = [
    'com.zhiliaoapp.musically', // TikTok
    'com.ss.android.ugc.trill', // TikTok (alternate)
    'com.google.android.youtube',
    'com.instagram.android',
    'com.facebook.katana',
    'com.twitter.android',
    'com.snapchat.android',
    'com.reddit.frontpage',
    'com.discord',
    'com.netflix.mediaclient',
    'com.spotify.music',
    'com.supercell.clashofclans',
    'com.supercell.clashroyale',
    'com.king.candycrushsaga',
    'com.mojang.minecraftpe',
    'com.activision.callofduty.shooter',
  ];
}
