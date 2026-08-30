import 'package:bisaasmobile/features/live_events/data/models/live_event_dto.dart';
import 'package:bisaasmobile/features/live_events/domain/entities/live_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveEventDto', () {
    test('fromJson minimal', () {
      final dto = LiveEventDto.fromJson({'id': 1, 'title': 'Live Quiz', 'event_type': 'quiz', 'status': 'scheduled', 'question_count': 10, 'starts_at': '2026-09-01T10:00:00Z', 'question_duration_seconds': 30, 'active_participant_count': 5, 'waitlisted_participant_count': 0, 'entry_fee_coins': 0, 'prize_pool_coins': 100, 'waitlist_enabled': true, 'replay_enabled': false});
      expect(dto.id, 1);
      expect(dto.title, 'Live Quiz');
      expect(dto.status, 'scheduled');
      expect(dto.toDomain(), isA<LiveEvent>());
      expect(dto.toDomain().isJoinable, isTrue);
    });

    test('fromJson with camelCase', () {
      final dto = LiveEventDto.fromJson({'id': 2, 'title': 'X', 'eventType': 'quiz', 'status': 'live', 'questionCount': 5, 'startsAt': '2026-09-01T10:00:00Z', 'questionDurationSeconds': 20, 'activeParticipantCount': 10, 'waitlistedParticipantCount': 1, 'entryFeeCoins': 10, 'prizePoolCoins': 200, 'waitlistEnabled': false, 'replayEnabled': true});
      expect(dto.status, 'live');
      expect(dto.toDomain().isLive, isTrue);
    });

    test('handles string numbers', () {
      final dto = LiveEventDto.fromJson({'id': '3', 'title': 'T', 'event_type': 'quiz', 'status': 'countdown', 'question_count': '7', 'starts_at': '2026-09-01T10:00:00Z', 'question_duration_seconds': '15', 'active_participant_count': '0', 'waitlisted_participant_count': '0', 'entry_fee_coins': '0', 'prize_pool_coins': '0', 'waitlist_enabled': false, 'replay_enabled': false});
      expect(dto.id, 3);
      expect(dto.questionCount, 7);
    });

    test('additive tolerant', () {
      final dto = LiveEventDto.fromJson({'id': 7, 'title': 'T', 'event_type': 'quiz', 'status': 'scheduled', 'question_count': 10, 'starts_at': '2026-09-01T10:00:00Z', 'question_duration_seconds': 30, 'active_participant_count': 0, 'waitlisted_participant_count': 0, 'entry_fee_coins': 0, 'prize_pool_coins': 0, 'waitlist_enabled': false, 'replay_enabled': false, 'future': 123});
      expect(dto.id, 7);
    });
  });

  group('LiveEventParticipantDto', () {
    test('fromJson minimal', () {
      final dto = LiveEventParticipantDto.fromJson({'id': 1, 'quiz_live_event_id': 5, 'user_id': 42, 'status': 'registered', 'score': 10, 'correct_count': 2, 'answered_count': 3, 'registered_at': '2026-08-30T10:00:00Z'});
      expect(dto.id, 1);
      expect(dto.eventId, 5);
      expect(dto.score, 10);
      expect(dto.toDomain(), isA<LiveEventParticipant>());
    });

    test('handles camelCase', () {
      final dto = LiveEventParticipantDto.fromJson({'id': 2, 'eventId': 5, 'userId': 7, 'status': 'waitlisted', 'score': 0, 'correctCount': 0, 'answeredCount': 0, 'registeredAt': '2026-08-30T10:00:00Z'});
      expect(dto.status, 'waitlisted');
      expect(dto.toDomain().isWaitlisted, isTrue);
    });
  });

  group('LiveEventDetailDto', () {
    test('fromJson with event and leaderboard', () {
      final dto = LiveEventDetailDto.fromJson({
        'event': {'id': 10, 'title': 'Final', 'event_type': 'quiz', 'status': 'live', 'question_count': 10, 'starts_at': '2026-09-01T10:00:00Z', 'question_duration_seconds': 30, 'active_participant_count': 5, 'waitlisted_participant_count': 0, 'entry_fee_coins': 0, 'prize_pool_coins': 100, 'waitlist_enabled': false, 'replay_enabled': false},
        'leaderboard': [
          {'rank': 1, 'score': 100, 'user_id': 1},
        ],
      });
      expect(dto.event.title, 'Final');
      expect(dto.leaderboard.length, 1);
      expect(dto.toDomain().event.id, 10);
    });

    test('tolerant flat', () {
      final dto = LiveEventDetailDto.fromJson({'id': 11, 'title': 'Flat', 'event_type': 'quiz', 'status': 'scheduled', 'question_count': 5, 'starts_at': '2026-09-01T10:00:00Z', 'question_duration_seconds': 30, 'active_participant_count': 0, 'waitlisted_participant_count': 0, 'entry_fee_coins': 0, 'prize_pool_coins': 0, 'waitlist_enabled': false, 'replay_enabled': false});
      expect(dto.event.id, 11);
    });
  });

  group('LiveEventSnapshotDto', () {
    test('fromJson with current_question', () {
      final dto = LiveEventSnapshotDto.fromJson({
        'current_question': {'question_id': 99, 'index': 2, 'question_text': 'What is 2+2?'},
        'participant': {'id': 1, 'quiz_live_event_id': 10, 'user_id': 42, 'status': 'active', 'score': 20, 'correct_count': 2, 'answered_count': 2, 'registered_at': '2026-08-30T10:00:00Z'},
      });
      final snap = dto.toDomain();
      expect(snap.currentQuestion, isNotNull);
      expect(snap.hasCurrentQuestion, isTrue);
      expect(snap.participant, isNotNull);
    });

    test('handles nested snapshot', () {
      final dto = LiveEventSnapshotDto.fromJson({
        'snapshot': {'current_question': {'question_id': 5, 'index': 0}},
      });
      expect(dto.toDomain().currentQuestion, isNotNull);
    });

    test('handles empty', () {
      final dto = LiveEventSnapshotDto.fromJson({});
      expect(dto.toDomain().hasCurrentQuestion, isFalse);
    });
  });
}
