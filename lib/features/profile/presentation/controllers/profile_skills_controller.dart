import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/models/skill_axes_dto.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(ref.watch(dioProvider));
});

/// Radar axes from `GET /profile/skills`. Empty list = no graded answers yet.
final profileSkillsProvider = FutureProvider<List<SkillAxis>>((ref) async {
  return ref.watch(profileRemoteDataSourceProvider).getSkills();
});
