import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/entities/psc.dart';
import '../../domain/repositories/psc_repository.dart';
import '../psc_remote_data_source.dart';
import '../repositories/psc_repository_impl.dart';

/// Data source and repository are composed here from the app's single Dio;
/// the screen no longer constructs either one.
final pscRemoteProvider = Provider<PscRemoteDataSource>((ref) {
  return PscRemoteDataSource(ref.watch(dioProvider));
});

final pscRepositoryProvider = Provider<PscRepository>((ref) {
  return PscRepositoryImpl(ref.watch(pscRemoteProvider));
});

/// The blueprint list as a provider so a failure is an error state rather
/// than an empty catalogue.
final pscBlueprintsProvider = FutureProvider<List<PscBlueprint>>((ref) {
  return ref.watch(pscRepositoryProvider).getBlueprints();
});
