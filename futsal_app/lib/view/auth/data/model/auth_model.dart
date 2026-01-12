class AuthResponseModel {
  final String tokenType;
  final String accessToken;
  final int expiresIn;
  final String refreshToken;

  AuthResponseModel({
    required this.tokenType,
    required this.accessToken,
    required this.expiresIn,
    required this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      tokenType: json['tokenType'] as String,
      accessToken: json['accessToken'] as String,
      expiresIn: json['expiresIn'] as int,
      refreshToken: json['refreshToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tokenType': tokenType,
      'accessToken': accessToken,
      'expiresIn': expiresIn,
      'refreshToken': refreshToken,
    };
  }

  // Calculate expiry timestamp (current time + expiresIn seconds)
  DateTime get expiryTime {
    return DateTime.now().add(Duration(seconds: expiresIn));
  }
}
