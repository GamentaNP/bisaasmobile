/// Auth repository — talks to `POST /api/v1/auth/*` only via DioClient.
/// Never builds URLs manually beyond ApiConfig.
library;

import 'package:dio/dio.dart';

class AuthRepository {
  AuthRepository(this._dio);
  final Dio _dio;

  /// POST /auth/login {email, password, device_name}
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password, 'device_name': deviceName},
    );
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'device_name': deviceName,
      },
    );
    return res.data!['data'] as Map<String, dynamic>;
  }

  /// POST /auth/refresh with X-Device-Name header (handled by DioClient)
  Future<Map<String, dynamic>> refresh() async {
    final res = await _dio.post<Map<String, dynamic>>('/auth/refresh');
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }
}
