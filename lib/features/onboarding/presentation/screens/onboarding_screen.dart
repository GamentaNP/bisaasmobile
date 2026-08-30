import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/storage/preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  String _selectedExam = 'Loksewa / Civil PSC';
  int _dailyMinutes = 30;
  String _experienceLevel = 'Graduate';

  final _exams = const [
    {
      'title': 'Loksewa / Civil PSC',
      'desc': 'Assistant Sub-Engineer, Sub-Engineer, & Engineer exams',
      'icon': Icons.account_balance_rounded,
    },
    {
      'title': 'GATE / Indian PSC',
      'desc': 'Graduate Aptitude Test & State Engineering Services',
      'icon': Icons.school_rounded,
    },
    {
      'title': 'SSC JE / Diploma',
      'desc': 'Junior Engineer Technical & General Practice',
      'icon': Icons.engineering_rounded,
    },
    {
      'title': 'University Semester Exams',
      'desc': 'Structural, Geotechnical, Surveying, & Fluid Mechanics',
      'icon': Icons.menu_book_rounded,
    },
  ];

  final _goals = const [
    {
      'minutes': 15,
      'label': 'Casual Review',
      'desc': '10-15 daily questions to maintain streak',
      'icon': Icons.timer_outlined,
    },
    {
      'minutes': 30,
      'label': 'Focused Mastery',
      'desc': '25-30 questions + formula revisions',
      'icon': Icons.timer_rounded,
    },
    {
      'minutes': 60,
      'label': 'Intensive Sprint',
      'desc': 'Mock exam practice & comprehensive tests',
      'icon': Icons.bolt_rounded,
    },
  ];

  final _levels = const [
    {
      'title': 'Engineering Student',
      'desc': 'Currently enrolled in Civil Engineering diploma/degree',
      'icon': Icons.person_outline,
    },
    {
      'title': 'Graduate / Job Seeker',
      'desc': 'Actively preparing for competitive technical exams',
      'icon': Icons.workspace_premium_outlined,
    },
    {
      'title': 'Practicing Engineer',
      'desc': 'Refreshing core theory and design standards',
      'icon': Icons.architecture_rounded,
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = Preferences.instance;
    await prefs.setSelectedExam(_selectedExam);
    await prefs.setDailyGoalMinutes(_dailyMinutes);
    await prefs.setExperienceLevel(_experienceLevel);
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
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_currentPage + 1} of 3',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),

            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / 3,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
              child: FilledButton(
                onPressed: _nextPage,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _currentPage == 2 ? 'Start Learning' : 'Continue',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamStep(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(
          'Target Examination',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your primary syllabus track to personalize questions and study sprint plans.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 20),
        ..._exams.map((exam) {
          final isSelected = _selectedExam == exam['title'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _selectedExam = exam['title']! as String),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brand.withValues(alpha: 0.1)
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brand
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brand
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        exam['icon']! as IconData,
                        color: isSelected ? Colors.black : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam['title']! as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exam['desc']! as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGoalStep(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(
          'Daily Practice Goal',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'How much time would you like to dedicate each day? You can change this anytime.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 20),
        ..._goals.map((goal) {
          final isSelected = _dailyMinutes == goal['minutes'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _dailyMinutes = goal['minutes']! as int),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brand.withValues(alpha: 0.1)
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brand
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brand
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        goal['icon']! as IconData,
                        color: isSelected ? Colors.black : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${goal['minutes']} mins / day — ${goal['label']}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            goal['desc']! as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLevelStep(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(
          'Your Current Level',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Help our IRT calibration engine tailor initial question difficulty to your stage.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 20),
        ..._levels.map((level) {
          final isSelected = _experienceLevel == level['title'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _experienceLevel = level['title']! as String),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brand.withValues(alpha: 0.1)
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brand
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brand
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        level['icon']! as IconData,
                        color: isSelected ? Colors.black : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level['title']! as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            level['desc']! as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
            ),
          );
        }),
      ],
    );
  }
}
