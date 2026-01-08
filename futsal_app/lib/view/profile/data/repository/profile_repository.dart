import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ui/core/service/api_const.dart';
import 'package:ui/core/service/api_service.dart';
import '../model/user_info_model.dart';

class ProfileRepository {
  final ApiService _apiService = ApiService();

  /// Fetch user info from the server
  Future<UserInfoModel> getUserInfo() async {
    try {
      final response = await _apiService.get(ApiConst.userInfo);

      if (response.statusCode == 200) {
        return UserInfoModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load user info: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to load user info',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Upload image to server
  Future<int> uploadImage(File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _apiService.post(
        ApiConst.uploadImage,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['id'] as int;
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to upload image',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update user info (only sends changed fields)
  Future<void> updateUserInfo(Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.post(ApiConst.userInfo, data: updates);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update user info: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to update user info',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Change user password via the same user info endpoint
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConst.userInfo,
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to change password: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to change password',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
