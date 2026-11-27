/// Pure Dart view of `GET /quiz/knowledge-atoms/{atom}` (§9.5).
///
/// The server publishes only the popover-safe fields: a title, a 480-char plain
/// text summary and the owning topic id. There is no lesson body and no answer
/// key here, and the client never invents either.
library;

class KnowledgeAtom {
  const KnowledgeAtom({
    required this.id,
    this.title,
    this.type,
    this.summary,
    this.topicId,
  });

  final int id;
  final String? title;
  final String? type;
  final String? summary;
  final int? topicId;
}
