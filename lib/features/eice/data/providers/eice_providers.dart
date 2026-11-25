import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/repositories/eice_repository.dart';
import '../eice_remote_data_source.dart';
import '../repositories/eice_repository_impl.dart';

/// The data source is built here, at the feature's composition seam, from the
/// app's single Dio. Presentation never constructs one itself.
final eiceRemoteProvider = Provider<EiceRemoteDataSource>((ref) {
  return EiceRemoteDataSource(ref.watch(dioProvider));
});

final eiceRepositoryProvider = Provider<EiceRepository>((ref) {
  return EiceRepositoryImpl(ref.watch(eiceRemoteProvider));
});
