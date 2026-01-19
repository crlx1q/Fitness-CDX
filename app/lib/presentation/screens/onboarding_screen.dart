import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_coach/core/theme/app_theme.dart';
import 'package:fitness_coach/presentation/providers/app_provider.dart';
import 'package:fitness_coach/presentation/screens/home_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Onboarding and permissions screen
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: '💪',
      title: 'Тренируйся — получай время',
      description: 'Выполняй упражнения и зарабатывай минуты доступа к приложениям.',
      color: AppColors.primary,
    ),
    _OnboardingPageData(
      icon: '📱',
      title: 'Блокируй отвлечения',
      description: 'Выбери приложения для блокировки: TikTok, YouTube, игры.',
      color: AppColors.error,
    ),
    _OnboardingPageData(
      icon: '🔥',
      title: 'Получай бонусы за серии',
      description: 'Тренируйся каждый день и получай до x2 к наградам!',
      color: AppColors.fireOrange,
    ),
    _OnboardingPageData(
      icon: '🔒',
      title: 'Приватность защищена',
      description: 'Видео не записывается.\nДанные только на устройстве.',
      color: AppColors.success,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Пропустить'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, _buildDot),
            ),
            const SizedBox(height: 24),
            if (_currentPage == _pages.length - 1)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: _PermissionsPanel(onContinue: _finish),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _buildNextButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPageData p) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: p.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(p.icon, style: const TextStyle(fontSize: 56))),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 40),
          Text(p.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(p.description, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDot(int i) {
    final sel = i == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: sel ? 24 : 8, height: 8,
      decoration: BoxDecoration(
        color: sel ? AppColors.primary : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
        child: const Text('Далее'),
      ),
    );
  }

  void _finish() {
    context.read<AppProvider>().completeOnboarding();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }
}

class _OnboardingPageData {
  final String icon, title, description;
  final Color color;
  const _OnboardingPageData({required this.icon, required this.title, required this.description, required this.color});
}

class _PermissionsPanel extends StatefulWidget {
  final VoidCallback onContinue;
  const _PermissionsPanel({required this.onContinue});

  @override
  State<_PermissionsPanel> createState() => _PermissionsPanelState();
}

class _PermissionsPanelState extends State<_PermissionsPanel> with WidgetsBindingObserver {
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
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PermissionRow(
                icon: Icons.camera_alt,
                title: 'Камера',
                subtitle: 'Для распознавания упражнений',
                isGranted: true,
              ),
              const SizedBox(height: 8),
              _PermissionRow(
                icon: Icons.accessibility,
                title: 'Спец. возможности',
                subtitle: 'Для блокировки приложений',
                isGranted: provider.hasAccessibilityPermission,
                onTap: () async {
                  await provider.openAccessibilitySettings();
                },
              ),
              const SizedBox(height: 8),
              _PermissionRow(
                icon: Icons.bar_chart,
                title: 'Статистика',
                subtitle: 'Для отслеживания времени',
                isGranted: provider.hasUsageStatsPermission,
                onTap: () async {
                  await provider.openUsageStatsSettings();
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onContinue,
                  child: const Text('Начать'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool isGranted;
  final VoidCallback? onTap;

  const _PermissionRow({required this.icon, required this.title, required this.subtitle, required this.isGranted, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isGranted ? AppColors.success.withValues(alpha: 0.5) : AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: isGranted ? AppColors.success : AppColors.textSecondary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
              ],
            ),
          ),
          if (isGranted)
            const Icon(Icons.check_circle, color: AppColors.success, size: 22)
          else if (onTap != null)
            SizedBox(
              height: 32,
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: const Text('Открыть', style: TextStyle(fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }
}
