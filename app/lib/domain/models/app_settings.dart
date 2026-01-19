import 'package:hive/hive.dart';
import 'package:fitness_coach/core/constants/app_constants.dart';

part 'app_settings.g.dart';

/// Application settings stored locally
@HiveType(typeId: 5)
class AppSettings extends HiveObject {
  @HiveField(0)
  int difficultyIndex; // 0=easy, 1=normal, 2=hard

  @HiveField(1)
  int pushUpRewardMinutes; // Minutes earned per pushUpRequirement

  @HiveField(2)
  int squatRewardMinutes; // Minutes earned per squatRequirement

  @HiveField(3)
  int plankRewardMinutes; // Minutes earned per minute of plank

  @HiveField(4)
  int pushUpRequirement; // How many push-ups for reward

  @HiveField(5)
  int squatRequirement; // How many squats for reward

  @HiveField(6)
  int plankSecondRequirement; // How many seconds of plank for reward

  @HiveField(7)
  bool strikeModeEnabled; // Streak multiplier mode

  @HiveField(8)
  bool notificationsEnabled;

  @HiveField(9)
  bool hasCompletedOnboarding;

  @HiveField(10)
  bool hasGrantedPermissions;

  @HiveField(11)
  bool soundEnabled; // Sound feedback on exercise completion

  AppSettings({
    this.difficultyIndex = 1,
    this.pushUpRewardMinutes = AppConstants.defaultPushUpReward,
    this.squatRewardMinutes = AppConstants.defaultSquatReward,
    this.plankRewardMinutes = AppConstants.defaultPlankReward,
    this.pushUpRequirement = AppConstants.pushUpsForReward,
    this.squatRequirement = AppConstants.squatsForReward,
    this.plankSecondRequirement = AppConstants.plankSecondsForReward,
    this.strikeModeEnabled = true,
    this.notificationsEnabled = true,
    this.hasCompletedOnboarding = false,
    this.hasGrantedPermissions = false,
    this.soundEnabled = true,
  });

  DifficultyPreset get difficulty => DifficultyPreset.values[difficultyIndex];

  set difficulty(DifficultyPreset preset) {
    difficultyIndex = preset.index;
    _applyDifficultyPreset(preset);
  }

  void _applyDifficultyPreset(DifficultyPreset preset) {
    final rewardMult = preset.rewardMultiplier;
    final reqMult = preset.requirementMultiplier;
    
    // Rewards scale with difficulty
    pushUpRewardMinutes = (AppConstants.defaultPushUpReward * rewardMult).round();
    squatRewardMinutes = (AppConstants.defaultSquatReward * rewardMult).round();
    plankRewardMinutes = (AppConstants.defaultPlankReward * rewardMult).round();
    
    // Requirements scale inversely (easy = fewer reps needed)
    pushUpRequirement = (AppConstants.pushUpsForReward * reqMult).round();
    squatRequirement = (AppConstants.squatsForReward * reqMult).round();
    plankSecondRequirement = (AppConstants.plankSecondsForReward * reqMult).round();
  }

  /// Calculate reward for push-ups
  int calculatePushUpReward(int count, double streakMultiplier) {
    final sets = count ~/ pushUpRequirement;
    return (sets * pushUpRewardMinutes * streakMultiplier).round();
  }

  /// Calculate reward for squats
  int calculateSquatReward(int count, double streakMultiplier) {
    final sets = count ~/ squatRequirement;
    return (sets * squatRewardMinutes * streakMultiplier).round();
  }

  /// Calculate reward for plank
  int calculatePlankReward(int seconds, double streakMultiplier) {
    final sets = seconds ~/ plankSecondRequirement;
    return (sets * plankRewardMinutes * streakMultiplier).round();
  }

  AppSettings copyWith({
    int? difficultyIndex,
    int? pushUpRewardMinutes,
    int? squatRewardMinutes,
    int? plankRewardMinutes,
    int? pushUpRequirement,
    int? squatRequirement,
    int? plankSecondRequirement,
    bool? strikeModeEnabled,
    bool? notificationsEnabled,
    bool? hasCompletedOnboarding,
    bool? hasGrantedPermissions,
    bool? soundEnabled,
  }) {
    return AppSettings(
      difficultyIndex: difficultyIndex ?? this.difficultyIndex,
      pushUpRewardMinutes: pushUpRewardMinutes ?? this.pushUpRewardMinutes,
      squatRewardMinutes: squatRewardMinutes ?? this.squatRewardMinutes,
      plankRewardMinutes: plankRewardMinutes ?? this.plankRewardMinutes,
      pushUpRequirement: pushUpRequirement ?? this.pushUpRequirement,
      squatRequirement: squatRequirement ?? this.squatRequirement,
      plankSecondRequirement: plankSecondRequirement ?? this.plankSecondRequirement,
      strikeModeEnabled: strikeModeEnabled ?? this.strikeModeEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasGrantedPermissions: hasGrantedPermissions ?? this.hasGrantedPermissions,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}
