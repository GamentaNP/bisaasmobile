import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/storage/preferences.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Selection state is a stable slug, never display copy. The canonical
  // English storage key is attached only when saving (see _storedExamValue),
  // so an existing stored choice keeps resolving in any display language.
  String _selectedExam = 'loksewa';
  int _dailyMinutes = 30;
  // Must be one of _levels' ids — a default that matches no option leaves
  // page 3 rendering nothing as selected and persists a value the profile
  // screens do not recognise.
  String _experienceLevel = 'student';

  /// The storage contract: a canonical, language-neutral English key for each
  /// option. The app used to persist its English display copy; keeping these
  /// keys as the stored values means an existing selection still resolves and
  /// changing the reader's language cannot change what was saved.
  static const _legacyExamIds = <String, String>{
    'Loksewa / Civil PSC': 'loksewa',
    'GATE / Indian PSC': 'gate',
    'SSC JE / Diploma': 'ssc',
    'University Semester Exams': 'university',
  };
  static const _legacyLevelIds = <String, String>{
    'Engineering Student': 'student',
    'Graduate / Job Seeker': 'graduate',
    'Practicing Engineer': 'engineer',
  };

  /// Accept both a legacy English key and a slug, so a stored choice from
  /// an older build still resolves to the same option.
  static String _readExamId(String? stored) =>
      _legacyExamIds[stored] ?? stored ?? 'loksewa';
  static String _readLevelId(String? stored) =>
      _legacyLevelIds[stored] ?? stored ?? 'student';

  static String _storedExamValue(String id) => _legacyExamIds.entries
      .firstWhere((e) => e.value == id, orElse: () => MapEntry('loksewa', 'loksewa'))
      .key;
  static String _storedLevelValue(String id) => _legacyLevelIds.entries
      .firstWhere((e) => e.value == id,
          orElse: () => MapEntry('Engineering Student', 'student'))
      .key;

  final _exams = const [
    {'id': 'loksewa', 'icon': Icons.account_balance_rounded},
    {'id': 'gate', 'icon': Icons.school_rounded},
    {'id': 'ssc', 'icon': Icons.engineering_rounded},
    {'id': 'university', 'icon': Icons.menu_book_rounded},
  ];

  final _goals = const [
    {'minutes': 15, 'id': 'casual', 'icon': Icons.timer_outlined},
    {'minutes': 30, 'id': 'focused', 'icon': Icons.timer_rounded},
    {'minutes': 60, 'id': 'intensive', 'icon': Icons.bolt_rounded},
  ];

  final _levels = const [
    {'id': 'student', 'icon': Icons.person_outline},
    {'id': 'graduate', 'icon': Icons.workspace_premium_outlined},
    {'id': 'engineer', 'icon': Icons.architecture_rounded},
  ];

  /// The visible title and description of an exam option, in the reader's
  /// language. The id is what gets persisted; the copy never is.
  ({String title, String desc}) _examCopy(String id, AppLocalizations l10n) =>
      switch (id) {
        'gate' => (title: l10n.onbExamGate, desc: l10n.onbExamGateDesc),
        'ssc' => (title: l10n.onbExamSsc, desc: l10n.onbExamSscDesc),
        'university' =>
          (title: l10n.onbExamUniversity, desc: l10n.onbExamUniversityDesc),
        _ => (title: l10n.onbExamLoksewa, desc: l10n.onbExamLoksewaDesc),
      };

  ({String label, String desc}) _goalCopy(String id, AppLocalizations l10n) =>
      switch (id) {
        'focused' => (label: l10n.onbGoalFocused, desc: l10n.onbGoalFocusedDesc),
        'intensive' =>
          (label: l10n.onbGoalIntensive, desc: l10n.onbGoalIntensiveDesc),
        _ => (label: l10n.onbGoalCasual, desc: l10n.onbGoalCasualDesc),
      };

  ({String title, String desc}) _levelCopy(String id, AppLocalizations l10n) =>
      switch (id) {
        'graduate' =>
          (title: l10n.onbLevelGraduate, desc: l10n.onbLevelGraduateDesc),
        'engineer' =>
          (title: l10n.onbLevelEngineer, desc: l10n.onbLevelEngineerDesc),
        _ => (title: l10n.onbLevelStudent, desc: l10n.onbLevelStudentDesc),
      };

  Future<void> _completeOnboarding() async {
    final prefs = Preferences.instance;
    await prefs.setSelectedExam(_storedExamValue(_selectedExam));
    await prefs.setDailyGoalMinutes(_dailyMinutes);
    await prefs.setExperienceLevel(_storedLevelValue(_experienceLevel));
    await prefs.setOnboardingDone(true);

    if (!mounted) return;
    context.go('/home');
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: Theme.of(context).brightness == Brightness.dark ? AppColors.auroraBackground : null, color: Theme.of(context).scaffoldBackgroundColor),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.onboardingStepOf(_currentPage + 1, 3),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(l10n.commonSkip),
                    ),
                  ],
                ),
              ),

              // Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: AppRadii.pillAll,
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / 3,
                    backgroundColor: isDark
                        ? AppColors.surfaceRaisedDark
                        : theme.colorScheme.surfaceContainerHighest,
                    color: AppColors.brand,
                    minHeight: 6,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // PageView
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildExamStep(theme),
                    _buildGoalStep(theme),
                    _buildLevelStep(theme),
                  ],
                ),
              ),

              // Bottom Navigation CTA
              Padding(
                padding: const EdgeInsets.all(24),
                child: GradientButton(
                  label: _currentPage == 2 ? l10n.onboardingStartLearning : l10n.onboardingContinue,
                  onPressed: _nextPage,
                  icon: _currentPage == 2
                      ? Icons.rocket_launch_rounded
                      : Icons.arrow_forward_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamStep(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(
          l10n.onboardingTargetExamTitle,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingTargetExamBody,
          style: AppTypography.bodyMedium.copyWith(
            color: theme.brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 20),
        ..._exams.map((exam) {
          final id = exam['id']! as String;
          final copy = _examCopy(id, l10n);
          final isSelected = _readExamId(_selectedExam) == id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassmorphicCard(
              glow: isSelected,
              onTap: () => setState(() => _selectedExam = id),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? AppColors.brandGradient
                          : null,
                      color: isSelected
                          ? null
                          : theme.brightness == Brightness.dark
                              ? AppColors.surfaceRaisedDark
                              : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: AppRadii.smAll,
                    ),
                    child: Icon(
                      exam['icon']! as IconData,
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          copy.desc,
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.brightness == Brightness.dark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppColors.brand),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGoalStep(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(
          l10n.onboardingDailyGoalTitle,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingDailyGoalBody,
          style: AppTypography.bodyMedium.copyWith(
            color: theme.brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 20),
        ..._goals.map((goal) {
          final copy = _goalCopy(goal['id']! as String, l10n);
          final isSelected = _dailyMinutes == goal['minutes'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassmorphicCard(
              glow: isSelected,
              onTap: () => setState(() => _dailyMinutes = goal['minutes']! as int),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.brandGradient : null,
                      color: isSelected
                          ? null
                          : theme.brightness == Brightness.dark
                              ? AppColors.surfaceRaisedDark
                              : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: AppRadii.smAll,
                    ),
                    child: Icon(
                      goal['icon']! as IconData,
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.onboardingMinutesPerDay(goal['minutes']! as int, copy.label),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          copy.desc,
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.brightness == Brightness.dark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppColors.brand),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLevelStep(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(
          l10n.onboardingCurrentLevelTitle,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          // Was: "Help our IRT calibration engine tailor initial question
          // difficulty to your stage." Nothing reads this answer back —
          // PATCH /me accepts only `name` (username/email have authoritative
          // flows of their own), so there is nowhere on
          // the server to persist it and nothing consumes it locally either.
          l10n.onboardingCurrentLevelBody,
          style: AppTypography.bodyMedium.copyWith(
            color: theme.brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 20),
        ..._levels.map((level) {
          final id = level['id']! as String;
          final copy = _levelCopy(id, l10n);
          final isSelected = _readLevelId(_experienceLevel) == id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassmorphicCard(
              glow: isSelected,
              onTap: () => setState(() => _experienceLevel = id),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.brandGradient : null,
                      color: isSelected
                          ? null
                          : theme.brightness == Brightness.dark
                              ? AppColors.surfaceRaisedDark
                              : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: AppRadii.smAll,
                    ),
                    child: Icon(
                      level['icon']! as IconData,
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          copy.desc,
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.brightness == Brightness.dark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppColors.brand),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
