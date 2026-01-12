import 'package:equatable/equatable.dart';

class UserInfoModel extends Equatable {
  final String id;
  final String email;
  final bool isEmailConfirmed;
  final String? profileImageUrl;
  final String firstName;
  final String lastName;
  final String username;
  final String? phoneNumber;
  final bool isPhoneNumberConfirmed;
  final String totalBookings;
  final String totalFavorites;
  final String totalReviews;

  const UserInfoModel({
    required this.id,
    required this.email,
    required this.isEmailConfirmed,
    this.profileImageUrl,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.phoneNumber,
    required this.isPhoneNumberConfirmed,
    required this.totalBookings,
    required this.totalFavorites,
    required this.totalReviews,
  });

  // Get full image URL with base URL prepended
  String? get fullImageUrl {
    if (profileImageUrl == null || profileImageUrl!.isEmpty) {
      return null;
    }
    // If it's already a full URL, return as is
    if (profileImageUrl!.startsWith('http')) {
      return profileImageUrl;
    }
    // Otherwise prepend base URL
    return 'http://144.126.252.228:8080$profileImageUrl';
  }

  factory UserInfoModel.fromJson(Map<String, dynamic> json) {
    return UserInfoModel(
      id: json['id'] as String,
      email: json['email'] as String,
      isEmailConfirmed: json['isEmailConfirmed'] as bool,
      profileImageUrl: json['profileImageUrl'] as String?,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      username: json['username'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      isPhoneNumberConfirmed: json['isPhoneNumberConfirmed'] as bool,
      totalBookings: json['totalBookings']?.toString() ?? '0',
      totalFavorites: json['totalFavorites']?.toString() ?? '0',
      totalReviews: json['totalReviews']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'isEmailConfirmed': isEmailConfirmed,
      'profileImageUrl': profileImageUrl,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'phoneNumber': phoneNumber,
      'isPhoneNumberConfirmed': isPhoneNumberConfirmed,
      'totalBookings': totalBookings,
      'totalFavorites': totalFavorites,
      'totalReviews': totalReviews,
    };
  }

  @override
  List<Object?> get props => [
    id,
    email,
    isEmailConfirmed,
    profileImageUrl,
    firstName,
    lastName,
    username,
    phoneNumber,
    isPhoneNumberConfirmed,
    totalBookings,
    totalFavorites,
    totalReviews,
  ];
}
