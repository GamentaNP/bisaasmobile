import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/chunky/chunky_button.dart';
import '../../../../shared/widgets/chunky/chunky_kit.dart';
import '../../domain/entities/arcade_category.dart';
import '../../domain/entities/arcade_mode.dart';
import '../controllers/arcade_controller.dart';

/// The arcade hub: three server-backed run modes, one optional category scope.
///
/// It exists because the quiz tab advertised an "Arcade Games" row that led
/// nowhere. Every card here starts a route that exists on the server, and the
/// category picker walks course → category because that is the only shape the
/// API serves.
class ArcadeHubScreen extends ConsumerStatefulWidget {
  const ArcadeHubScreen({super.key});

  @override
  ConsumerState<ArcadeHubScreen> createState() => _ArcadeHubScreenState();
}

class _ArcadeHubScreenState extends ConsumerState<ArcadeHubScreen> {
  ArcadeCategory? _category;

  Future<void> _start(ArcadeMode mode) async {
    final controller = ref.read(arcadeControllerProvider.notifier);
    // Start first, then navigate: the play screen renders the starting and
    // failure phases, so a failed start stays on a screen that can retry it
    // instead of dumping the user back on the hub with a toast.
    unawaited(controller.start(mode, category: _category));
    if (mounted) unawaited(context.push('/arcade/play', extra: mode));
  }

  Future<void> _pickCategory() async {
    final selected = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CategoryPicker(selected: _category),
    );
    if (!mounted) return;
    // `null` is a dismissal and keeps the current scope; `_ClearScope` is the
    // explicit "any category" choice. They cannot share a value, or closing the
    // sheet would silently clear the user's category.
    if (selected is ArcadeCategory) {
      setState(() => _category = selected);
    } else if (selected is _ClearScope) {
      setState(() => _category = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final run = ref.watch(arcadeControllerProvider);
    final startingMode =
        run.phase == ArcadePhase.starting ? run.mode : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.arcadeTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _Intro(subtitle: l10n.arcadeSubtitle, badge: l10n.arcadeServerScored),
          const SizedBox(height: 16),
          _CategoryRow(
            label: _category?.name ?? l10n.arcadeAnyCategory,
            hint: l10n.arcadeCategoryHint,
            onPick: _pickCategory,
            onClear: _category == null
                ? null
                : () => setState(() => _category = null),
          ),
          const SizedBox(height: 20),
          for (final mode in ArcadeMode.values) ...[
            _ModeCard(
              mode: mode,
              busy: startingMode == mode,
              disabled: startingMode != null,
              onPlay: () => _start(mode),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.subtitle, required this.badge});

  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.violet.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.videogame_asset_rounded,
              color: AppColors.violet, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.hint,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final String hint;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onPick,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category_rounded,
                          size: 20, color: AppColors.brand),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.expand_more_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onClear,
                child: Text(l10n.arcadeCategoryClear),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          hint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.busy,
    required this.disabled,
    required this.onPlay,
  });

  final ArcadeMode mode;
  final bool busy;
  final bool disabled;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final copy = _copyFor(mode, l10n);
    final accent = _accentFor(mode);

    return ChunkyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(copy.icon, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      copy.body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _RuleChip(
                icon: Icons.quiz_rounded,
                label: l10n.arcadeRuleQuestions(mode.questionLimit),
              ),
              if (mode.secondsPerQuestion != null)
                _RuleChip(
                  icon: Icons.timer_rounded,
                  label: l10n.arcadeRuleSeconds(mode.secondsPerQuestion!),
                ),
              if (mode.endsOnWrongAnswer)
                _RuleChip(
                  icon: Icons.bolt_rounded,
                  label: l10n.arcadeRuleUntilMiss,
                ),
            ],
          ),
          const SizedBox(height: 14),
          ChunkyButton(
            label: busy ? l10n.arcadeStarting : l10n.arcadeStartRun,
            icon: Icons.play_arrow_rounded,
            size: ChunkySize.md,
            loading: busy,
            onPressed: disabled ? null : onPlay,
          ),
        ],
      ),
    );
  }

  static Color _accentFor(ArcadeMode mode) => switch (mode) {
        ArcadeMode.survival => AppColors.errorShadow,
        ArcadeMode.lightning => AppColors.warningShadow,
        ArcadeMode.trueFalse => AppColors.brandAccent,
      };

  static ({String title, String body, IconData icon}) _copyFor(
    ArcadeMode mode,
    AppLocalizations l10n,
  ) =>
      switch (mode) {
        ArcadeMode.survival => (
            title: l10n.arcadeSurvivalTitle,
            body: l10n.arcadeSurvivalBody,
            icon: Icons.local_fire_department_rounded,
          ),
        ArcadeMode.lightning => (
            title: l10n.arcadeLightningTitle,
            body: l10n.arcadeLightningBody,
            icon: Icons.flash_on_rounded,
          ),
        ArcadeMode.trueFalse => (
            title: l10n.arcadeTrueFalseTitle,
            body: l10n.arcadeTrueFalseBody,
            icon: Icons.swap_horiz_rounded,
          ),
      };
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Sentinel popped by the picker's "Any category" row.
///
/// It cannot be `null`: `null` is what the sheet returns when it is dismissed,
/// and dismissing must keep the user's existing scope.
class _ClearScope {
  const _ClearScope();
}

