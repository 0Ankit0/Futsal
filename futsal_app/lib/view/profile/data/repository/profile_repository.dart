import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ui/core/service/api_const.dart';
import 'package:ui/core/service/api_service.dart';
import '../model/user_info_model.dart';

class ProfileRepository {
  final ApiService _apiService = ApiService();

  /// GET /api/v1/users/me
  Future<UserInfoModel> getUserInfo() async {
    try {
      final response = await _apiService.get(ApiConst.userInfo);
      return UserInfoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to load user info');
    }
  }

  /// PATCH /api/v1/users/me — update profile fields
  Future<UserInfoModel> updateUserInfo(Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.patch(
        ApiConst.userInfo,
        data: updates,
      );
      return UserInfoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update profile');
    }
  }

  /// POST /api/v1/users/me/avatar — upload avatar image
  Future<UserInfoModel> uploadAvatar(File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });
      final response = await _apiService.post(
        ApiConst.uploadAvatar,
        data: formData,
      );
      return UserInfoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to upload avatar');
    }
  }

  /// POST /api/v1/auth/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.post(
        ApiConst.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to change password');
    }
  }
}
