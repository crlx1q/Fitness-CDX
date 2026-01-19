import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
  int _selectedPeriod = 0; // 0 = week, 1 = month

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final stats = provider.userStats;
        final dailyStats = _getDailyStats(provider);

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
                        value: stats.totalWorkouts.toString(),
                        icon: Icons.fitness_center,
                        color: AppColors.primary,
                      ),
                      _SummaryCard(
                        title: 'Текущий стрик',
                        value: '${stats.currentStreak} дн.',
                        icon: Icons.local_fire_department,
                        color: AppColors.primary,
                      ),
                      _SummaryCard(
                        title: 'Лучший стрик',
                        value: '${stats.longestStreak} дн.',
                        icon: Icons.emoji_events,
                        color: AppColors.primary,
                      ),
                      _SummaryCard(
                        title: 'Заработано времени',
                        value: _formatMinutes(stats.totalEarnedMinutes),
                        icon: Icons.timer,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),

              // Period selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    children: [
                      Text(
                        'Активность',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _PeriodSelector(
                        selectedIndex: _selectedPeriod,
                        onSelected: (index) => setState(() => _selectedPeriod = index),
                      ),
                    ],
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
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: _buildChart(dailyStats),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              ),

              // Daily breakdown
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Дни',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final dayStats = dailyStats[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: _DailyStatsTile(
                        stats: dayStats,
                        onTap: () => _showDailyDetails(context, dayStats),
                      ),
                    );
                  },
                  childCount: dailyStats.length,
                ),
              ),

              // Exercise breakdown - compact progress view
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: _ExerciseProgressCard(stats: stats),
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
                child: _buildRecordsSection(context, stats, dailyStats),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  List<DailyStats> _getDailyStats(AppProvider provider) {
    final now = DateTime.now();
    final days = _selectedPeriod == 0 ? 7 : 30;
    final start = DateTime(now.year, now.month, now.day - days + 1);
    final end = DateTime(now.year, now.month, now.day + 1);
    final stats = provider.getDailyStats(start, end);
    final dataMap = <String, DailyStats>{};
    for (final stat in stats) {
      dataMap[stat.dateKey] = stat;
    }
    final full = <DailyStats>[];
    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day - days + 1 + i);
      final key = DailyStats.dateToKey(date);
      full.add(dataMap[key] ?? DailyStats(dateKey: key));
    }
    return full;
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

    final days = _selectedPeriod == 0 ? 7 : 30;
    final now = DateTime.now();
    
    // Create data map for quick lookup
    final dataMap = <String, int>{};
    for (final stat in dailyStats) {
      dataMap[stat.dateKey] = stat.earnedMinutes;
    }

    // Generate bars for each day
    final bars = <BarChartGroupData>[];
    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day - days + 1 + i);
      final key = DailyStats.dateToKey(date);
      final value = dataMap[key] ?? 0;
      
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              color: AppColors.primary,
              width: days == 7 ? 24 : 8,
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
              final date = DateTime(now.year, now.month, now.day - days + 1 + group.x);
              return BarTooltipItem(
                '${DateFormat('d MMM', 'ru').format(date)}\n${rod.toY.toInt()} мин',
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
                if (days == 7) {
                  final date = DateTime(now.year, now.month, now.day - days + 1 + value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('E', 'ru').format(date).substring(0, 2),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  );
                }
                // Show every 5th day for month view
                if (value.toInt() % 5 == 0) {
                  final date = DateTime(now.year, now.month, now.day - days + 1 + value.toInt());
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

  Widget _buildRecordsSection(BuildContext context, UserStats stats, List<DailyStats> dailyStats) {
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
              value: '${stats.longestStreak} дней',
            ),
            const Divider(color: AppColors.surfaceLight, height: 24),
            _RecordRow(
              icon: Icons.star,
              iconColor: AppColors.primary,
              title: 'Лучший день',
              value: bestDay != null 
                  ? '${_formatMinutes(bestDay.earnedMinutes)} (${DateFormat('d MMM').format(bestDay.date)})' 
                  : '—',
            ),
            const Divider(color: AppColors.surfaceLight, height: 24),
            _RecordRow(
              icon: Icons.calendar_today,
              iconColor: AppColors.primary,
              title: 'Дней с FitLock',
              value: '${DateTime.now().difference(stats.createdAt).inDays + 1} дней',
            ),
            const Divider(color: AppColors.surfaceLight, height: 24),
            _RecordRow(
              icon: Icons.phone_android,
              iconColor: AppColors.primary,
              title: 'Потрачено времени',
              value: _formatMinutes(stats.totalSpentMinutes),
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

class _DailyStatsTile extends StatelessWidget {
  final DailyStats stats;
  final VoidCallback onTap;

  const _DailyStatsTile({
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasActivity = stats.earnedMinutes > 0 || stats.spentMinutes > 0 || stats.workoutCount > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasActivity ? AppColors.primary.withValues(alpha: 0.3) : AppColors.surfaceLight,
          ),
        ),
        child: Row(
          children: [
            Text(
              DateFormat('d MMM', 'ru').format(stats.date),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            Text(
              _formatMinutesValue(stats.earnedMinutes),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: hasActivity ? AppColors.primary : AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
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
  if (minutes >= 60) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}ч ${mins}м' : '${hours}ч';
  }
  return '${minutes}м';
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

class _PeriodSelector extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelected;

  const _PeriodSelector({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _PeriodButton(
            label: 'Неделя',
            isSelected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _PeriodButton(
            label: 'Месяц',
            isSelected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
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
