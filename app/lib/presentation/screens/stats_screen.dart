import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:fitness_coach/core/constants/app_constants.dart';
import 'package:fitness_coach/core/theme/app_theme.dart';
import 'package:fitness_coach/domain/models/user_stats.dart';
import 'package:fitness_coach/presentation/providers/app_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Statistics and progress screen
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final userStats = provider.userStats;
        final allDailyStats = _getDailyStats(provider);
        final recentDailyStats = _getRecentDailyStats(allDailyStats, userStats.createdAt);
        final chartStats = _getWeekStats(recentDailyStats, userStats.createdAt);
        final summary = _buildSummaryStats(recentDailyStats);

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Статистика',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ваш прогресс и достижения',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              // Summary cards
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _SummaryCard(
                        title: 'Всего тренировок',
                        value: summary.totalWorkouts.toString(),
                        icon: Icons.fitness_center,
                        color: AppColors.primary,
                      ),
                      _SummaryCard(
                        title: 'Текущий стрик',
                        value: '${summary.currentStreak} дн.',
                        icon: Icons.local_fire_department,
                        color: AppColors.primary,
                      ),
                      _SummaryCard(
                        title: 'Лучший стрик',
                        value: '${summary.longestStreak} дн.',
                        icon: Icons.emoji_events,
                        color: AppColors.primary,
                      ),
                      _SummaryCard(
                        title: 'Заработано времени',
                        value: _formatMinutes(summary.totalEarnedMinutes),
                        icon: Icons.timer,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Text(
                    'Активность',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Activity chart
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Заработанные минуты',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (chartStats.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatChartRange(chartStats),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: _buildChart(chartStats),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              ),

              // Daily breakdown
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        'Дни',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${recentDailyStats.length} записано',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _DailyPager(
                  stats: recentDailyStats,
                  initialPage: recentDailyStats.isEmpty ? 0 : recentDailyStats.length - 1,
                  onTap: (dayStats) => _showDailyDetails(context, dayStats),
                ),
              ),

              // Exercise breakdown - compact progress view
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: _ExerciseProgressCard(stats: userStats),
                ),
              ),

              // Records section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Text(
                    'Рекорды',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _buildRecordsSection(context, summary, recentDailyStats),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  List<DailyStats> _getDailyStats(AppProvider provider) {
    final stats = provider.getAllDailyStats().toList();
    stats.sort((a, b) => a.date.compareTo(b.date));
    return stats;
  }

  List<DailyStats> _getRecentDailyStats(List<DailyStats> dailyStats, DateTime createdAt) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final retentionDays = AppConstants.dailyStatsRetentionDays;
    final startCandidate = todayDate.subtract(Duration(days: retentionDays - 1));
    final start = createdDate.isAfter(startCandidate) ? createdDate : startCandidate;

    final byKey = {for (final stat in dailyStats) stat.dateKey: stat};
    final days = todayDate.difference(start).inDays;
    return List.generate(days + 1, (index) {
      final date = start.add(Duration(days: index));
      final key = DailyStats.dateToKey(date);
      return byKey[key] ?? DailyStats(dateKey: key);
    });
  }

  List<DailyStats> _getWeekStats(List<DailyStats> recentDailyStats, DateTime createdAt) {
    if (recentDailyStats.isEmpty) return [];
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final weekStartWeekday = createdAt.weekday;
    var offset = todayDate.weekday - weekStartWeekday;
    if (offset < 0) {
      offset += 7;
    }
    final start = todayDate.subtract(Duration(days: offset));
    final byKey = {for (final stat in recentDailyStats) stat.dateKey: stat};
    return List.generate(7, (index) {
      final date = start.add(Duration(days: index));
      final key = DailyStats.dateToKey(date);
      return byKey[key] ?? DailyStats(dateKey: key);
    });
  }

  _SummaryStats _buildSummaryStats(List<DailyStats> dailyStats) {
    var totalWorkouts = 0;
    var totalEarnedMinutes = 0;
    var totalSpentMinutes = 0;

    for (final day in dailyStats) {
      totalWorkouts += day.workoutCount;
      totalEarnedMinutes += day.earnedMinutes;
      totalSpentMinutes += day.spentMinutes;
    }

    return _SummaryStats(
      totalWorkouts: totalWorkouts,
      totalEarnedMinutes: totalEarnedMinutes,
      totalSpentMinutes: totalSpentMinutes,
      currentStreak: _calculateCurrentStreak(dailyStats),
      longestStreak: _calculateLongestStreak(dailyStats),
      daysCount: dailyStats.length,
    );
  }

  int _calculateCurrentStreak(List<DailyStats> dailyStats) {
    var streak = 0;
    for (int i = dailyStats.length - 1; i >= 0; i--) {
      if (_hasWorkoutActivity(dailyStats[i])) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int _calculateLongestStreak(List<DailyStats> dailyStats) {
    var longest = 0;
    var current = 0;
    for (final day in dailyStats) {
      if (_hasWorkoutActivity(day)) {
        current++;
        if (current > longest) {
          longest = current;
        }
      } else {
        current = 0;
      }
    }
    return longest;
  }

  String _formatChartRange(List<DailyStats> dailyStats) {
    if (dailyStats.isEmpty) return '';
    final start = dailyStats.first.date;
    final end = dailyStats.last.date;
    if (DateUtils.isSameDay(start, end)) {
      return DateFormat('d MMM', 'ru').format(start);
    }
    final startLabel = DateFormat('d MMM', 'ru').format(start);
    final endLabel = DateFormat('d MMM', 'ru').format(end);
    return '$startLabel – $endLabel';
  }

  Widget _buildChart(List<DailyStats> dailyStats) {
    if (dailyStats.isEmpty) {
      return Center(
        child: Text(
          'Нет данных за выбранный период',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final bars = <BarChartGroupData>[];
    for (int i = 0; i < dailyStats.length; i++) {
      final value = dailyStats[i].earnedMinutes;
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              color: AppColors.primary,
              width: dailyStats.length <= 7
                  ? 24
                  : dailyStats.length <= 14
                      ? 14
                      : 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    final maxValue = dailyStats
        .map((s) => s.earnedMinutes)
        .reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue == 0 ? 1 : (maxValue * 1.2).toDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceLight,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final date = dailyStats[group.x].date;
              return BarTooltipItem(
                '${DateFormat('d MMM', 'ru').format(date)}\n${_formatMinutesValue(rod.toY.toInt())}',
                const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= dailyStats.length) {
                  return const SizedBox.shrink();
                }
                if (dailyStats.length <= 7) {
                  final date = dailyStats[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('E', 'ru').format(date).substring(0, 2),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  );
                }
                // Show every 5th recorded day for month view
                if (value.toInt() % 5 == 0) {
                  final date = dailyStats[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      date.day.toString(),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: bars,
      ),
    );
  }

  Widget _buildRecordsSection(
    BuildContext context,
    _SummaryStats summary,
    List<DailyStats> dailyStats,
  ) {
    // Find best day
    DailyStats? bestDay;
    for (final day in dailyStats) {
      if (day.earnedMinutes <= 0) continue;
      if (bestDay == null || day.earnedMinutes > bestDay.earnedMinutes) {
        bestDay = day;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _RecordRow(
              icon: Icons.emoji_events,
              iconColor: AppColors.primary,
              title: 'Лучший стрик',
              value: '${summary.longestStreak} дней',
            ),
            const Divider(color: AppColors.surfaceLight, height: 24),
            _RecordRow(
              icon: Icons.star,
              iconColor: AppColors.primary,
              title: 'Лучший день',
              value: bestDay != null 
                  ? '${_formatMinutes(bestDay.earnedMinutes)} (${DateFormat('d MMM', 'ru').format(bestDay.date)})' 
                  : '-',
            ),
            const Divider(color: AppColors.surfaceLight, height: 24),
            _RecordRow(
              icon: Icons.calendar_today,
              iconColor: AppColors.primary,
              title: 'Дней в периоде',
              value: '${summary.daysCount} дней',
            ),
            const Divider(color: AppColors.surfaceLight, height: 24),
            _RecordRow(
              icon: Icons.phone_android,
              iconColor: AppColors.primary,
              title: 'Потрачено времени',
              value: _formatMinutes(summary.totalSpentMinutes),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  String _formatMinutes(int minutes) => _formatMinutesValue(minutes);

  void _showDailyDetails(BuildContext context, DailyStats stats) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('d MMMM', 'ru').format(stats.date),
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _DailyStatLine(label: 'Заработано', value: _formatMinutes(stats.earnedMinutes)),
              _DailyStatLine(label: 'Потрачено', value: _formatMinutes(stats.spentMinutes)),
              _DailyStatLine(label: 'Время в приложениях', value: _formatMinutes(stats.spentMinutes)),
              _DailyStatLine(label: 'Тренировок', value: stats.workoutCount.toString()),
              _DailyStatLine(label: 'Отжиманий', value: stats.pushUps.toString()),
              _DailyStatLine(label: 'Приседаний', value: stats.squats.toString()),
              _DailyStatLine(label: 'Планка', value: '${stats.plankSeconds} сек'),
              _DailyStatLine(label: 'Активность', value: '${stats.freeActivitySeconds} сек'),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _DailyPager extends StatelessWidget {
  final List<DailyStats> stats;
  final int initialPage;
  final ValueChanged<DailyStats> onTap;

  const _DailyPager({
    required this.stats,
    required this.initialPage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Нет записанных дней за период',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      );
    }

    final safeInitialPage = initialPage.clamp(0, stats.length - 1);

    return SizedBox(
      height: 136,
      child: PageView.builder(
        controller: PageController(
          viewportFraction: 0.85,
          initialPage: safeInitialPage,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final dayStats = stats[index];
          return Padding(
            padding: const EdgeInsets.only(left: 20, right: 12),
            child: _DailyStatsTile(
              stats: dayStats,
              onTap: () => onTap(dayStats),
            ),
          );
        },
      ),
    );
  }
}

class _DailyStatsTile extends StatelessWidget {
  final DailyStats stats;
  final VoidCallback onTap;

  const _DailyStatsTile({
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('d MMM', 'ru').format(stats.date),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _DailyStatChip(
              label: 'Заработано',
              value: _formatMinutesValue(stats.earnedMinutes),
              color: AppColors.success,
            ),
            const SizedBox(height: 8),
            _DailyStatChip(
              label: 'Потрачено',
              value: _formatMinutesValue(stats.spentMinutes),
              color: AppColors.error,
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DailyStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _DailyStatLine extends StatelessWidget {
  final String label;
  final String value;

  const _DailyStatLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

String _formatMinutesValue(int minutes) {
  if (minutes <= 0) return '0м';
  if (minutes >= 60) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}ч ${mins}м' : '${hours}ч';
  }
  return '${minutes}м';
}

bool _hasWorkoutActivity(DailyStats stats) {
  return stats.workoutCount > 0;
}

class _SummaryStats {
  final int totalWorkouts;
  final int totalEarnedMinutes;
  final int totalSpentMinutes;
  final int currentStreak;
  final int longestStreak;
  final int daysCount;

  const _SummaryStats({
    required this.totalWorkouts,
    required this.totalEarnedMinutes,
    required this.totalSpentMinutes,
    required this.currentStreak,
    required this.longestStreak,
    required this.daysCount,
  });
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}

/// Compact exercise progress card with horizontal bars
class _ExerciseProgressCard extends StatelessWidget {
  final UserStats stats;

  const _ExerciseProgressCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final exercises = [
      _ExerciseData('💪', 'Отжимания', stats.totalPushUps, AppColors.pushUpColor),
      _ExerciseData('🦵', 'Приседания', stats.totalSquats, AppColors.squatColor),
      _ExerciseData('🧘', 'Планка', stats.totalPlankSeconds, AppColors.plankColor, isTime: true),
      _ExerciseData('🏃', 'Выпады', stats.totalLunges, AppColors.lungeColor),
      _ExerciseData('⭐', 'Джампинг', stats.totalJumpingJacks, AppColors.jumpingJackColor),
      _ExerciseData('🦶', 'Высокие колени', stats.totalHighKnees, AppColors.highKneesColor),
      _ExerciseData('🔥', 'Активность', stats.totalFreeActivitySeconds, AppColors.fireOrange, isTime: true),
    ];

    // Find max value for relative progress
    final maxValue = exercises.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'По упражнениям',
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
          const SizedBox(height: 16),
          ...exercises.map((ex) => _buildExerciseRow(context, ex, maxValue)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildExerciseRow(BuildContext context, _ExerciseData data, int maxValue) {
    final progress = maxValue > 0 ? data.value / maxValue : 0.0;
    final displayValue = data.isTime 
        ? _formatTime(data.value) 
        : data.value.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(data.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              data.title,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: data.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 50,
            child: Text(
              displayValue,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: data.value > 0 ? data.color : AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}с';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return secs > 0 ? '${mins}м ${secs}с' : '${mins}м';
  }
}

class _ExerciseData {
  final String icon;
  final String title;
  final int value;
  final Color color;
  final bool isTime;

  _ExerciseData(this.icon, this.title, this.value, this.color, {this.isTime = false});
}

class _RecordRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _RecordRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
