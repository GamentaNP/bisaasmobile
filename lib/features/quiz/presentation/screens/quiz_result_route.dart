import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/quiz_controller.dart';
import '../state/quiz_state.dart';
import 'quiz_result_screen.dart';
import 'quiz_review_screen.dart';

/// Backs the `/quiz/attempt/{attemptId}/result` route.
///
/// The route used to render `QuizReviewScreen` unconditionally, which meant the
/// in-session result moment (accuracy ring, Correct/XP/Coins, per-question
/// breakdown, confetti, share) was unreachable — the only caller
/// (`quiz_attempt_screen.dart`) jumps here the moment the attempt finishes.
///
/// Two cases, deliberately distinguished:
///
///  * **Live session** — the quiz controller is still holding the finished
///    `QuizState` for this attempt, so render the rich result screen. All
///    numbers come from server-graded state; nothing is recomputed here.
///  * **Deep link / cold start / reload** — there is no in-memory state, so
///    fall back to the review screen, which rebuilds everything from
///    `GET /quiz/attempts/{id}/results`.
///
/// The explicit `/result/review` child route always renders the review screen,
/// which is what the result screen's "see detailed review" action targets.
class QuizResultRoute extends ConsumerWidget {
  const QuizResultRoute({required this.attemptId, super.key});

  final String attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);
    final isLiveFinish = state.phase == QuizPhase.finished && state.attemptId == attemptId;
    return isLiveFinish ? QuizResultScreen(quizState: state) : QuizReviewScreen(attemptId: attemptId);
  }
}
