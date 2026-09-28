import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/script_fonts.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/dio_client.dart';
import '../data/datasources/numerical_remote_data_source.dart';
import '../domain/entities/numerical.dart';

final numericalRemoteDataSourceProvider = Provider<NumericalRemoteDataSource>(
  (ref) => NumericalRemoteDataSource(DioClient.instance.dio),
);

class NumericalState {
  const NumericalState({
    this.isLoading = false,
    this.problem,
    this.check,
    this.solution,
    this.error,
    this.submitting = false,
    this.hasAttempted = false,
  });

  final bool isLoading;
  final Numerical? problem;

  /// The graded result of the last answer. Null until one has been submitted,
  /// and never carries a withheld answer.
  final NumericalCheck? check;

  /// A worked solution the user has now consumed, from a logged solve attempt.
  final Numerical? solution;
  final String? error;
  final bool submitting;

  /// True once an answer has been graded. A worked solution is only offered
  /// after this, so "show me the solution" is a deliberate act rather than
  /// something sitting next to an untouched problem.
  final bool hasAttempted;

  NumericalState copyWith({
    bool? isLoading,
    Numerical? problem,
    NumericalCheck? check,
    Numerical? solution,
    String? error,
    bool clearError = false,
    bool? submitting,
    bool? hasAttempted,
  }) {
    return NumericalState(
      isLoading: isLoading ?? this.isLoading,
      problem: problem ?? this.problem,
      check: check,
      solution: solution,
      error: clearError ? null : (error ?? this.error),
      submitting: submitting ?? this.submitting,
      hasAttempted: hasAttempted ?? this.hasAttempted,
    );
  }
}

/// Drives one numerical practice instance.
///
/// Grading is entirely server-side. This controller never evaluates a formula,
/// and never fills in an answer the server withheld.
class NumericalController extends Notifier<NumericalState> {
  NumericalController(this.numericalId);

  final int numericalId;

  @override
  NumericalState build() {
    Future.microtask(randomize);
    return const NumericalState();
  }

  NumericalRemoteDataSource get _remote => ref.read(numericalRemoteDataSourceProvider);

  Future<void> randomize() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final problem = await _remote.randomize(numericalId);
      if (problem == null) {
        state = state.copyWith(isLoading: false, error: 'This problem could not be loaded.');
        return;
      }
      // A new randomisation clears the previous verdict and solution, so a stale
      // "correct" badge cannot sit above a fresh problem.
      state = state.copyWith(
        isLoading: false,
        problem: problem,
        submitting: false,
        hasAttempted: false,
      );
    } catch (e) {
      AppLogger.w('numerical randomize $numericalId failed: $e');
      state = state.copyWith(isLoading: false, error: 'Could not load this problem');
    }
  }

  Future<void> submitAnswer(String raw) async {
    if (state.submitting) return;
    final answer = double.tryParse(raw.trim());
    if (answer == null) {
      state = state.copyWith(error: 'Enter a number');
      return;
    }
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final check = await _remote.checkAnswer(numericalId, answer);
      if (check == null) {
        state = state.copyWith(submitting: false, error: 'Could not grade that answer');
        return;
      }
      state = state.copyWith(submitting: false, check: check, hasAttempted: true);
    } catch (e) {
      AppLogger.w('numerical check failed: $e');
      state = state.copyWith(submitting: false, error: 'Could not grade that answer');
    }
  }

  Future<void> showSolution() async {
    if (state.submitting) return;
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final solution = await _remote.solve(
        numericalId,
        parameters: state.problem?.parameters,
      );
      if (solution == null) {
        state = state.copyWith(submitting: false, error: 'No solution available yet');
        return;
      }
      state = state.copyWith(submitting: false, solution: solution);
    } catch (e) {
      AppLogger.w('numerical solve failed: $e');
      state = state.copyWith(submitting: false, error: 'Could not load the solution');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final numericalControllerProvider =
    NotifierProvider.family<NumericalController, NumericalState, int>(
  NumericalController.new,
);

/// Practice one server-solved numerical.
class NumericalPracticeScreen extends ConsumerStatefulWidget {
  const NumericalPracticeScreen({required this.numericalId, super.key});

  final int numericalId;

  @override
  ConsumerState<NumericalPracticeScreen> createState() => _NumericalPracticeScreenState();
}

class _NumericalPracticeScreenState extends ConsumerState<NumericalPracticeScreen> {
  final _answer = TextEditingController();

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(numericalControllerProvider(widget.numericalId));
    final notifier = ref.read(numericalControllerProvider(widget.numericalId).notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Numerical'),
        actions: [
          IconButton(
            tooltip: 'New numbers',
            onPressed: state.isLoading ? null : notifier.randomize,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.isLoading && state.problem == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.problem == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: notifier.randomize,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          state.error!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                    if (state.problem != null) _ProblemBlock(problem: state.problem!),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _answer,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Your answer',
                        suffixText: state.problem?.unit,
                      ),
                      onSubmitted: notifier.submitAnswer,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: state.submitting
                          ? null
                          : () => notifier.submitAnswer(_answer.text),
                      child: state.submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Check answer'),
                    ),
                    if (state.check != null) ...[
                      const SizedBox(height: 16),
                      _Verdict(check: state.check!),
                    ],
                    if (state.check == null || state.check!.correct == false) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed:
                            state.submitting || !state.hasAttempted ? null : notifier.showSolution,
                        child: const Text('Show worked solution'),
                      ),
                    ],
                    if (state.solution != null) ...[
                      const SizedBox(height: 20),
                      _SolutionBlock(solution: state.solution!),
                    ],
                  ],
                ),
    );
  }
}

