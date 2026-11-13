import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_coach/core/theme/app_theme.dart';
import 'package:fitness_coach/core/constants/app_constants.dart';
import 'package:fitness_coach/presentation/providers/app_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Settings screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh permissions when returning from settings
      context.read<AppProvider>().refreshPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final settings = provider.settings;

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
                        'Настройки',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Настройте приложение под себя',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              // Difficulty section
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'Сложность'),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: DifficultyPreset.values.map((preset) {
                        final isSelected = settings.difficulty == preset;
                        return _DifficultyOption(
                          preset: preset,
                          isSelected: isSelected,
                          onTap: () => provider.setDifficulty(preset),
                        );
                      }).toList(),
                    ),
                  ).animate().fadeIn(),
                ),
              ),

              // Rewards preview
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _RewardsPreview(settings: settings),
                ),
              ),

              // Sound & Strike mode section
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'Тренировки'),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Row(
                            children: [
                              const Text('🔊', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Text(
                                'Звук при повторении',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Звуковой сигнал при каждом выполненном повторении',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          value: settings.soundEnabled,
                          onChanged: (value) => provider.setSoundEnabled(value),
                        ),
                        const Divider(color: AppColors.surfaceLight, height: 1),
                        SwitchListTile(
                          title: Row(
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Text(
                                'Ударный режим',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Получайте бонус к наградам за ежедневные тренировки без пропусков',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          value: settings.strikeModeEnabled,
                          onChanged: (value) => provider.setStrikeModeEnabled(value),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                ),
              ),

              // Streak multipliers info
              if (settings.strikeModeEnabled)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _StreakMultipliersInfo(),
                  ),
                ),

              // Notifications section
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'Уведомления'),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SwitchListTile(
                      title: Row(
                        children: [
                          const Text('🔔', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Text(
                            'Пуш-уведомления',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Утренние напоминания, предупреждения о низком балансе',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      value: settings.notificationsEnabled,
                      onChanged: (value) => provider.setNotificationsEnabled(value),
                    ),
                  ).animate().fadeIn(),
                ),
              ),

              // Permissions section
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'Разрешения'),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _PermissionTile(
                          icon: Icons.accessibility,
                          title: 'Специальные возможности',
                          subtitle: 'Для блокировки приложений',
                          isGranted: provider.hasAccessibilityPermission,
                          onTap: provider.openAccessibilitySettings,
                        ),
                        const Divider(color: AppColors.surfaceLight, height: 1),
                        _PermissionTile(
                          icon: Icons.bar_chart,
                          title: 'Статистика использования',
                          subtitle: 'Для отслеживания времени в приложениях',
                          isGranted: provider.hasUsageStatsPermission,
                          onTap: provider.openUsageStatsSettings,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                ),
              ),

              SliverToBoxAdapter(
                child: _SectionHeader(title: 'Защита от удаления'),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Row(
                            children: [
                              const Text('🔒', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Защита от удаления',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              provider.isDeviceAdminEnabled
                                  ? 'Приложение защищено от удаления'
                                  : 'Включите для предотвращения удаления',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          value: provider.isDeviceAdminEnabled,
                          onChanged: (value) {
                            if (value) {
                              provider.enableDeviceAdmin();
                            } else {
                              _showDisableProtectionDialog(context, provider);
                            }
                          },
                        ),
                        if (provider.isDeviceAdminEnabled) ...[
                          const Divider(color: AppColors.surfaceLight, height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.shield,
                                    color: AppColors.success,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Для удаления приложения потребуется кодовое слово',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(),
                ),
              ),

              SliverToBoxAdapter(
                child: _SectionHeader(title: 'Администрирование'),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined),
                      title: const Text('Остановить блокировку'),
                      onTap: () => _showAdminUnlockDialog(context, provider),
                    ),
                  ).animate().fadeIn(),
                ),
              ),

              // Privacy section
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'Приватность'),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Ваши данные защищены',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _PrivacyItem(
                          icon: Icons.videocam_off,
                          text: 'Видео не записывается',
                        ),
                        _PrivacyItem(
                          icon: Icons.cloud_off,
                          text: 'Данные только на устройстве',
                        ),
                        _PrivacyItem(
                          icon: Icons.person_off,
                          text: 'Без регистрации',
                        ),
                        _PrivacyItem(
                          icon: Icons.visibility_off,
                          text: 'Лицо не отслеживается',
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                ),
              ),

              // About section
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'О приложении'),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('Версия'),
                          trailing: Text(
                            AppConstants.appVersion,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const Divider(color: AppColors.surfaceLight, height: 1),
                        ListTile(
                          leading: const Icon(Icons.delete_outline, color: AppColors.error),
                          title: Text(
                            'Сбросить все данные',
                            style: TextStyle(color: AppColors.error),
                          ),
                          onTap: () => _showResetDialog(context, provider),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  void _showResetDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Сбросить данные?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Это действие удалит всю историю тренировок, статистику и настройки. '
                  'Это действие нельзя отменить.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () async {
                  final value = controller.text.trim();
                  if (value != 'Апельсин') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Неверное ключевое слово')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  await provider.resetAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Данные сброшены')),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Сбросить'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAdminUnlockDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Подтверждение'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () async {
                  final value = controller.text.trim();
                  if (value != 'Апельсин') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Неверное ключевое слово')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  await provider.stopBlockingService();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Блокировка остановлена')),
                    );
                  }
                },
                child: const Text('Подтвердить'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDisableProtectionDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Отключение защиты'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Введите кодовое слово для отключения защиты от удаления:',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Кодовое слово',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () async {
                  final value = controller.text.trim();
                  final success = await provider.disableDeviceAdmin(value);
                  if (!success) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Неверное кодовое слово')),
                      );
                    }
                    return;
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Защита от удаления отключена')),
                    );
                  }
                },
                child: const Text('Отключить'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DifficultyOption extends StatelessWidget {
  final DifficultyPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyOption({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
          border: Border(
            bottom: BorderSide(
              color: AppColors.surfaceLight,
              width: preset == DifficultyPreset.hard ? 0 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preset.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPresetColor(preset).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'x${preset.rewardMultiplier}',
                style: TextStyle(
                  color: _getPresetColor(preset),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPresetColor(DifficultyPreset preset) {
    switch (preset) {
      case DifficultyPreset.easy:
        return AppColors.success;
      case DifficultyPreset.normal:
        return AppColors.primary;
      case DifficultyPreset.hard:
        return AppColors.error;
    }
  }
}

class _RewardsPreview extends StatelessWidget {
  final settings;

  const _RewardsPreview({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Награды при текущих настройках:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _RewardChip(
                icon: '💪',
                text: '${settings.pushUpRequirement} отж = ${settings.pushUpRewardMinutes}м',
              ),
              _RewardChip(
                icon: '🦵',
                text: '${settings.squatRequirement} прис = ${settings.squatRewardMinutes}м',
              ),
              _RewardChip(
                icon: '🧘',
                text: '${settings.plankSecondRequirement}с план = ${settings.plankRewardMinutes}м',
              ),
              _RewardChip(
                icon: '🏃',
                text: '${settings.squatRequirement} выпад = ${settings.squatRewardMinutes}м',
              ),
              _RewardChip(
                icon: '⭐',
                text: '${settings.pushUpRequirement} джамп = ${settings.pushUpRewardMinutes}м',
              ),
              _RewardChip(
                icon: '🦶',
                text: '${settings.pushUpRequirement * 4} колен = ${settings.pushUpRewardMinutes}м',
              ),
              _RewardChip(
                icon: '🔥',
                text: '60с актив = 1м',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String icon;
  final String text;

  const _RewardChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakMultipliersInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.fireOrange.withValues(alpha: 0.15),
            AppColors.fireRed.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fireOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Множители за стрик:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.fireOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MultiplierBadge(days: 3, multiplier: 1.2),
              _MultiplierBadge(days: 7, multiplier: 1.5),
              _MultiplierBadge(days: 14, multiplier: 1.75),
              _MultiplierBadge(days: 30, multiplier: 2.0),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _MultiplierBadge extends StatelessWidget {
  final int days;
  final double multiplier;

  const _MultiplierBadge({required this.days, required this.multiplier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$days дн. → x$multiplier',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isGranted;
  final VoidCallback onTap;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isGranted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isGranted ? AppColors.success : AppColors.textSecondary,
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: isGranted
          ? const Icon(Icons.check_circle, color: AppColors.success)
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Открыть'),
            ),
      onTap: isGranted ? null : onTap,
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PrivacyItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
