import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:fitness_coach/core/theme/app_theme.dart';
import 'package:fitness_coach/domain/models/exercise.dart';
import 'package:fitness_coach/domain/services/pose_detection_service.dart';
import 'package:fitness_coach/presentation/providers/app_provider.dart';
import 'package:fitness_coach/presentation/providers/exercise_provider.dart';
import 'package:fitness_coach/presentation/widgets/skeleton_painter.dart';
import 'package:fitness_coach/presentation/widgets/exercise_counter.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Exercise tracking screen with camera and pose detection
class ExerciseScreen extends StatefulWidget {
  final ExerciseType exerciseType;

  const ExerciseScreen({
    super.key,
    required this.exerciseType,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isFrontCamera = true;
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;
  late ExerciseProvider _exerciseProvider;
  final PoseDetectionService _poseService = PoseDetectionService();
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poseService.initialize();
    _listenToPoseUpdates();
    _initializeCamera();
    // Keep screen on during exercise
    WakelockPlus.enable();
  }

  void _listenToPoseUpdates() {
    _poseService.poseStream.listen((pose) {
      if (mounted && _exerciseProvider.isTracking) {
        _exerciseProvider.processPose(pose);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appProvider = context.read<AppProvider>();
    _exerciseProvider = ExerciseProvider(appProvider);
    _exerciseProvider.selectExercise(widget.exerciseType);
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Камера не найдена';
          _isInitializing = false;
        });
        return;
      }

      // Prefer front camera for exercises
      _currentCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (_currentCameraIndex < 0) _currentCameraIndex = 0;
      _isFrontCamera = _cameras[_currentCameraIndex].lensDirection == CameraLensDirection.front;

      await _setupCamera(_cameras[_currentCameraIndex]);

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });

