import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/home_remote_data_source.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/home_repository.dart';

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  final dio = DioClient.instance.dio;
  return HomeRemoteDataSource(dio);
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final remote = ref.watch(homeRemoteDataSourceProvider);
  return HomeRepositoryImpl(remote);
});

class HomeNotifier extends AsyncNotifier<DashboardData> {
  @override
  FutureOr<DashboardData> build() async {
    final repo = ref.watch(homeRepositoryProvider);
    return repo.getDashboardData();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(homeRepositoryProvider);
      return repo.getDashboardData();
    });
  }
}

final homeControllerProvider =
    AsyncNotifierProvider<HomeNotifier, DashboardData>(HomeNotifier.new);
