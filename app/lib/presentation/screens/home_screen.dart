import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_coach/core/constants/app_constants.dart';
import 'package:fitness_coach/core/theme/app_theme.dart';
import 'package:fitness_coach/domain/models/exercise.dart';
import 'package:fitness_coach/presentation/providers/app_provider.dart';
import 'package:fitness_coach/presentation/widgets/time_balance_card.dart';
import 'package:fitness_coach/presentation/widgets/streak_indicator.dart';
import 'package:fitness_coach/presentation/widgets/exercise_card.dart';
import 'package:fitness_coach/presentation/screens/exercise_screen.dart';
import 'package:fitness_coach/presentation/screens/apps_screen.dart';
import 'package:fitness_coach/presentation/screens/stats_screen.dart';
import 'package:fitness_coach/presentation/screens/settings_screen.dart';
import 'package:fitness_coach/presentation/screens/balance_details_screen.dart';

/// Main home screen with navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _hasCheckedNotificationPermission = false;

  late final List<Widget> _screens = [
    const _HomeContent(),
    const AppsScreen(),
    const StatsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check notification permission after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force time sync when app comes to foreground
      context.read<AppProvider>().forceTimeSync();
    }
  }

  Future<void> _checkNotificationPermission() async {
    if (_hasCheckedNotificationPermission) return;
    _hasCheckedNotificationPermission = true;
    
    final provider = context.read<AppProvider>();
    // Check actual system permission status, not app settings
    final hasSystemPermission = await provider.checkNotificationPermission();
    if (!hasSystemPermission) {
      // Show permission request dialog
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showNotificationPermissionDialog();
      }
    }
  }

  void _showNotificationPermissionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _NotificationPermissionSheet(
        onAllow: () async {
          Navigator.pop(ctx);
          final provider = context.read<AppProvider>();
          final granted = await provider.requestNotificationPermission();
          if (granted) {
            await provider.setNotificationsEnabled(true);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Уведомления включены!'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          }
        },
        onDeny: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.surfaceLight,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Главная'),
                _buildNavItem(1, Icons.apps_outlined, Icons.apps, 'Приложения'),
                _buildNavItem(2, Icons.bar_chart_outlined, Icons.bar_chart, 'Статистика'),
                _buildNavItem(3, Icons.settings_outlined, Icons.settings, 'Настройки'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home screen content
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final stats = provider.userStats;
        final settings = provider.settings;

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FitLock',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getGreeting(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (stats.currentStreak > 0)
                        StreakBadge(streakDays: stats.currentStreak, showLabel: true),
                    ],
                  ),
                ),
              ),

              // Time balance card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TimeBalanceCard(
                    availableMinutes: provider.usableMinutes,
                    todayEarned: _getTodayEarned(provider),
                    todaySpent: _getTodaySpent(provider),
                    freeBalance: provider.dailyBalance.freeBalance,
                    earnedBalance: provider.dailyBalance.earnedBalance,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BalanceDetailsScreen()),
                    ),
                  ),
                ),
              ),

              // Streak indicator
              if (settings.strikeModeEnabled) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: StreakIndicator(
                      streakDays: stats.currentStreak,
                      multiplier: stats.streakMultiplier,
                    ),
                  ),
                ),
              ],

              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Row(
                    children: [
                      Text(
                        'Начать тренировку',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          settings.difficulty.displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Exercise cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildExerciseCard(
                      context,
                      ExerciseType.pushUp,
                      settings.pushUpRewardMinutes,
                      settings.pushUpRequirement,
                      delay: 200,
                    ),
                    const SizedBox(height: 12),
                    _buildExerciseCard(
                      context,
                      ExerciseType.squat,
                      settings.squatRewardMinutes,
                      settings.squatRequirement,
                      delay: 300,
                    ),
                    const SizedBox(height: 12),
                    _buildExerciseCard(
                      context,
                      ExerciseType.plank,
                      settings.plankRewardMinutes,
                      settings.plankSecondRequirement,
                      delay: 400,
                    ),
                    const SizedBox(height: 12),
                    _buildExerciseCard(
                      context,
                      ExerciseType.lunge,
                      settings.squatRewardMinutes,
                      settings.squatRequirement,
                      delay: 500,
                    ),
                    const SizedBox(height: 12),
                    _buildExerciseCard(
                      context,
                      ExerciseType.jumpingJack,
                      settings.pushUpRewardMinutes,
                      settings.pushUpRequirement,
                      delay: 600,
                    ),
                    const SizedBox(height: 12),
                    _buildExerciseCard(
                      context,
                      ExerciseType.highKnees,
                      settings.pushUpRewardMinutes,
                      settings.pushUpRequirement,
                      delay: 700,
                    ),
                    const SizedBox(height: 12),
                    _buildExerciseCard(
                      context,
                      ExerciseType.freeActivity,
                      1, // 1 minute per 60 seconds
                      60, // 60 seconds requirement
                      delay: 800,
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),

              // Quick stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildQuickStats(context, stats),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    ExerciseType type,
    int reward,
    int requirement, {
    int delay = 0,
  }) {
    return ExerciseCard(
      exerciseType: type,
      rewardMinutes: reward,
      requirement: requirement,
      onTap: () => _startExercise(context, type),
    );
  }

  void _startExercise(BuildContext context, ExerciseType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseScreen(exerciseType: type),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, stats) {
    // All 7 exercises - sorted by progress (completed first)
    final exercises = [
      _QuickStatData('💪', stats.totalPushUps, 'отжиманий', AppColors.pushUpColor),
      _QuickStatData('🦵', stats.totalSquats, 'приседаний', AppColors.squatColor),
      _QuickStatData('🧘', stats.totalPlankSeconds, 'сек планки', AppColors.plankColor),
      _QuickStatData('🏃', stats.totalLunges, 'выпадов', AppColors.lungeColor),
      _QuickStatData('⭐', stats.totalJumpingJacks, 'джампинг', AppColors.jumpingJackColor),
      _QuickStatData('🦶', stats.totalHighKnees, 'высок.колени', AppColors.highKneesColor),
      _QuickStatData('🔥', stats.totalFreeActivitySeconds, 'сек актив.', AppColors.fireOrange),
    ];
    
    // Sort: exercises with progress first
    exercises.sort((a, b) {
      if (a.value > 0 && b.value == 0) return -1;
      if (a.value == 0 && b.value > 0) return 1;
      return b.value.compareTo(a.value);
    });
    
    final hasAnyProgress = exercises.any((e) => e.value > 0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surface.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Ваш прогресс',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${stats.totalWorkouts} тренировок',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasAnyProgress)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Начните тренировку!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: exercises.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => _buildCompactStat(context, exercises[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(BuildContext context, _QuickStatData data) {
    return Container(
      width: 75,
      height: 78,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: data.value > 0 
            ? data.color.withValues(alpha: 0.15) 
            : AppColors.surfaceLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(data.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            data.value.toString(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: data.value > 0 ? data.color : AppColors.textSecondary,
            ),
          ),
          Text(
            data.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 8,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Доброе утро!';
    if (hour < 18) return 'Добрый день!';
    return 'Добрый вечер!';
  }

  int _getTodayEarned(AppProvider provider) {
    final today = DateTime.now();
    final stats = provider.getDailyStats(
      DateTime(today.year, today.month, today.day),
      DateTime(today.year, today.month, today.day + 1),
    );
    if (stats.isEmpty) return 0;
    return stats.first.earnedMinutes;
  }

  int _getTodaySpent(AppProvider provider) {
    final today = DateTime.now();
    final stats = provider.getDailyStats(
      DateTime(today.year, today.month, today.day),
      DateTime(today.year, today.month, today.day + 1),
    );
    if (stats.isEmpty) return 0;
    return stats.first.spentMinutes;
  }
}

class _QuickStatData {
  final String icon;
  final int value;
  final String label;
  final Color color;

  _QuickStatData(this.icon, this.value, this.label, this.color);
}

/// Notification permission request sheet
class _NotificationPermissionSheet extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  const _NotificationPermissionSheet({
    required this.onAllow,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Включить уведомления?',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Напомним о тренировках',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildBenefitRow(context, '🌅', 'Утреннее напоминание о балансе'),
                const SizedBox(height: 12),
                _buildBenefitRow(context, '⏰', 'Предупреждение когда время заканчивается'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDeny,
                  child: const Text('Позже'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onAllow,
                  child: const Text('Включить'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(BuildContext context, String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
