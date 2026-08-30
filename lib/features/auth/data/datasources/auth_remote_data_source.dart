import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../models/auth_response_dto.dart';
import '../models/user_dto.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<AuthResponseDto> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'device_name': deviceName,
        },
      );
      final envelope = ApiResponse.fromJson(
        res.data!,
        (json) => AuthResponseDto.fromJson(json! as Map<String, dynamic>),
      );
      if (envelope.data == null) {
        throw ApiException(
          statusCode: res.statusCode ?? 500,
          code: ApiErrorCode.unknown,
          message: envelope.message ?? 'Login failed',
        );
      }
      return envelope.data!;
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(
          e.response?.statusCode ?? 500,
          e.response!.data as Map<String, dynamic>,
          requestId: e.requestOptions.headers['X-Request-Id'] as String?,
        );
      }
      throw ApiException(
        statusCode: e.response?.statusCode ?? 500,
        code: ApiErrorCode.serviceUnavailable,
        message: e.message ?? 'Network error during login',
      );
    }
  }

  Future<AuthResponseDto> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String deviceName,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'device_name': deviceName,
        },
      );
      final envelope = ApiResponse.fromJson(
        res.data!,
        (json) => AuthResponseDto.fromJson(json! as Map<String, dynamic>),
      );
      if (envelope.data == null) {
        throw ApiException(
          statusCode: res.statusCode ?? 500,
          code: ApiErrorCode.unknown,
          message: envelope.message ?? 'Registration failed',
        );
      }
      return envelope.data!;
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(
          e.response?.statusCode ?? 500,
          e.response!.data as Map<String, dynamic>,
          requestId: e.requestOptions.headers['X-Request-Id'] as String?,
        );
      }
      throw ApiException(
        statusCode: e.response?.statusCode ?? 500,
        code: ApiErrorCode.serviceUnavailable,
        message: e.message ?? 'Network error during registration',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on DioException catch (_) {
      // Best-effort logout on server
    }
  }

  Future<UserDto?> getCurrentUser() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/me');
      final envelope = ApiResponse.fromJson(
        res.data!,
        (json) => UserDto.fromJson(json! as Map<String, dynamic>),
      );
      return envelope.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      if (e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(
          e.response?.statusCode ?? 500,
          e.response!.data as Map<String, dynamic>,
          requestId: e.requestOptions.headers['X-Request-Id'] as String?,
        );
      }
      return null;
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(
          e.response?.statusCode ?? 500,
          e.response!.data as Map<String, dynamic>,
          requestId: e.requestOptions.headers['X-Request-Id'] as String?,
        );
      }
      throw ApiException(
        statusCode: e.response?.statusCode ?? 500,
        code: ApiErrorCode.serviceUnavailable,
        message: e.message ?? 'Network error',
      );
    }
  }
}