/// Course → category picker.
///
/// Two steps because the API has no flat category list: the first screen is
/// `/quiz/courses`, the second is `/quiz/courses/{course}/categories`. Both
/// states show a retry on failure — a failed load is never an empty list.
class _CategoryPicker extends ConsumerStatefulWidget {
  const _CategoryPicker({this.selected});

  final ArcadeCategory? selected;

  @override
  ConsumerState<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends ConsumerState<_CategoryPicker> {
  late Future<List<ArcadeCourse>> _courses;
  ArcadeCourse? _course;
  Future<List<ArcadeCategory>>? _categories;

  @override
  void initState() {
    super.initState();
    _courses = ref.read(arcadeRepositoryProvider).courses();
  }

  void _reload() {
    setState(() {
      _course = null;
      _categories = null;
      _courses = ref.read(arcadeRepositoryProvider).courses();
    });
  }

  void _openCourse(ArcadeCourse course) {
    setState(() {
      _course = course;
      _categories = ref.read(arcadeRepositoryProvider).categories(course: course);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_course != null)
                    IconButton(
                      onPressed: () => setState(() {
                        _course = null;
                        _categories = null;
                      }),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: l10n.arcadeChooseCourse,
                    ),
                  Expanded(
                    child: Text(
                      _course == null
                          ? l10n.arcadeChooseCourse
                          : l10n.arcadeChooseCategory,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.selected != null && _course == null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.clear_all_rounded),
                  title: Text(l10n.arcadeAnyCategory),
                  onTap: () => Navigator.of(context).pop(const _ClearScope()),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              Flexible(
                child: _course == null
                    ? _CourseList(
                        future: _courses,
                        onRetry: _reload,
                        onPick: _openCourse,
                      )
                    : _CategoryList(
                        future: _categories!,
                        course: _course!,
                        onRetry: () => _openCourse(_course!),
                        onPick: (category) =>
                            Navigator.of(context).pop(category),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseList extends StatelessWidget {
  const _CourseList({
    required this.future,
    required this.onRetry,
    required this.onPick,
  });

  final Future<List<ArcadeCourse>> future;
  final VoidCallback onRetry;
  final ValueChanged<ArcadeCourse> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<ArcadeCourse>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _PickerError(
            message: ErrorHandler.handle(snapshot.error!).message,
            retryLabel: l10n.arcadeRetry,
            onRetry: onRetry,
          );
        }
        final courses = snapshot.data ?? const [];
        if (courses.isEmpty) {
          return _PickerError(
            message: l10n.arcadeEmptyBody,
            retryLabel: l10n.arcadeRetry,
            onRetry: onRetry,
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_rounded),
              title: Text(course.name),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onPick(course),
            );
          },
        );
      },
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.future,
    required this.course,
    required this.onRetry,
    required this.onPick,
  });

  final Future<List<ArcadeCategory>> future;
  final ArcadeCourse course;
  final VoidCallback onRetry;
  final ValueChanged<ArcadeCategory> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<ArcadeCategory>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _PickerError(
            message: ErrorHandler.handle(snapshot.error!).message,
            retryLabel: l10n.arcadeRetry,
            onRetry: onRetry,
          );
        }
        final categories = snapshot.data ?? const [];
        if (categories.isEmpty) {
          return _PickerError(
            message: l10n.arcadeEmptyBody,
            retryLabel: l10n.arcadeRetry,
            onRetry: onRetry,
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.label_rounded),
              title: Text(category.name),
              subtitle: Text(course.name),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onPick(category),
            );
          },
        );
      },
    );
  }
}

class _PickerError extends StatelessWidget {
  const _PickerError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined,
              size: 44, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
