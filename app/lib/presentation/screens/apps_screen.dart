import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_coach/core/theme/app_theme.dart';
import 'package:fitness_coach/domain/models/blocked_app.dart';
import 'package:fitness_coach/presentation/providers/app_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Screen for managing blocked apps
class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Refresh apps with usage stats on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadInstalledApps();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          child: Stack(
            children: [
              Column(
            children: [
              // Header - wrapped in flexible for keyboard
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Управление приложениями',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Выберите приложения для блокировки',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              // Permission warning
              if (!provider.hasAllPermissions)
                _buildPermissionWarning(context, provider),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Поиск приложений...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Блокир. (${provider.blockedApps.length})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.apps, size: 16),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Все',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBlockedAppsList(provider),
                    _buildAllAppsList(provider),
                  ],
                ),
              ),
            ],
              ),
              // FAB for manual package input
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton.extended(
                  onPressed: () => _showAddPackageDialog(context, provider),
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Добавить', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddPackageDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      useSafeArea: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Добавить приложение'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        scrollable: true,
        content: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Введите package name приложения:',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'com.google.android.youtube',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Название (опционально)',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Популярные:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    SizedBox(height: 4),
                    Text('YouTube: com.google.android.youtube', style: TextStyle(fontSize: 11)),
                    Text('TikTok: com.zhiliaoapp.musically', style: TextStyle(fontSize: 11)),
                    Text('Instagram: com.instagram.android', style: TextStyle(fontSize: 11)),
                    Text('VK: com.vkontakte.android', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final packageName = controller.text.trim();
              if (packageName.isNotEmpty) {
                final appName = nameController.text.trim().isEmpty 
                    ? packageName.split('.').last 
                    : nameController.text.trim();
                provider.addBlockedAppManually(packageName, appName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$appName добавлено в блокировку'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Добавить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionWarning(BuildContext context, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Требуются разрешения',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!provider.hasAccessibilityPermission)
                SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: provider.openAccessibilitySettings,
                    icon: const Icon(Icons.accessibility, size: 14),
                    label: const Text('Спец. возможности', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: const BorderSide(color: AppColors.warning),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              if (!provider.hasUsageStatsPermission)
                SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: provider.openUsageStatsSettings,
                    icon: const Icon(Icons.bar_chart, size: 14),
                    label: const Text('Статистика', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: const BorderSide(color: AppColors.warning),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildBlockedAppsList(AppProvider provider) {
    final apps = provider.blockedApps
        .where((app) => app.appName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (apps.isEmpty) {
      return _buildEmptyState(
        icon: Icons.lock_open_outlined,
        title: 'Нет заблокированных приложений',
        subtitle: 'Добавьте приложения из вкладки "Все приложения"',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return _AppListTile(
          app: app,
          isBlocked: true,
          onToggle: () => provider.removeBlockedApp(app.packageName),
        ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
      },
    );
  }

  Widget _buildAllAppsList(AppProvider provider) {
    final apps = provider.installedApps
        .where((app) => app.appName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (apps.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'Приложения не найдены',
        subtitle: 'Попробуйте другой поисковый запрос',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final isBlocked = provider.isAppBlocked(app.packageName);
        
        return _InstalledAppTile(
          app: app,
          isBlocked: isBlocked,
          onToggle: () {
            if (isBlocked) {
              provider.removeBlockedApp(app.packageName);
            } else {
              provider.addBlockedApp(app);
            }
          },
        ).animate().fadeIn(delay: Duration(milliseconds: (index % 10) * 30));
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            Icon(icon, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// List tile for blocked app
class _AppListTile extends StatelessWidget {
  final BlockedApp app;
  final bool isBlocked;
  final VoidCallback onToggle;

  const _AppListTile({
    required this.app,
    required this.isBlocked,
    required this.onToggle,
  });

  Widget _buildAppIcon() {
    if (app.iconBase64 != null && app.iconBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(app.iconBase64!);
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackIcon(),
            ),
          ),
        );
      } catch (_) {
        return _buildFallbackIcon();
      }
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.error,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: _buildAppIcon(),
        title: Text(
          app.appName,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          app.totalUsedMinutes > 0 
              ? 'Использовано: ${app.totalUsedMinutes} мин'
              : 'Заблокировано',
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          onPressed: onToggle,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.error,
        ),
      ),
    );
  }
}

/// List tile for installed app
class _InstalledAppTile extends StatelessWidget {
  final InstalledApp app;
  final bool isBlocked;
  final VoidCallback onToggle;

  const _InstalledAppTile({
    required this.app,
    required this.isBlocked,
    required this.onToggle,
  });

  Color _getAppColor() {
    // Generate consistent color based on app name
    final hash = app.appName.hashCode;
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.fireOrange,
      AppColors.pushUpColor,
      AppColors.squatColor,
    ];
    return colors[hash.abs() % colors.length];
  }

  Widget _buildAppIcon() {
    final appColor = _getAppColor();
    
    if (app.iconBase64 != null && app.iconBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(app.iconBase64!);
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackIcon(appColor),
            ),
          ),
        );
      } catch (_) {
        return _buildFallbackIcon(appColor);
      }
    }
    return _buildFallbackIcon(appColor);
  }
  
  Widget _buildFallbackIcon(Color appColor) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isBlocked ? AppColors.error.withValues(alpha: 0.2) : appColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
          style: TextStyle(
            color: isBlocked ? AppColors.error : appColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isBlocked ? AppColors.error.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isBlocked
            ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _buildAppIcon(),
        title: Text(
          app.appName,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          app.formattedUsage,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: app.todayUsageMinutes > 0 ? AppColors.warning : AppColors.textHint,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Switch(
          value: isBlocked,
          onChanged: (_) => onToggle(),
          activeColor: AppColors.error,
        ),
      ),
    );
  }
}
