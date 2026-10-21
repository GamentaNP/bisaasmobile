import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_failure.dart';
import '../../../../core/network/api_response.dart';
import '../models/auth_response_dto.dart';
import '../models/user_dto.dart';
import 'social_sign_in_gateway.dart';

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

  /// Rotates the current single-use PAT before it expires. The interceptor
  /// handles emergency 401 rotation; this method is used on cold start so a
  /// healthy session is not allowed to drift into an avoidable expiry window.
  Future<AuthResponseDto> refresh({required String deviceName}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        options: Options(headers: {'X-Device-Name': deviceName}),
      );
      final envelope = ApiResponse.fromJson(
        res.data!,
        (json) => AuthResponseDto.fromJson(json! as Map<String, dynamic>),
      );
      if (envelope.data == null) {
        throw ApiException(
          statusCode: res.statusCode ?? 500,
          code: ApiErrorCode.unknown,
          message: envelope.message ?? 'Token refresh failed',
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
        message: e.message ?? 'Network error during token refresh',
      );
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
      // A 401 is a real answer: the token is not (or no longer) valid, so
      // the caller is signed out. Every other failure is an *unknown*, and an
      // unknown must not be reported as "signed out" — that dumps the user on
      // the login screen every time the network hiccups.
      if (e.response?.statusCode == 401) return null;
      if (e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(
          e.response?.statusCode ?? 500,
          e.response!.data as Map<String, dynamic>,
          requestId: e.requestOptions.headers['X-Request-Id'] as String?,
        );
      }
      // No response at all: a transport failure. Surface it as an error so
      // the app can show the cached session (or a retry) instead of
      // pretending nobody is signed in.
      throw toApiException(e);
    }
  }

  // ── Social sign-in ──────────────────────────────────────────────────────────

  /// Signs in with a Google id_token.
  ///
  /// `POST /api/v1/auth/social/google {id_token}`. The server verifies the
  /// token with Socialite in stateless mode and mints the same bearer PAT the
  /// password flow returns, so the client stores it identically.
  Future<AuthResponseDto> loginWithGoogle({required String idToken}) {
    return _socialLogin(
      provider: SocialProvider.google,
      idToken: idToken,
      extra: const {},
    );
  }

  /// Signs in with an Apple id_token.
  ///
  /// `POST /api/v1/auth/social/apple {id_token, name?}`. Apple returns the
  /// user's name only on the very first authorisation, so [name] is forwarded
  /// when the platform gave one and omitted otherwise.
  Future<AuthResponseDto> loginWithApple({
    required String idToken,
    String? name,
  }) {
    return _socialLogin(
      provider: SocialProvider.apple,
      idToken: idToken,
      extra: {
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      },
    );
  }

  Future<AuthResponseDto> _socialLogin({
    required SocialProvider provider,
    required String idToken,
    required Map<String, dynamic> extra,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        provider.endpoint,
        data: <String, dynamic>{'id_token': idToken, ...extra},
      );
      final envelope = ApiResponse.fromJson(
        res.data!,
        (json) => AuthResponseDto.fromJson(json! as Map<String, dynamic>),
      );
      if (envelope.data == null) {
        throw ApiException(
          statusCode: res.statusCode ?? 500,
          code: ApiErrorCode.authSocialFailed,
          message: envelope.message ?? 'Social sign-in failed',
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
        message: e.message ?? 'Network error during social sign-in',
      );
    }
  }

  // ── Email verification ──────────────────────────────────────────────────────

  /// Resends the account-verification email.
  ///
  /// `POST /api/v1/auth/email/verification-notification` — authenticated
  /// (the caller already has a token) and throttled by the server. The
  /// server answers 200 whether or not the address still needs verifying, so
  /// this never leaks account state.
  Future<void> resendVerificationEmail() async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/email/verification-notification',
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
