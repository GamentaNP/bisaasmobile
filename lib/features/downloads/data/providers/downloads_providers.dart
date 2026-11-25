import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/storage/database/daos/quiz_dao.dart';
import '../../domain/repositories/downloads_repository.dart';
import '../repositories/downloads_repository_impl.dart';

/// The offline cache has no remote data source of its own. Its network side
/// is the daily prefetcher, which is built from `dioProvider`; watching the
/// app's Dio here keeps this feature on the same Dio seam as every feature
/// that does talk to the API directly.
final downloadsRepositoryProvider = Provider<DownloadsRepository>((ref) {
  ref.watch(dioProvider);
  return DownloadsRepositoryImpl(
    QuizDao(ref.watch(appDatabaseProvider)),
    ref.watch(dailyQuizPrefetcherProvider),
  );
});
