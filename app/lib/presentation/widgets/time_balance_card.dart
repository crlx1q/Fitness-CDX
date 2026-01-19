import 'package:flutter/material.dart';
import 'package:fitness_coach/core/theme/app_theme.dart';

/// Card displaying available screen time balance
class TimeBalanceCard extends StatelessWidget {
  final int availableMinutes;
  final int todayEarned;
  final int todaySpent;
  final VoidCallback? onTap;
  final int freeBalance;
  final int earnedBalance;
  final int debtMinutes;
  final int debtCreditRemaining;

  const TimeBalanceCard({
    super.key,
    required this.availableMinutes,
    this.todayEarned = 0,
    this.todaySpent = 0,
    this.onTap,
    this.freeBalance = 0,
    this.earnedBalance = 0,
    this.debtMinutes = 0,
    this.debtCreditRemaining = 0,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = AppColors.primary;
    final hasDebt = debtMinutes > 0;
    final isLockedByDebt = hasDebt && debtCreditRemaining == 0;
    final balanceColor = isLockedByDebt ? AppColors.textSecondary : AppColors.textPrimary;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: 0.3),
              primaryColor.withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Баланс времени',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Main balance display
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(availableMinutes),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: availableMinutes > 0
                        ? balanceColor
                        : (isLockedByDebt ? AppColors.textSecondary : AppColors.error),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'доступно',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            
            // Show breakdown if has both free and earned
            if (freeBalance > 0 ||
                earnedBalance > 0 ||
                debtMinutes > 0 ||
                debtCreditRemaining > 0) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (debtCreditRemaining > 0)
                    _buildMiniStat(
                      context,
                      '⏳',
                      _formatTime(debtCreditRemaining),
                      'в долг',
                    ),
                  if (debtMinutes > 0)
                    _buildMiniStat(
                      context,
                      '🧾',
                      _formatTime(debtMinutes),
                      'долг',
                      dimmed: true,
                    ),
                  if (freeBalance > 0)
                    _buildMiniStat(
                      context,
                      '🎁',
                      _formatTime(freeBalance),
                      'бесплатно',
                    ),
                  if (earnedBalance > 0)
                    _buildMiniStat(
                      context,
                      '💪',
                      _formatTime(earnedBalance),
                      'заработано',
                    ),
                ],
              ),
            ],
            
            // Today stats
            if (todayEarned > 0 || todaySpent > 0) ...[
              const SizedBox(height: 16),
              const Divider(color: AppColors.surfaceLight),
              const SizedBox(height: 12),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  if (todayEarned > 0)
                    _buildTodayStat(
                      context,
                      icon: Icons.add_circle_outline,
                      value: '+${_formatTime(todayEarned)}',
                      color: AppColors.success,
                      label: 'Заработано',
                    ),
                  if (todaySpent > 0)
                    _buildTodayStat(
                      context,
                      icon: Icons.remove_circle_outline,
                      value: '-${_formatTime(todaySpent)}',
                      color: AppColors.error,
                      label: 'Потрачено',
                    ),
                ],
              ),
            ],
            
            // Zero balance - show workout prompt
            if (availableMinutes <= 0) ...[
              const SizedBox(height: 16),
              _buildZeroBalanceSection(context, isLockedByDebt),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildZeroBalanceSection(BuildContext context, bool isLockedByDebt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.fitness_center,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isLockedByDebt
                  ? 'Сначала отработайте долг, чтобы снова пользоваться временем'
                  : 'Потренируйтесь, чтобы заработать время',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    String icon,
    String value,
    String label, {
    bool dimmed = false,
  }) {
    final textColor = dimmed ? AppColors.textHint : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: dimmed ? AppColors.textHint : AppColors.textHint,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required Color color,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  String _formatTime(int minutes) {
    if (minutes <= 0) return '0м';
    
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0 && mins > 0) {
      return '${hours}ч ${mins}м';
    } else if (hours > 0) {
      return '${hours}ч';
    }
    return '${mins}м';
  }
}

/// Compact time badge for app bar
class TimeBadge extends StatelessWidget {
  final int minutes;

  const TimeBadge({
    super.key,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context) {
    final hasTime = minutes > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasTime 
            ? AppColors.success.withValues(alpha: 0.2) 
            : AppColors.error.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasTime 
              ? AppColors.success.withValues(alpha: 0.5) 
              : AppColors.error.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: hasTime ? AppColors.success : AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _formatCompact(minutes),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: hasTime ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompact(int minutes) {
    if (minutes <= 0) return '0м';
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}ч${mins}м' : '${hours}ч';
    }
    return '${minutes}м';
  }
}
