/// A server-published study-planner payload.
///
/// The coach / triage / sprint / weekly endpoints answer a payload whose shape
/// the server owns and evolves. Wrapping it rather than re-parsing it here is
/// deliberate: this entity is the domain's handle on that payload, and it does
/// not invent fields the response did not publish. The one derived value is
/// the numeric exam id the triage route needs, which the UI used to pull out
/// of the raw map by hand.
library;

class EicePayload {
  const EicePayload(this.raw);

  /// The untouched `data` object from the envelope. Presentation renders it
  /// verbatim through `PayloadView`, so no server field is lost on the way.
  final Map<String, dynamic> raw;

  /// `exam_id` is the server's own field on the coach payload. Both spellings
  /// are accepted because the server has published both over time; a string is
  /// parsed rather than guessed at.
  int? get examId {
    final value = raw['exam_id'] ?? raw['examId'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
