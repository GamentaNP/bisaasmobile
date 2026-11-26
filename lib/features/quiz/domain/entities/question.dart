import 'package:meta/meta.dart';

/// Question families the attempt screen can render.
///
/// Mirrors the wire values of the server's `App\Domains\Quiz\Enums\QuestionType`
/// (after its `canonical()` normalisation). A value that is not in this table
/// is deliberately *not* quietly treated as an MCQ: the screen surfaces an
/// unsupported-question error with a retry instead of fabricating a UI the
/// server grader would never accept.
enum QuizQuestionType {
  singleChoice,
  multipleChoice,
  trueFalse,
  fillBlank,
  fillBlankMultiple,
  imageBased;

  static QuizQuestionType? fromWire(String raw) {
    final value = raw.trim().toLowerCase();
    // Legacy Drift rows and the daily pack predate the `type` field. They only
    // ever carried MCQ options, so an absent value keeps working. A present
    // value that is not in the switch below is NOT given this fallback.
    if (value.isEmpty) return QuizQuestionType.singleChoice;
    switch (value) {
      case 'mcq':
      case 'mcq_single':
      case 'best_answer':
      case 'odd_one_out':
        return QuizQuestionType.singleChoice;
      case 'multi_select':
      case 'mcq_multiple':
        return QuizQuestionType.multipleChoice;
      case 'true_false':
        return QuizQuestionType.trueFalse;
      case 'fill_blank':
      case 'fill_blank_single':
      case 'short_answer':
        return QuizQuestionType.fillBlank;
      case 'fill_blank_multiple':
        return QuizQuestionType.fillBlankMultiple;
      case 'image_based':
      case 'image_mcq':
        return QuizQuestionType.imageBased;
      default:
        return null;
    }
  }
}

@immutable
class AnswerOption {
  const AnswerOption({
    required this.id,
    required this.text,
    required this.position,
  });

  final String id;
  final String text;
  final int position;
}

@immutable
class Question {
  const Question({
    required this.id,
    required this.body,
    required this.options,
    required this.subjectSlug,
    required this.difficulty,
    required this.marksPositive,
    required this.marksNegative,
    required this.type,
    this.metadata = const <String, dynamic>{},
    this.quizId,
    this.explanation,
    this.correctOptionId,
  });

  final String id;
  final String body;
  final List<AnswerOption> options;
  final String subjectSlug;
  final int difficulty;
  final int marksPositive;
  final int marksNegative;

  /// Raw wire value (`mcq`, `multi_select`, `fill_blank_multiple`, …).
  /// Kept verbatim so an unsupported value can be named in the error UI.
  final String type;

  /// Attempt-safe metadata from the question resource. Render-only keys such
  /// as `image_url` and `blank_count` live here; answer keys never do.
  final Map<String, dynamic> metadata;

  final String? quizId;
  final String? explanation;
  // Only populated after server grading
  final String? correctOptionId;

  /// `null` means the server sent a family this client cannot render.
  QuizQuestionType? get inputKind => QuizQuestionType.fromWire(type);

  /// The server publishes the figure under `metadata.image_url`; the offline
  /// daily pack carries the same key at the top level (normalised in the DTO).
  String? get imageUrl {
    final raw = metadata['image_url'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  /// Number of answer slots for a multi-blank question.
  int get blankCount {
    final raw = metadata['blank_count'];
    if (raw is int && raw > 0) return raw;
    if (raw is num && raw > 0) return raw.toInt();
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null && parsed > 0) return parsed;
    }
    return options.isNotEmpty ? options.length : 2;
  }

  /// Keys that identify each blank in the wire answer (`a:cat,b:dog`).
  /// Stored option keys win; the renderer's fallback slots are used only when
  /// the author saved no options, mirroring the web renderer's contract.
  List<String> get blankKeys => options.isNotEmpty
      ? options.map((option) => option.id).toList()
      : List<String>.generate(blankCount, (index) => 'blank_${index + 1}');
}

@immutable
class QuizSession {
  const QuizSession({
    required this.id,
    required this.title,
    required this.questions,
    required this.durationSeconds,
    this.xpReward = 0,
    this.coinsReward = 0,
    this.subjectSlug,
  });

  final String id;
  final String title;
  final List<Question> questions;
  final int durationSeconds;
  final int xpReward;
  final int coinsReward;
  final String? subjectSlug;

  int get totalQuestions => questions.length;
}
