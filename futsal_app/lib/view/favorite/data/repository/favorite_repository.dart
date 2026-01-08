import 'package:ui/core/service/api_service.dart';
import 'package:ui/core/service/api_const.dart';
import 'package:ui/view/home/data/model/futsal_model.dart';

class FavoriteRepository {
  final ApiService _apiService = ApiService();

  // Get all favorite futsals
  Future<List<FutsalModel>> getFavoriteFutsals() async {
    try {
      final response = await _apiService.get(ApiConst.getFavoritesFutsal);

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => FutsalModel.fromJson(json)).toList();
    } catch (e) {
      throw ApiException('Failed to load favorite futsals: ${e.toString()}');
    }
  }

  // Add futsal to favorites (if you have this endpoint)
  Future<void> addToFavorites(int futsalId) async {
    try {
      await _apiService.post('${ApiConst.manageFavoriteFutsal}/$futsalId');
    } catch (e) {
      throw ApiException('Failed to add to favorites: ${e.toString()}');
    }
  }

  // Remove futsal from favorites (if you have this endpoint)
  Future<void> removeFromFavorites(int futsalId) async {
    try {
      await _apiService.delete('${ApiConst.manageFavoriteFutsal}/$futsalId');
    } catch (e) {
      throw ApiException('Failed to remove from favorites: ${e.toString()}');
    }
  }
}
