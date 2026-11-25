library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/consent/consent_gate.dart';
import '../../../../core/storage/preferences.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../data/providers/onboarding_options_providers.dart';
import '../../domain/entities/onboarding_options.dart';

/// Three-step wizard whose options come exclusively from
/// `GET /quiz/onboarding/options`. Nothing on this screen is invented locally:
/// the domain ids, goal minutes and education-level ids displayed here are the
/// ones persisted, and the only local copy is the translation of the goal
/// presets' stable `value` keys.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Server ids, never display copy. Initialised from the server catalogue on
  // the first frame that has data (and resolved against any stored choice).
  int? _selectedDomainId;
  int _dailyMinutes = 0;
  int? _selectedLevelId;
  bool _initialized = false;

  // Legacy *stored* values from the invented-option builds. Kept only to
  // resolve existing selections; nothing new is ever written in this shape.
  static const _legacyExamValues = <String, String>{
    'Loksewa / Civil PSC': 'loksewa',
    'GATE / Indian PSC': 'gate',
    'SSC JE / Diploma': 'ssc',
    'University Semester Exams': 'university',
  };
  static const _legacyLevelValues = <String, String>{
    'Engineering Student': 'student',
    'Graduate / Job Seeker': 'graduate',
    'Practicing Engineer': 'engineer',
  };

  void _initialize(OnboardingOptions options) {
    if (_initialized) return;
    _initialized = true;
    final prefs = Preferences.instance;
    _selectedDomainId = _resolveDomainId(options.domains, prefs.selectedExam);
    _dailyMinutes =
        _resolveMinutes(options.goalIntensities, prefs.dailyGoalMinutes);
    _selectedLevelId =
        _resolveLevelId(options.educationLevels, prefs.experienceLevel);
  }

  /// A stored server id wins; a legacy slug/copy is looked up by slug/name;
  /// anything unresolvable falls back to the server's first domain.
  static int _resolveDomainId(List<DomainOption> domains, String? stored) {
    final storedId = int.tryParse(stored ?? '');
    if (storedId != null && domains.any((d) => d.id == storedId)) return storedId;
    final legacy = _legacyExamValues[stored] ?? stored;
    for (final domain in domains) {
      if (domain.slug == legacy || domain.name == stored) return domain.id;
    }
    return domains.first.id;
  }

  static int _resolveLevelId(
    List<EducationLevelOption> levels,
    String? stored,
  ) {
    final storedId = int.tryParse(stored ?? '');
    if (storedId != null && levels.any((l) => l.id == storedId)) return storedId;
    final legacy = _legacyLevelValues[stored] ?? stored;
    for (final level in levels) {
      if (level.name == legacy || level.name == stored) return level.id;
    }
    return levels.first.id;
  }

  /// Keep a stored minute value only when a server intensity still publishes
  /// it; otherwise start at the first server preset.
  static int _resolveMinutes(List<GoalIntensityOption> goals, int stored) {
    if (goals.any((g) => g.defaultMinutes == stored)) return stored;
    return goals.first.defaultMinutes;
  }

  /// The server sends an English `label`; the reader gets a localized one.
  /// The `value` is the stable key, not display copy.
  static String _goalLabel(String value, AppLocalizations l10n) => switch (value) {
        'serious' => l10n.onbGoalSerious,
        'beast' => l10n.onbGoalBeast,
        _ => l10n.onbGoalCasual,
      };

  Future<void> _completeOnboarding() async {
    final domainId = _selectedDomainId;
    final levelId = _selectedLevelId;
    if (domainId == null || levelId == null) return;

    final prefs = Preferences.instance;
    await prefs.setSelectedExam(domainId.toString());
    await prefs.setDailyGoalMinutes(_dailyMinutes);
    await prefs.setExperienceLevel(levelId.toString());
    await prefs.setOnboardingDone(true);

    // The completion transition, not the first-frame app_open. Through the
    // consent gate so a user who declined analytics is not counted.
    unawaited(ref.read(analyticsProvider).log(AnalyticsEvents.onboardingComplete));

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
    final optionsAsync = ref.watch(onboardingOptionsProvider);
    final options = optionsAsync.value;
    if (options != null) _initialize(options);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.auroraBackground : null,
          color: theme.scaffoldBackgroundColor,
        ),
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
                      onPressed: options == null ? null : _completeOnboarding,
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

              // Server-backed steps. Loading and failure never render an
              // invented option list.
              Expanded(
                child: optionsAsync.when(
                  data: (loaded) => PageView(
                    controller: _pageController,
                    onPageChanged: (page) => setState(() => _currentPage = page),
                    children: [
                      _buildDomainStep(theme, loaded),
                      _buildGoalStep(theme, loaded),
                      _buildLevelStep(theme, loaded),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ErrorView(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(onboardingOptionsProvider),
                  ),
                ),
              ),

              // Bottom Navigation CTA
              Padding(
                padding: const EdgeInsets.all(24),
                child: GradientButton(
                  label: _currentPage == 2
                      ? l10n.onboardingStartLearning
                      : l10n.onboardingContinue,
                  onPressed: options == null ? null : _nextPage,
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

  Widget _buildDomainStep(ThemeData theme, OnboardingOptions options) {
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
        ...options.domains.map((domain) {
          final isSelected = _selectedDomainId == domain.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassmorphicCard(
              glow: isSelected,
              onTap: () => setState(() => _selectedDomainId = domain.id),
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
                      Icons.school_rounded,
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      domain.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildGoalStep(ThemeData theme, OnboardingOptions options) {
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
        ...options.goalIntensities.map((goal) {
          final isSelected = _dailyMinutes == goal.defaultMinutes;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassmorphicCard(
              glow: isSelected,
              onTap: () => setState(() => _dailyMinutes = goal.defaultMinutes),
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
                      Icons.timer_rounded,
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.onboardingMinutesPerDay(
                        goal.defaultMinutes,
                        _goalLabel(goal.value, l10n),
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildLevelStep(ThemeData theme, OnboardingOptions options) {
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
          l10n.onboardingCurrentLevelBody,
          style: AppTypography.bodyMedium.copyWith(
            color: theme.brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 20),
        ...options.educationLevels.map((level) {
          final isSelected = _selectedLevelId == level.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassmorphicCard(
              glow: isSelected,
              onTap: () => setState(() => _selectedLevelId = level.id),
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
                      Icons.person_outline,
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      level.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
