import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../models/skill_axes_dto.dart';

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._dio);
  final Dio _dio;

  /// `GET /profile/skills` — per-category graded accuracy axes.
  Future<List<SkillAxis>> getSkills() async {
    const endpoint = '/profile/skills';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final data = requireDataMap(res.data, endpoint: endpoint);
    final axes = data['axes'];
    if (axes is! List) {
      // A missing `axes` list is drift, not "the user has no skill axes".
      throw const ContractViolation(
        'Expected `axes` to be an array',
        endpoint: endpoint,
      );
    }
    final out = <SkillAxis>[];
    for (final axis in axes) {
      if (axis is! Map<String, dynamic>) {
        throw const ContractViolation(
          'Expected each skill axis to be an object',
          endpoint: endpoint,
        );
      }
      out.add(SkillAxis.fromJson(axis));
    }
    return out;
  }

  /// `POST /me/avatar` — multipart upload; returns the resolved avatar URL.
  Future<String> uploadAvatar(XFile file) async {
    final form = FormData.fromMap(<String, dynamic>{
      'avatar': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    const endpoint = '/me/avatar';
    final res = await _dio.post<Map<String, dynamic>>(endpoint, data: form);
    final data = requireDataMap(res.data, endpoint: endpoint);
    final url = data['avatar_url'];
    if (url is! String || url.isEmpty) {
      throw const ContractViolation(
        'Avatar upload response missing `avatar_url`',
        endpoint: endpoint,
      );
    }
    return url;
  }

  /// `PATCH /me` — update editable profile fields (currently name). Server
  /// validates and returns the updated user; caller refreshes auth state.
  Future<void> updateProfile({String? name}) async {
    final payload = <String, dynamic>{
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    };
    if (payload.isEmpty) return;
    await _dio.patch<Map<String, dynamic>>('/me', data: payload);
  }

  /// `PATCH /me/locale` — persist the preferred locale server-side.
  ///
  /// `UpdateLocaleController` validates against `config('app.supported_locales')`
  /// = en, es, fr, ar, ne, hi, bn, ta, te, so an unsupported code is a 422
  /// rather than a silent write. The app only offers en/ne/hi, all of which are
  /// in that list.
  Future<void> updateLocale(String locale) async {
    await _dio.patch<Map<String, dynamic>>(
      '/me/locale',
      data: <String, dynamic>{'locale': locale},
    );
  }

  /// `PATCH /me` — persist the appearance choice server-side so it follows the
  /// account across reinstalls (the web app writes the same field). Callers
  /// treat failure as best-effort: a network error must never undo the local
  /// choice the user just made.
  Future<void> updateAppearance(String appearance) async {
    await _dio.patch<Map<String, dynamic>>(
      '/me',
      data: <String, dynamic>{'appearance': appearance},
    );
  }
}
