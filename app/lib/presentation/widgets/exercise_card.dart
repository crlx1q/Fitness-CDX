import 'package:flutter/material.dart';
import 'package:fitness_coach/core/theme/app_theme.dart';
import 'package:fitness_coach/core/utils/time_formatter.dart';
import 'package:fitness_coach/domain/models/exercise.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Card for selecting an exercise type
class ExerciseCard extends StatelessWidget {
  final ExerciseType exerciseType;
  final int rewardMinutes;
  final int requirement;
  final bool isSelected;
  final VoidCallback? onTap;

  const ExerciseCard({
    super.key,
    required this.exerciseType,
    required this.rewardMinutes,
    required this.requirement,
    this.isSelected = false,
    this.onTap,
  });

  Color get _exerciseColor {
    switch (exerciseType) {
      case ExerciseType.pushUp:
        return AppColors.pushUpColor;
      case ExerciseType.squat:
      case ExerciseType.lunge:
        return AppColors.squatColor;
      case ExerciseType.plank:
        return AppColors.plankColor;
      case ExerciseType.jumpingJack:
        return AppColors.accent;
      case ExerciseType.highKnees:
        return AppColors.fireOrange;
      case ExerciseType.freeActivity:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? _exerciseColor.withValues(alpha: 0.15) 
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? _exerciseColor 
                : AppColors.surfaceLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _exerciseColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _exerciseColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    exerciseType.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exerciseType.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRequirementText(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _exerciseColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Reward info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+${formatMinutes(rewardMinutes)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRequirementText() {
    switch (exerciseType) {
      case ExerciseType.pushUp:
        return '$requirement отжиманий';
      case ExerciseType.squat:
        return '$requirement приседаний';
      case ExerciseType.lunge:
        return '$requirement выпадов';
      case ExerciseType.jumpingJack:
        return '$requirement джампингов';
      case ExerciseType.highKnees:
        return '$requirement подъемов';
      case ExerciseType.plank:
        return '$requirement сек планки';
      case ExerciseType.freeActivity:
        final seconds = requirement;
        if (seconds >= 60) {
          final minutes = seconds ~/ 60;
          return '${formatMinutes(minutes)} свободной активности';
        }
        return '$seconds сек свободной активности';
    }
  }
}

/// Quick action button for starting an exercise
class QuickExerciseButton extends StatelessWidget {
  final ExerciseType exerciseType;
  final VoidCallback? onTap;

  const QuickExerciseButton({
    super.key,
    required this.exerciseType,
    this.onTap,
  });

  Color get _exerciseColor {
    switch (exerciseType) {
      case ExerciseType.pushUp:
        return AppColors.pushUpColor;
      case ExerciseType.squat:
      case ExerciseType.lunge:
        return AppColors.squatColor;
      case ExerciseType.plank:
        return AppColors.plankColor;
      case ExerciseType.jumpingJack:
        return AppColors.accent;
      case ExerciseType.highKnees:
        return AppColors.fireOrange;
      case ExerciseType.freeActivity:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _exerciseColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _exerciseColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              exerciseType.icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              exerciseType.displayName,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: _exerciseColor,
              size: 14,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.0, 1.0),
    );
  }
}
