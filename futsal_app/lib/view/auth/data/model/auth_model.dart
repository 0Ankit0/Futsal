/// FastAPI Token response: {access, refresh, token_type}
class AuthResponseModel {
  final String tokenType;
  final String accessToken;
  final String refreshToken;

  const AuthResponseModel({
    required this.tokenType,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      tokenType: (json['token_type'] as String?) ?? 'bearer',
      accessToken: json['access'] as String,
      refreshToken: json['refresh'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token_type': tokenType,
      'access': accessToken,
      'refresh': refreshToken,
    };
  }
}
