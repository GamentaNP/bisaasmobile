import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/repositories/numerical_repository.dart';
import '../datasources/numerical_remote_data_source.dart';
import '../repositories/numerical_repository_impl.dart';

/// Kept under its original public name: the widget test overrides this with a
/// mock data source, and the repository below wraps that same instance.
final numericalRemoteDataSourceProvider = Provider<NumericalRemoteDataSource>(
  (ref) => NumericalRemoteDataSource(ref.watch(dioProvider)),
);

final numericalRepositoryProvider = Provider<NumericalRepository>((ref) {
  return NumericalRepositoryImpl(ref.watch(numericalRemoteDataSourceProvider));
});
