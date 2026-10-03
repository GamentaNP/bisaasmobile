import 'bot_decision_kernel.dart';

/// Wire models for the offline bot match contract.
///
/// Hand-written `fromJson` throughout: the freezed / json_serializable chain
/// was removed from this project on 2026-09-28 and must not be reintroduced.
///
/// Every field here is a wire contract with
/// `C:\laragon\www\bisaas\app\Domains\Quiz\Services\QuizOpenApiSpec.php`
/// (quiz contract 2026.10.4). Parsing is deliberately total — an absent or
/// malformed optional field yields null rather than throwing, because a device
/// must never crash on a server response it cannot use; it queues and retries.

/// One simulated opponent as served by `GET /quiz/offline/bot-roster`.
///
/// Carries no account identifier and no answer key. `disclosedAsAi` is always
/// true: a simulated opponent is disclosed as AI, and the client asserts it
/// rather than assuming it.
class OfflineBotOpponent {
  const OfflineBotOpponent({
    required this.botKey,
    required this.displayName,
    required this.difficulty,
    required this.personality,
    required this.accuracyRate,
    required this.minAnswerMs,
    required this.maxAnswerMs,
    required this.misconceptionCode,
    required this.disclosedAsAi,
  });

  final String botKey;
  final String displayName;
  final String difficulty;
  final String personality;
  final int accuracyRate;
  final int minAnswerMs;
  final int maxAnswerMs;

  /// The misconception this bot targets, or null when it targets none.
  final String? misconceptionCode;

  final bool disclosedAsAi;

  static OfflineBotOpponent? fromJson(Map<String, dynamic> json) {
    final botKey = json['bot_key'];
    if (botKey is! String || botKey.isEmpty) return null;

    return OfflineBotOpponent(
      botKey: botKey,
      displayName: _string(json['display_name']) ?? 'Opponent',
      difficulty: _string(json['difficulty']) ?? 'intermediate',
      personality: _string(json['personality']) ?? 'balanced',
      accuracyRate: _int(json['accuracy_rate']) ?? 0,
      minAnswerMs: _int(json['min_answer_ms']) ?? 0,
      maxAnswerMs: _int(json['max_answer_ms']) ?? 0,
      misconceptionCode: _string(json['misconception_code']),
      disclosedAsAi: json['disclosed_as_ai'] as bool? ?? true,
    );
  }
}

/// A roster plus the manifest that pins it.
class OfflineBotRoster {
  const OfflineBotRoster({
    required this.manifestId,
    required this.seed,
    required this.packDay,
    required this.kernelVersion,
    required this.opponents,
    required this.size,
    required this.expiresAt,
  });

  /// Opaque handle a receipt must quote. Without it the server has to guess the
  /// roster, and guessing wrong quarantines an honest player.
  final String manifestId;

  final String seed;
  final String packDay;

  /// Echoed back in the receipt. If the server has moved on, the receipt is
  /// unverifiable rather than false — a distinct outcome the client handles.
  final String kernelVersion;

  final List<OfflineBotOpponent> opponents;
  final int size;
  final DateTime? expiresAt;

  /// True when the server can no longer corroborate a receipt for this roster.
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  static OfflineBotRoster? fromJson(Map<String, dynamic> json) {
    final manifestId = json['manifest_id'];
    final seed = json['seed'];
    if (manifestId is! String ||
        manifestId.isEmpty ||
        seed is! String ||
        seed.isEmpty) {
      return null;
    }

    final rawOpponents = json['opponents'];
    final opponents = <OfflineBotOpponent>[];

    if (rawOpponents is List) {
      for (final entry in rawOpponents) {
        if (entry is Map<String, dynamic>) {
          final parsed = OfflineBotOpponent.fromJson(entry);
          if (parsed != null) opponents.add(parsed);
        }
      }
    }

    return OfflineBotRoster(
      manifestId: manifestId,
      seed: seed,
      packDay: _string(json['pack_day']) ?? '',
      kernelVersion: _string(json['kernel_version']) ?? BotDecisionKernel.version,
      opponents: List.unmodifiable(opponents),
      size: _int(json['size']) ?? opponents.length,
      expiresAt: _dateTime(json['expires_at']),
    );
  }
}

