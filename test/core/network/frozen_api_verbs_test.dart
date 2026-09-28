import 'dart:convert';
import 'dart:typed_data';

import 'package:bisaasmobile/features/contests/data/datasources/contests_remote_data_source.dart';
import 'package:bisaasmobile/features/eice/data/eice_remote_data_source.dart';
import 'package:bisaasmobile/features/learning/data/datasources/learning_remote_data_source.dart';
import 'package:bisaasmobile/features/library/data/datasources/library_remote_data_source.dart';
import 'package:bisaasmobile/features/live_events/data/datasources/live_events_remote_data_source.dart';
import 'package:bisaasmobile/features/psc/data/psc_remote_data_source.dart';
import 'package:bisaasmobile/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:bisaasmobile/features/store/data/datasources/store_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records real requests through Dio's adapter so the assertions are on the
/// actual method + path, not on mocktail's typed-argument matching.
class _Recorder implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': <String, dynamic>{'id': 1, 'questions': <dynamic>[]},
      }),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }
}

/// The server registers the frozen §4.3 transitions canonically and keeps the
/// older POST spellings as `*.transition-alias`, additive-only until the
/// grammar freeze. The client was sitting on nine of those aliases.
///
/// One was worse than future-proofing: the calculation-snapshot sync posted to
/// `/v1/calculation-snapshots/sync`, which with an `/api/v1` base URL became
/// `/api/v1/v1/...` and 404'd on every drain, so offline snapshots were never
/// synced at all. That path is asserted in `sync_queue_test.dart`.
void main() {
  late _Recorder recorder;
  late Dio dio;

  setUp(() {
    recorder = _Recorder();
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
      ..httpClientAdapter = recorder;
  });

  RequestOptions last() => recorder.requests.last;

  test('start attempt is POST /quiz/attempts, not the /start alias', () async {
    await QuizRemoteDataSource(dio).startAttempt(quizId: '1');
    expect(last().method, 'POST');
    expect(last().path, '/quiz/attempts');
  });

  test('answer is POST /quiz/attempts/{id}/answers (plural collection)', () async {
    await QuizRemoteDataSource(dio).submitAnswer(
      attemptId: '9',
      questionId: '3',
      selectedOptionId: 'a',
    );
    expect(last().method, 'POST');
    expect(last().path, '/quiz/attempts/9/answers');
  });

  test('complete is PUT /quiz/attempts/{id}/completion', () async {
    await QuizRemoteDataSource(dio).finishAttempt('9');
    expect(last().method, 'PUT');
    expect(last().path, '/quiz/attempts/9/completion');
  });

  test('review grade is PUT /learning/reviews/{id}/grade', () async {
    await LearningRemoteDataSource(dio).gradeReview(4, 'good');
    expect(last().method, 'PUT');
    expect(last().path, '/learning/reviews/4/grade');
  });

  test('library unlock is PUT /library/files/{slug}/unlock', () async {
    await LibraryRemoteDataSource(dio).unlock('soil-mechanics');
    expect(last().method, 'PUT');
    expect(last().path, '/library/files/soil-mechanics/unlock');
  });

  test('wardrobe equip is PUT /store/wardrobe/equipment', () async {
    await StoreRemoteDataSource(dio).equip('head', 'hard-hat');
    expect(last().method, 'PUT');
    expect(last().path, '/store/wardrobe/equipment');
  });

  test('contest join is PUT /quiz/contests/{id}/participation', () async {
    await ContestsRemoteDataSource(dio).joinContest(7);
    expect(last().method, 'PUT');
    expect(last().path, '/quiz/contests/7/participation');
  });

  test('live event register is PUT /quiz/live-events/{id}/registration', () async {
    await LiveEventsRemoteDataSource(dio).register(12);
    expect(last().method, 'PUT');
    expect(last().path, '/quiz/live-events/12/registration');
  });

  test('sprint grade is PUT /quiz/sprint/{q}/grade', () async {
    await EiceRemoteDataSource(dio).gradeSprint('5', 4);
    expect(last().method, 'PUT');
    expect(last().path, '/quiz/sprint/5/grade');
  });

  test('psc submit is PUT /psc/blueprints/{id}/submission', () async {
    await PscRemoteDataSource(dio).submit('3', <String, dynamic>{});
    expect(last().method, 'PUT');
    expect(last().path, '/psc/blueprints/3/submission');
  });
}