        // Start exercise tracking
        await _exerciseProvider.startTracking();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Ошибка камеры: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    // Stop image stream if running
    if (_cameraController != null) {
      try {
        await _cameraController!.stopImageStream();
      } catch (_) {}
      await _cameraController!.dispose();
    }
    
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid 
          ? ImageFormatGroup.nv21 
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    
    // Start image stream for pose detection
    await _startImageStream();
  }

  Future<void> _startImageStream() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    final camera = _cameras[_currentCameraIndex];
    final rotation = _getRotation(camera);
    
    await _cameraController!.startImageStream((image) {
      if (!_isDetecting && _exerciseProvider.isTracking) {
        _isDetecting = true;
        _poseService.processImage(image, rotation, _isFrontCamera).then((_) {
          _isDetecting = false;
        });
      }
    });
  }

  int _getRotation(CameraDescription camera) {
    // Convert sensor orientation to ML Kit rotation
    final orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };
    
    var rotation = orientations[DeviceOrientation.portraitUp]!;
    if (Platform.isAndroid) {
      rotation = camera.sensorOrientation;
    }
    return rotation;
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    
    setState(() => _isInitializing = true);
    
    // Find next camera with different lens direction
    final currentDirection = _cameras[_currentCameraIndex].lensDirection;
    int newIndex = -1;
    
    for (int i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection != currentDirection) {
        newIndex = i;
        break;
      }
    }
    
    if (newIndex < 0) {
      setState(() => _isInitializing = false);
      return;
    }
    
    _currentCameraIndex = newIndex;
    _isFrontCamera = _cameras[_currentCameraIndex].lensDirection == CameraLensDirection.front;
    
    try {
      await _setupCamera(_cameras[_currentCameraIndex]);
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Ошибка переключения камеры: $e';
        _isInitializing = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _exerciseProvider.pauseTracking();
    } else if (state == AppLifecycleState.resumed) {
      _exerciseProvider.resumeTracking();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Disable wakelock when leaving
    WakelockPlus.disable();
    try {
      _cameraController?.stopImageStream();
    } catch (_) {}
    _cameraController?.dispose();
    _poseService.dispose();
    _exerciseProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _exerciseProvider,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _showExitDialog(_exerciseProvider);
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    return _buildCameraView();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Подготовка камеры...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage ?? 'Ошибка камеры',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Назад'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview with correct aspect ratio
            // Note: Front camera preview is NOT pre-mirrored by the plugin,
            // so we don't apply mirroring here - let skeleton handle it
            if (_cameraController != null && _cameraController!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: 1 / _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                ),
              ),

            // Skeleton overlay - centered and sized to match camera preview exactly
            if (_cameraController != null && _cameraController!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: 1 / _cameraController!.value.aspectRatio,
                  child: SkeletonOverlay(
                    poseResult: provider.lastPose,
                    mirrorMode: _isFrontCamera, // Mirror skeleton for front camera
                  ),
                ),
              ),

            // Dark overlay for better visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Back button
                      _buildCircleButton(
                        icon: Icons.close,
                        onTap: () => _showExitDialog(provider),
                      ),
                      const Spacer(),
                      // Switch camera
                      _buildCircleButton(
                        icon: Icons.cameraswitch_outlined,
                        onTap: _switchCamera,
                      ),
                      const SizedBox(width: 12),
                      // Pause/Resume
                      _buildCircleButton(
                        icon: provider.isPaused 
                            ? Icons.play_arrow 
                            : Icons.pause,
                        onTap: () {
                          if (provider.isPaused) {
                            provider.resumeTracking();
                          } else {
                            provider.pauseTracking();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom panel with counter
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Feedback message
                      ExerciseFeedback(
                        message: provider.trackingState.formFeedback,
                        isValid: provider.trackingState.isValidForm,
                      ).animate().fadeIn(),
                      const SizedBox(height: 16),

                      // Counter with goal
                      Consumer<AppProvider>(
                        builder: (context, appProvider, _) {
                          final settings = appProvider.settings;
                          int? goal;
                          // Set goal based on exercise type
                          switch (widget.exerciseType) {
                            case ExerciseType.pushUp:
                            case ExerciseType.jumpingJack:
                            case ExerciseType.highKnees:
                              goal = settings.pushUpRequirement;
                              break;
                            case ExerciseType.squat:
                            case ExerciseType.lunge:
                              goal = settings.squatRequirement;
                              break;
                            case ExerciseType.plank:
                              goal = null; // Time-based, no goal format
                              break;
                            case ExerciseType.freeActivity:
                              goal = null; // Free activity is time-based, no numeric goal
                              break;
                          }
                          return ExerciseCounter(
                            count: provider.currentCount,
                            exerciseType: widget.exerciseType,
                            earnedMinutes: provider.potentialReward,
                            goal: goal,
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Finish button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: provider.currentCount > 0 
                              ? () => _finishExercise(provider) 
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Завершить тренировку'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Pause overlay - on top of everything
            if (provider.isPaused)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.85),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.pause_circle_filled,
                          size: 100,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Пауза',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton.icon(
                          onPressed: provider.resumeTracking,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                          ),
                          icon: const Icon(Icons.play_arrow, size: 28),
                          label: const Text('Продолжить', style: TextStyle(fontSize: 18)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _showExitDialog(ExerciseProvider provider) {
    if (provider.currentCount == 0) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Завершить тренировку?'),
        content: Text(
          'Вы выполнили ${provider.currentCount} ${widget.exerciseType.displayName.toLowerCase()}.\n'
          'Заработано: +${provider.potentialReward} минут',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Продолжить'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _finishExercise(provider);
            },
            child: const Text('Завершить'),
          ),
          TextButton(
            onPressed: () async {
              // Save progress for later continuation
              await provider.saveProgress();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(this.context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('Сохранить и выйти'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishExercise(ExerciseProvider provider) async {
    final session = await provider.stopTracking(save: true);
    
    if (session != null && mounted) {
      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SuccessDialog(session: session),
      );
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}

/// Success dialog after completing exercise
class _SuccessDialog extends StatelessWidget {
  final ExerciseSession session;

  const _SuccessDialog({required this.session});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 48,
              ),
            ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),

            Text(
              'Отлично!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              _getCompletionText(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Earned time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.2),
                    AppColors.success.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer,
                    color: AppColors.success,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '+${session.earnedMinutes} мин',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Готово'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCompletionText() {
    if (session.type == ExerciseType.plank) {
      final mins = session.count ~/ 60;
      final secs = session.count % 60;
      if (mins > 0) {
        return 'Вы продержали планку $mins мин $secs сек';
      }
      return 'Вы продержали планку $secs секунд';
    }
    return 'Вы выполнили ${session.count} ${session.type.displayName.toLowerCase()}';
  }
}
