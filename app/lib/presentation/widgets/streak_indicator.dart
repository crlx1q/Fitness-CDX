import 'package:flutter/material.dart';
import 'package:fitness_coach/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Streak fire indicator with animation
class StreakIndicator extends StatelessWidget {
  final int streakDays;
  final double multiplier;
  final bool isAnimated;

  const StreakIndicator({
    super.key,
    required this.streakDays,
    this.multiplier = 1.0,
    this.isAnimated = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasStreak = streakDays > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: hasStreak
            ? LinearGradient(
                colors: [
                  AppColors.fireOrange.withValues(alpha: 0.2),
                  AppColors.fireRed.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: hasStreak ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasStreak 
              ? AppColors.fireOrange.withValues(alpha: 0.5) 
              : AppColors.surfaceLight,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fire icon
          _buildFireIcon(hasStreak),
          const SizedBox(width: 12),
          
          // Streak info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$streakDays ${_getDaysLabel(streakDays)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: hasStreak ? AppColors.fireOrange : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (multiplier > 1.0)
                Text(
                  'x${multiplier.toStringAsFixed(1)} бонус',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.fireYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFireIcon(bool hasStreak) {
    Widget icon = Text(
      hasStreak ? '🔥' : '❄️',
      style: const TextStyle(fontSize: 32),
    );

    if (isAnimated && hasStreak) {
      icon = icon
          .animate(onPlay: (controller) => controller.repeat())
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.15, 1.15),
            duration: 600.ms,
          )
          .then()
          .scale(
            begin: const Offset(1.15, 1.15),
            end: const Offset(1.0, 1.0),
            duration: 600.ms,
          );
    }

    return icon;
  }

  String _getDaysLabel(int days) {
    if (days % 10 == 1 && days % 100 != 11) {
      return 'день подряд';
    } else if ([2, 3, 4].contains(days % 10) && ![12, 13, 14].contains(days % 100)) {
      return 'дня подряд';
    }
    return 'дней подряд';
  }
}

/// Compact streak badge for app bar or cards
class StreakBadge extends StatelessWidget {
  final int streakDays;
  final bool showLabel;

  const StreakBadge({
    super.key,
    required this.streakDays,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    if (streakDays <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.fireOrange,
            AppColors.fireRed,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            showLabel ? '$streakDays дн.' : streakDays.toString(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 2.seconds,
          color: Colors.white.withValues(alpha: 0.3),
        );
  }
}

/// Streak milestone celebration widget
class StreakMilestone extends StatelessWidget {
  final int streakDays;
  final VoidCallback? onDismiss;

  const StreakMilestone({
    super.key,
    required this.streakDays,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final milestone = _getMilestoneInfo(streakDays);
    if (milestone == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.fireOrange.withValues(alpha: 0.3),
            AppColors.fireRed.withValues(alpha: 0.2),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.fireOrange,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            milestone['emoji'] as String,
            style: const TextStyle(fontSize: 64),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .then()
              .shake(duration: 500.ms),
          const SizedBox(height: 16),
          Text(
            milestone['title'] as String,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.fireOrange,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            milestone['message'] as String,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onDismiss != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onDismiss,
              child: const Text('Продолжить'),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Map<String, String>? _getMilestoneInfo(int days) {
    if (days == 3) {
      return {
        'emoji': '🎯',
        'title': '3 дня подряд!',
        'message': 'Отличное начало! Бонус x1.2 активирован.',
      };
    } else if (days == 7) {
      return {
        'emoji': '🔥',
        'title': 'Неделя силы!',
        'message': '7 дней тренировок! Бонус x1.5 активирован.',
      };
    } else if (days == 14) {
      return {
        'emoji': '💪',
        'title': '2 недели!',
        'message': 'Вы машина! Бонус x1.75 активирован.',
      };
    } else if (days == 30) {
      return {
        'emoji': '👑',
        'title': 'Месяц дисциплины!',
        'message': 'Невероятно! Максимальный бонус x2.0!',
      };
    }
    return null;
  }
}
