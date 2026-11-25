import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/entities/visitor_data.dart';
import '../../domain/repositories/privacy_repository.dart';
import '../datasources/privacy_remote_data_source.dart';
import '../repositories/privacy_repository_impl.dart';

/// The anonymous-profile routes live outside `auth:sanctum`, but they still
/// share the app's single Dio; composing them here keeps the data source out
/// of presentation.
final privacyRemoteDataSourceProvider = Provider<PrivacyRemoteDataSource>((ref) {
  return PrivacyRemoteDataSource(ref.watch(dioProvider));
});

final privacyRepositoryProvider = Provider<PrivacyRepository>((ref) {
  return PrivacyRepositoryImpl(ref.watch(privacyRemoteDataSourceProvider));
});

/// Null is a distinct state: the response had no visitor id, which is not the
/// same claim as "the server holds nothing".
final visitorDataProvider = FutureProvider<VisitorData?>((ref) {
  return ref.watch(privacyRepositoryProvider).getVisitorData();
});
