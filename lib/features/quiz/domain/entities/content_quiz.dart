/// Tests generated from book content.
///
/// Generation is asynchronous and server-side, so a freshly created quiz is a
/// **pending** record rather than a set of questions. The client has to be able
/// to say "being prepared" without implying a test is ready to take, which is
/// what GenerationStatus is for.
library;

import 'package:flutter/foundation.dart';

/// What a generated test is scoped to. The server validates the matching id with
/// `required_if`, so an unrecognised value is a 422 rather than a silent default.
enum ContentQuizScope {
  topic,
  chapter,
  book,
  selection;

  static ContentQuizScope byName(String? name) {
    for (final s in ContentQuizScope.values) {
      if (s.name == name) return s;
    }
    // An unknown scope is treated as `selection`, the widest and least
    // prescriptive of the real scopes, rather than being guessed at.
    return ContentQuizScope.selection;
  }

  String get wireValue => name;
}

/// Where generation has got to.
enum GenerationStatus {
  pending,
  generating,
  ready,
  failed;

  static GenerationStatus byName(String? name) {
    final v = name?.toLowerCase();
    for (final s in GenerationStatus.values) {
      if (s.name == v) return s;
    }
    // An unrecognised status reads as `pending`. Treating it as `ready` would
    // offer a user a test whose questions may not exist.
    return GenerationStatus.pending;
  }

  /// True only when the questions are actually there.
  bool get isReady => this == GenerationStatus.ready;
}

@immutable
class ContentQuiz {
  const ContentQuiz({
    required this.id,
    required this.scope,
    this.questionCount = 0,
    this.generationStatus = GenerationStatus.pending,
    this.trigger,
    this.bookId,
    this.chapterId,
    this.topicId,
    this.questionIds = const [],
  });

  final int id;
  final ContentQuizScope scope;
  final int questionCount;
  final GenerationStatus generationStatus;
  final String? trigger;
  final int? bookId;
  final int? chapterId;
  final int? topicId;
  final List<int> questionIds;

  /// True when the server says the questions are ready. The count is not trusted
  /// as a substitute: a record with 0 ids and a `ready` status is a server bug,
  /// and offering a start button would be a lie.
  bool get canStart => generationStatus.isReady && questionIds.isNotEmpty;

  /// Wording that matches the actual state, so a pending test is never presented
  /// as a finished one.
  String get statusLabel => switch (generationStatus) {
        GenerationStatus.ready =>
          questionIds.isEmpty ? 'Ready, but no questions were returned' : 'Ready to take',
        GenerationStatus.generating => 'Being prepared…',
        GenerationStatus.failed => 'Could not be generated',
        GenerationStatus.pending => 'Waiting to be prepared',
      };
}
