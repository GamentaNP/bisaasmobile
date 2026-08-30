import 'user_dto.dart';

class AuthResponseDto {
  const AuthResponseDto({
    required this.token,
    this.tokenType = 'Bearer',
    this.expiresAt,
    this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      token: json['token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresAt: json['expires_at'] as String?,
      user: json['user'] != null
          ? UserDto.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  final String token;
  final String tokenType;
  final String? expiresAt;
  final UserDto? user;

  Map<String, dynamic> toJson() => {
        'token': token,
        'token_type': tokenType,
        'expires_at': expiresAt,
        'user': user?.toJson(),
      };
}
