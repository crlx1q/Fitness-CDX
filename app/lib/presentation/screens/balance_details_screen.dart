import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_coach/core/theme/app_theme.dart';
import 'package:fitness_coach/core/constants/app_constants.dart';
import 'package:fitness_coach/presentation/providers/app_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Detailed screen showing balance breakdown
class BalanceDetailsScreen extends StatelessWidget {
  const BalanceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Баланс времени'),
        backgroundColor: AppColors.background,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final balance = provider.dailyBalance;
          final stats = provider.userStats;
          final settings = provider.settings;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main balance card
                _MainBalanceCard(
                  usableMinutes: provider.usableMinutes,
                  isLockedByDebt: balance.debtMinutes > 0 &&
                      balance.debtCreditRemaining == 0 &&
                      balance.freeBalance == 0 &&
                      balance.earnedBalance == 0,
                ).animate().fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 24),

                // Balance breakdown
                _SectionTitle(title: 'Разбивка баланса'),
                const SizedBox(height: 12),
                
                _BalanceBreakdownCard(
                  freeBalance: balance.freeBalance,
                  earnedBalance: balance.earnedBalance,
                  debtMinutes: balance.debtMinutes,
                  debtCreditRemaining: balance.debtCreditRemaining,
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                _SectionTitle(title: 'Долг'),
                const SizedBox(height: 12),
                _DebtCard(
                  debtMinutes: balance.debtMinutes,
                  debtCreditRemaining: balance.debtCreditRemaining,
                  canTakeDebt: provider.canTakeDebt,
                  onTakeDebt: (minutes) async {
                    final success = await provider.takeDebtMinutes(minutes);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Доступно ${_formatMinutes(minutes)} в долг'
                                : 'Сегодня долг уже был использован',
                          ),
                        ),
                      );
                    }
                  },
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // Streak multiplier info
                _SectionTitle(title: 'Множитель за стрик'),
                const SizedBox(height: 12),
                _StreakMultiplierCard(
                  currentStreak: stats.currentStreak,
                  currentMultiplier: stats.streakMultiplier,
                  strikeModeEnabled: settings.strikeModeEnabled,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // Daily allowance info
                _SectionTitle(title: 'Ежедневная норма'),
                const SizedBox(height: 12),
                _DailyAllowanceCard(
                  difficulty: settings.difficulty,
                  freeAllowance: settings.difficulty.freeAllowanceMinutes,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // How it works
                _SectionTitle(title: 'Как это работает'),
                const SizedBox(height: 12),
                _HowItWorksCard().animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _MainBalanceCard extends StatelessWidget {
  final int usableMinutes;
  final bool isLockedByDebt;

  const _MainBalanceCard({
    required this.usableMinutes,
    required this.isLockedByDebt,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.3),
            primaryColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: primaryColor, size: 48),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _formatTime(usableMinutes),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: isLockedByDebt ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Доступно для использования',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int minutes) => _formatMinutes(minutes);
}

class _BalanceBreakdownCard extends StatelessWidget {
  final int freeBalance;
  final int earnedBalance;
  final int debtMinutes;
  final int debtCreditRemaining;

  const _BalanceBreakdownCard({
    required this.freeBalance,
    required this.earnedBalance,
    required this.debtMinutes,
    required this.debtCreditRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (debtCreditRemaining > 0)
            _BalanceRow(
              icon: Icons.schedule,
              label: 'В долг',
              value: debtCreditRemaining,
              color: AppColors.primary,
            ),
          if (debtCreditRemaining > 0)
            const Divider(color: AppColors.surfaceLight, height: 24),
          if (debtMinutes > 0)
            _BalanceRow(
              icon: Icons.receipt_long,
              label: 'Долг',
              value: debtMinutes,
              color: AppColors.textSecondary,
            ),
          if (debtMinutes > 0)
            const Divider(color: AppColors.surfaceLight, height: 24),
          _BalanceRow(
            icon: Icons.card_giftcard,
            label: 'Бесплатно',
            value: freeBalance,
            color: AppColors.success,
          ),
          const Divider(color: AppColors.surfaceLight, height: 24),
          _BalanceRow(
            icon: Icons.fitness_center,
            label: 'Заработано',
            value: earnedBalance,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _BalanceRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
          Text(
            _formatMinutes(value),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
      ],
    );
  }
}

class _DebtCard extends StatefulWidget {
  final int debtMinutes;
  final int debtCreditRemaining;
  final bool canTakeDebt;
  final ValueChanged<int> onTakeDebt;

  const _DebtCard({
    required this.debtMinutes,
    required this.debtCreditRemaining,
    required this.canTakeDebt,
    required this.onTakeDebt,
  });

  @override
  State<_DebtCard> createState() => _DebtCardState();
}

class _DebtCardState extends State<_DebtCard> {
  late int _selectedMinutes;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = _debtOptions.first;
  }

  List<int> get _debtOptions {
    const options = [15, 30, 60, 120];
    return options.where((value) => value <= AppConstants.maxDailyDebtMinutes).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasDebt = widget.debtMinutes > 0;
    final hasCredit = widget.debtCreditRemaining > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                'Лимит долга',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasDebt
                ? 'Нужно отработать ${_formatMinutes(widget.debtMinutes)}'
                : hasCredit
                    ? 'Сегодня доступно ${_formatMinutes(widget.debtCreditRemaining)} в долг'
                    : 'Можно взять до ${_formatMinutes(AppConstants.maxDailyDebtMinutes)} в долг один раз в день',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          if (!hasDebt && !hasCredit) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _debtOptions.map((minutes) {
                final isSelected = _selectedMinutes == minutes;
                return ChoiceChip(
                  label: Text(_formatMinutes(minutes)),
                  selected: isSelected,
                  onSelected: widget.canTakeDebt
                      ? (value) {
                          if (value) {
                            setState(() => _selectedMinutes = minutes);
                          }
                        }
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.canTakeDebt ? () => widget.onTakeDebt(_selectedMinutes) : null,
                child: const Text('Взять в долг'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StreakMultiplierCard extends StatelessWidget {
  final int currentStreak;
  final double currentMultiplier;
  final bool strikeModeEnabled;

  const _StreakMultiplierCard({
    required this.currentStreak,
    required this.currentMultiplier,
    required this.strikeModeEnabled,
  });

  @override
  Widget build(BuildContext context) {
    if (!strikeModeEnabled) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ударный режим выключен в настройках',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.fireOrange.withValues(alpha: 0.15),
            AppColors.fireRed.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fireOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Текущий стрик: $currentStreak дней',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Множитель: x$currentMultiplier',
                      style: TextStyle(
                        color: AppColors.fireOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Множители:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MultiplierChip(days: 3, multiplier: AppConstants.streakMultiplier3Days, current: currentStreak),
              _MultiplierChip(days: 7, multiplier: AppConstants.streakMultiplier7Days, current: currentStreak),
              _MultiplierChip(days: 14, multiplier: AppConstants.streakMultiplier14Days, current: currentStreak),
              _MultiplierChip(days: 30, multiplier: AppConstants.streakMultiplier30Days, current: currentStreak),
            ],
          ),
        ],
      ),
    );
  }
}

class _MultiplierChip extends StatelessWidget {
  final int days;
  final double multiplier;
  final int current;

  const _MultiplierChip({
    required this.days,
    required this.multiplier,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current >= days;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.fireOrange.withValues(alpha: 0.3) : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: AppColors.fireOrange) : null,
      ),
      child: Text(
        '$days дн → x$multiplier',
        style: TextStyle(
          color: isActive ? AppColors.fireOrange : AppColors.textSecondary,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DailyAllowanceCard extends StatelessWidget {
  final DifficultyPreset difficulty;
  final int freeAllowance;

  const _DailyAllowanceCard({
    required this.difficulty,
    required this.freeAllowance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сложность: ${difficulty.displayName}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Каждый день в 00:01 вы получаете ${_formatMinutes(freeAllowance)} бесплатно',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HowItWorksItem(
            icon: Icons.schedule,
            text: 'Каждый день в 00:01 баланс сбрасывается и даётся бесплатное время',
          ),
          const SizedBox(height: 12),
          _HowItWorksItem(
            icon: Icons.fitness_center,
            text: 'Тренировки добавляют заработанные минуты к балансу',
          ),
          const SizedBox(height: 12),
          _HowItWorksItem(
            icon: Icons.receipt_long,
            text: 'Долг погашается в первую очередь и блокирует бесплатные минуты',
          ),
          const SizedBox(height: 12),
          _HowItWorksItem(
            icon: Icons.local_fire_department,
            text: 'Стрик увеличивает награды за тренировки до x2',
          ),
        ],
      ),
    );
  }
}

class _HowItWorksItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HowItWorksItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

String _formatMinutes(int minutes) {
  if (minutes <= 0) return '0м';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours > 0 && mins > 0) {
    return '${hours}ч ${mins}м';
  }
  if (hours > 0) {
    return '${hours}ч';
  }
  return '${mins}м';
}
