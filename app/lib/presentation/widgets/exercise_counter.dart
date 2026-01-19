import 'package:flutter/material.dart';
import 'package:fitness_coach/core/theme/app_theme.dart';
import 'package:fitness_coach/domain/models/exercise.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Large exercise counter display with animation
class ExerciseCounter extends StatelessWidget {
  final int count;
  final ExerciseType exerciseType;
  final int earnedMinutes;
  final bool showReward;
  final int? goal; // Goal count for showing progress like "5/15"

  const ExerciseCounter({
    super.key,
    required this.count,
    required this.exerciseType,
    this.earnedMinutes = 0,
    this.showReward = true,
    this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Exercise type indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                exerciseType.icon,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  exerciseType.displayName.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Main counter with goal format
          if (goal != null && !exerciseType.isTimeBased)
            Text(
              '$count/$goal',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 64,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ).animate(
              key: ValueKey(count),
            ).scale(
              begin: const Offset(1.2, 1.2),
              end: const Offset(1.0, 1.0),
              duration: 200.ms,
              curve: Curves.easeOut,
            )
          else
            Text(
              exerciseType.isTimeBased 
                  ? _formatTime(count) 
                  : count.toString(),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 72,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ).animate(
              key: ValueKey(count),
            ).scale(
              begin: const Offset(1.2, 1.2),
              end: const Offset(1.0, 1.0),
              duration: 200.ms,
              curve: Curves.easeOut,
            ),
          
          // Unit label
          Text(
            exerciseType.isTimeBased ? _getTimeLabel(count) : _getCountLabel(count),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          // Earned minutes
          if (showReward && earnedMinutes > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+$earnedMinutes мин',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
          ],
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    // For time-based exercises: show seconds until 60, then minutes format
    if (seconds >= 60) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      if (secs == 0) return '$mins';
      return '$mins:${secs.toString().padLeft(2, '0')}';
    }
    return seconds.toString();
  }

  String _getTimeLabel(int seconds) {
    if (seconds >= 60) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      if (secs == 0) {
        if (mins == 1) return 'минута';
        if (mins >= 2 && mins <= 4) return 'минуты';
        return 'минут';
      }
      return ''; // No label when showing mm:ss format
    }
    return 'секунд';
  }

  String _getCountLabel(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return exerciseType == ExerciseType.pushUp ? 'отжимание' : 'приседание';
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return exerciseType == ExerciseType.pushUp ? 'отжимания' : 'приседания';
    }
    return exerciseType == ExerciseType.pushUp ? 'отжиманий' : 'приседаний';
  }
}

/// Feedback message widget
class ExerciseFeedback extends StatelessWidget {
  final String? message;
  final bool isValid;

  const ExerciseFeedback({
    super.key,
    this.message,
    this.isValid = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: (isValid ? AppColors.success : AppColors.warning).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isValid ? AppColors.success : AppColors.warning).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.info_outline,
            color: isValid ? AppColors.success : AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Angle indicator for form feedback
class AngleIndicator extends StatelessWidget {
  final double currentAngle;
  final double targetAngle;
  final String label;

  const AngleIndicator({
    super.key,
    required this.currentAngle,
    required this.targetAngle,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final difference = (currentAngle - targetAngle).abs();
    final isGood = difference < 15;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${currentAngle.toInt()}°',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isGood ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
