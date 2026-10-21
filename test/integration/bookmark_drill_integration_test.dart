/// Cross-layer test for the bookmark drill.
///
/// The bookmarks endpoint publishes the question **and its options** now, so a
/// bookmark can be drilled as it is — the drill is built from the bookmarks
/// themselves, and the attempt is seeded with the bookmarked ids so the server
/// grades what the user actually bookmarked.
library;

import 'package:bisaasmobile/features/practice/data/datasources/practice_remote_data_source.dart';
import 'package:bisaasmobile/features/practice/data/models/practice_dto.dart';
import 'package:bisaasmobile/features/practice/data/repositories/practice_repository_impl.dart';
import 'package:bisaasmobile/features/practice/domain/entities/practice.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {  group('the bookmark drill', () {
    late FakeApi api;
    late PracticeRepositoryImpl repository;

    setUp(() {
      api = FakeApi(<String, FakeRoute>{});
      repository = PracticeRepositoryImpl(
        PracticeRemoteDataSource(dioFor(api)),
      );
    });

    test("the drill is built from the bookmarks' own options", () async {
      api.on(
        'POST',
        '/quiz/attempts',
        FakeRoute.ok(<String, dynamic>{
          'attempt_id': 900,
          'mode': 'practice',
          'status': 'in_progress',
          'question_count': 2,
        }),
      );

      final drill = await repository.startBookmarkDrill(
        title: 'Bookmarked Practice',
        bookmarks: <BookmarkedQuestion>[
          BookmarkedQuestionDto.fromJson(<String, dynamic>{
            'question': <String, dynamic>{
              'id': 11,
              'question_text': 'Bookmarked question one',
              'options': <Map<String, dynamic>>[
                <String, dynamic>{'key': 'A', 'text': 'Right'},
              ],
              'quiz_category_id': 3,
            },
          }).toDomain(),
          BookmarkedQuestionDto.fromJson(<String, dynamic>{
            'question': <String, dynamic>{
              'id': 12,
              'question_text': 'Bookmarked question two',
              'options': <Map<String, dynamic>>[
                <String, dynamic>{'key': 'A', 'text': 'Right'},
              ],
              'quiz_category_id': 4,
            },
          }).toDomain(),
        ],
      );

      expect(drill.questions.map((q) => q.id), <int>[11, 12]);
      expect(drill.questions.first.options, hasLength(1));
      expect(drill.undrillableCount, 0);

      // The attempt is seeded with the **bookmarked** ids — the server grades
      // the questions the user bookmarked.
      final body = api.jsonBodyOf(0);
      expect(body['mode'], 'practice');
      expect(body['question_ids'], <int>[11, 12]);
    });

    test('no question-collection round trip is needed when the options are there',
        () async {
      api.on(
        'POST',
        '/quiz/attempts',
        FakeRoute.ok(<String, dynamic>{
          'attempt_id': 901,
          'mode': 'practice',
          'status': 'in_progress',
          'question_count': 1,
        }),
      );

      await repository.startBookmarkDrill(
        title: 'Bookmarked Practice',
        bookmarks: <BookmarkedQuestion>[
          BookmarkedQuestionDto.fromJson(<String, dynamic>{
            'question': <String, dynamic>{
              'id': 21,
              'question_text': 'Has its own options',
              'options': <Map<String, dynamic>>[
                <String, dynamic>{'key': 'A', 'text': 'Right'},
              ],
            },
          }).toDomain(),
        ],
      );


      // Only the attempt start was called — the drill did not go looking for
      // the question in the collection.
      expect(api.requests, hasLength(1));
      expect(api.requests.single.method, 'POST');
    });
  });
}