class _ProblemBlock extends StatelessWidget {
  const _ProblemBlock({required this.problem});

  final Numerical problem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          problem.statement,
          // Server-authored and the most likely place for mixed-script problem
          // text, so the font comes from the string.
          style: ScriptFonts.forText(theme.textTheme.bodyLarge ?? const TextStyle(), problem.statement),
        ),
        if (problem.parameters.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final entry in problem.parameters.entries)
                Text(
                  '${entry.key} = ${formatNumber(entry.value)}',
                  style: theme.textTheme.labelLarge,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.check});

  final NumericalCheck check;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: check.correct
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            check.correct
                ? 'Correct${check.revealsAnswer ? ' · ${formatNumber(check.finalAnswer!)}${check.unitSuffix}' : ''}'
                : 'Not correct. Try again, or open the worked solution.',
            style: theme.textTheme.bodyMedium,
          ),
          if (check.needsReview)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'The server has flagged this problem for review.',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _SolutionBlock extends StatelessWidget {
  const _SolutionBlock({required this.solution});

  final Numerical solution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Worked solution', style: theme.textTheme.titleMedium),
        if (solution.computedBy != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 8),
            child: Text(
              'Computed by: ${solution.computedBy}',
              style: theme.textTheme.labelSmall,
            ),
          ),
        if (solution.needsReview)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Flagged by the server for review — treat this answer with care.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        if (solution.hasSteps)
          for (var i = 0; i < solution.steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '${i + 1}. ${solution.steps[i]}',
                style: ScriptFonts.forText(theme.textTheme.bodyMedium ?? const TextStyle(), solution.steps[i]),
              ),
            ),
        if (solution.finalAnswer != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Answer: ${formatNumber(solution.finalAnswer!)}${solution.unit == null ? '' : ' ${solution.unit}'}',
              style: theme.textTheme.titleMedium,
            ),
          ),
        if (solution.hasLink)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: () {
                final uri = Uri.tryParse(solution.civilCalLink!);
                if (uri != null) context.push(uri.toString());
              },
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Open in calculator'),
            ),
          ),
      ],
    );
  }
}
