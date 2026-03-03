import 'package:equatable/equatable.dart';
import 'package:ui/core/service/api_const.dart';

/// Matches FastAPI `UserResponse` schema from `GET /api/v1/users/me`
class UserInfoModel extends Equatable {
  final String id; // Encoded hashid (string) or int stringified
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final bool isActive;
  final bool isSuperuser;
  final String? avatarUrl;

  const UserInfoModel({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.phone,
    required this.isActive,
    required this.isSuperuser,
    this.avatarUrl,
  });

  String get fullName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? username : parts.join(' ');
  }

  String? get fullAvatarUrl {
    if (avatarUrl == null || avatarUrl!.isEmpty) return null;
    if (avatarUrl!.startsWith('http')) return avatarUrl;
    return '${ApiConst.baseUrl}$avatarUrl';
  }

  /// Placeholder counts — populate from dedicated API calls if needed.
  int get totalBookings => 0;
  int get totalFavorites => 0;
  int get totalReviews => 0;

  factory UserInfoModel.fromJson(Map<String, dynamic> json) {
    return UserInfoModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isSuperuser: json['is_superuser'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'is_active': isActive,
      'is_superuser': isSuperuser,
      'avatar_url': avatarUrl,
    };
  }

  @override
  List<Object?> get props => [
    id, email, username, firstName, lastName, phone, isActive, isSuperuser, avatarUrl,
  ];
}
