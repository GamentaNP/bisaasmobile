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

  /// Completes a password reset using the one-time token from the reset email.
  ///
  /// Server contract (`MobilePasswordController::resetPassword`): all three
  /// fields are required, `password` is `min:8` + `confirmed`, and **every
  /// session and token is revoked on success** — so the caller must send the
  /// user back to sign-in rather than assuming they are still authenticated.
  /// Rejects a bad token as a 422 on `email`, not a 401, because the broker
  /// reports `passwords.user` that way.
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {
          'token': token,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
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

  /// Authenticated change. Revokes every OTHER device but keeps this one signed
  /// in, so no re-authentication is needed afterwards.
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
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
