import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_response.dart';
import '../models/skill_axes_dto.dart';

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._dio);
  final Dio _dio;

  /// `GET /profile/skills` — per-category graded accuracy axes.
  Future<List<SkillAxis>> getSkills() async {
    final res = await _dio.get<Map<String, dynamic>>('/profile/skills');
    final envelope = ApiResponse.fromJson(res.data!, (json) => json);
    final data = envelope.data;
    final axes = (data is Map<String, dynamic> ? data['axes'] : null) as List? ?? const [];
    return axes.cast<Map<String, dynamic>>().map(SkillAxis.fromJson).toList();
  }

  /// `POST /me/avatar` — multipart upload; returns the resolved avatar URL.
  Future<String> uploadAvatar(XFile file) async {
    final form = FormData.fromMap(<String, dynamic>{
      'avatar': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    final res = await _dio.post<Map<String, dynamic>>('/me/avatar', data: form);
    final envelope = ApiResponse.fromJson(res.data!, (json) => json);
    final data = envelope.data;
    return data is Map<String, dynamic> ? ((data['avatar_url'] as String?) ?? '') : '';
  }
}