/// One bot decision as reported in a receipt.
class OfflineBotDecision {
  const OfflineBotDecision({
    required this.botKey,
    required this.questionIndex,
    required this.questionId,
    required this.answeredCorrectly,
    required this.durationMs,
    required this.chosenAnswerKey,
  });

  final String botKey;
  final int questionIndex;
  final int questionId;
  final bool answeredCorrectly;
  final int durationMs;

  /// Null on a correct answer. On a wrong answer the server verifies this
  /// against the seed, so it is not free-form: reporting the wrong option is a
  /// detectable forgery, not a rounding difference.
  final String? chosenAnswerKey;

  OfflineBotDecision.fromDecision({
    required this.botKey,
    required this.questionIndex,
    required this.questionId,
    required BotDecision decision,
  })  : answeredCorrectly = decision.answeredCorrectly,
        durationMs = decision.durationMs,
        chosenAnswerKey = decision.chosenAnswerKey;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'bot_key': botKey,
        'question_index': questionIndex,
        'question_id': questionId,
        'answered_correctly': answeredCorrectly,
        'duration_ms': durationMs,
        'chosen_answer_key': chosenAnswerKey,
      };
}

/// The receipt posted to `POST /quiz/offline/match-receipt`.
///
/// There is deliberately no score, XP, coin or completion field: a receipt is
/// evidence about how a bot behaved, never a claim about what the learner
/// earned. Offline results are archive-only, and a payload with nowhere to put
/// a payout is the structural form of that promise.
class OfflineMatchReceipt {
  const OfflineMatchReceipt({
    required this.manifestId,
    required this.seed,
    required this.kernelVersion,
    required this.decisions,
  });

  final String manifestId;
  final String seed;
  final String kernelVersion;
  final List<OfflineBotDecision> decisions;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'manifest_id': manifestId,
        'seed': seed,
        'kernel_version': kernelVersion,
        'decisions': decisions.map((d) => d.toJson()).toList(growable: false),
      };
}

/// The verdict returned by the server.
///
/// Always HTTP 200, including for a quarantined receipt: the client has to
/// prune its outbox either way, and a 4xx would invite it to retry a forgery
/// forever. So the disposition lives in the body, not the status.
class OfflineReceiptVerdict {
  const OfflineReceiptVerdict({
    required this.status,
    required this.reasons,
    required this.awarded,
  });

  /// `corroborated` or `quarantined`.
  final String status;

  /// Machine-readable reasons; empty when corroborated.
  final List<String> reasons;

  /// Always false. Offline awards nothing, and restating it here means a client
  /// cannot infer a payout from a successful call.
  final bool awarded;

  static const String statusCorroborated = 'corroborated';
  static const String statusQuarantined = 'quarantined';

  bool get isCorroborated => status == statusCorroborated;
  bool get isQuarantined => status == statusQuarantined;

  /// A receipt that will never be accepted, whatever the network does.
  ///
  /// Retrying these is how a device ends up replaying a forgery indefinitely,
  /// so the queue treats them as terminal and drops them. An expired manifest
  /// is deliberately NOT terminal: the receipt is stale rather than false, and
  /// a learner who practised offline for a week should not be punished for it.
  bool get isTerminal =>
      isQuarantined && !reasons.contains('expired_manifest');

  static OfflineReceiptVerdict? fromJson(Map<String, dynamic> json) {
    final status = _string(json['status']);
    if (status == null) return null;

    final rawReasons = json['reasons'];

    return OfflineReceiptVerdict(
      status: status,
      reasons: rawReasons is List
          ? rawReasons.whereType<String>().toList(growable: false)
          : const <String>[],
      awarded: json['awarded'] == true,
    );
  }
}

String? _string(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
