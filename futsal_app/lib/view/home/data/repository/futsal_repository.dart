import 'package:ui/core/service/api_service.dart';
import 'package:ui/core/service/api_const.dart';
import 'package:ui/view/home/data/model/futsal_model.dart';

class FutsalRepository {
  final ApiService _apiService;

  FutsalRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  // Get all futsal grounds
  Future<List<FutsalModel>> getAllFutsals() async {
    try {
      final response = await _apiService.get(ApiConst.futsal);

      if (response.data is List) {
        return (response.data as List)
            .map((json) => FutsalModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw ApiException('Invalid response format');
    } catch (e) {
      throw ApiException('Failed to fetch futsals: ${e.toString()}');
    }
  }

  // Get trending futsal grounds
  Future<List<FutsalModel>> getTrendingFutsals() async {
    try {
      final response = await _apiService.get(ApiConst.trendingFutsal);

      if (response.data is List) {
        return (response.data as List)
            .map((json) => FutsalModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw ApiException('Invalid response format');
    } catch (e) {
      throw ApiException('Failed to fetch trending futsals: ${e.toString()}');
    }
  }

  // Get top-reviewed futsal grounds
  Future<List<FutsalModel>> getTopReviewedFutsals() async {
    try {
      final response = await _apiService.get(ApiConst.topReviewedFutsal);

      if (response.data is List) {
        return (response.data as List)
            .map((json) => FutsalModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw ApiException('Invalid response format');
    } catch (e) {
      throw ApiException(
        'Failed to fetch top-reviewed futsals: ${e.toString()}',
      );
    }
  }

  // Get favorite futsal grounds
  Future<List<FutsalModel>> getFavoriteFutsals() async {
    try {
      final response = await _apiService.get(ApiConst.getFavoritesFutsal);

      if (response.data is List) {
        return (response.data as List)
            .map((json) => FutsalModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw ApiException('Invalid response format');
    } catch (e) {
      throw ApiException('Failed to fetch favorite futsals: ${e.toString()}');
    }
  }
}
