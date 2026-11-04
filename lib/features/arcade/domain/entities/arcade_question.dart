import 'package:meta/meta.dart';

/// One answer choice in an arcade question.
///
/// The server's `QuizQuestionResource` sanitises options down to the display
/// fields (`key`, `text`, `label`, `value`, image fields) and strips anything
/// that could leak the answer. The client therefore sends back the option's
/// `key` as the answer — the same value the existing quiz flow submits — and
/// falls back to `id`/`value` for older payloads.
@immutable
class ArcadeOption {
  const ArcadeOption({
    required this.id,
    required this.text,
    required this.position,
  });

  final String id;
  final String text;
  final int position;
}

/// A question as the arcade run needs it: prompt, optional figure, choices.
///
/// Deliberately not the study DTO: an arcade round shows no explanation and no
/// correctness. The server withholds grading until completion for every
/// exam-like mode, and Survival in particular must not be told "wrong" by the
/// client — the server is what ends the run.
@immutable
class ArcadeQuestion {
  const ArcadeQuestion({
    required this.id,
    required this.body,
    required this.options,
    required this.type,
    this.imageUrl,
  });

  final int id;
  final String body;
  final List<ArcadeOption> options;

  /// `mcq`, `true_false`, … — presentation only, never a grading input.
  final String type;
  final String? imageUrl;

  bool get hasOptions => options.isNotEmpty;
}
