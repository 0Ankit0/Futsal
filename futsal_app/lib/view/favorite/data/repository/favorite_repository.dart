import 'package:ui/core/service/api_const.dart';
import 'package:ui/core/service/api_service.dart';
import 'package:ui/view/home/data/model/futsal_model.dart';

class FavoriteRepository {
  final ApiService _apiService = ApiService();

  /// GET /api/v1/futsal/favourites
  Future<List<FutsalModel>> getFavoriteFutsals() async {
    try {
      final response = await _apiService.get(ApiConst.favourites);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((j) => FutsalModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiException('Failed to load favourites: $e');
    }
  }

  /// POST /api/v1/futsal/favourites/{groundId}
  Future<void> addToFavorites(int groundId) async {
    try {
      await _apiService.post(ApiConst.addFavourite(groundId));
    } catch (e) {
      throw ApiException('Failed to add to favourites: $e');
    }
  }

  /// DELETE /api/v1/futsal/favourites/{groundId}
  Future<void> removeFromFavorites(int groundId) async {
    try {
      await _apiService.delete(ApiConst.removeFavourite(groundId));
    } catch (e) {
      throw ApiException('Failed to remove from favourites: $e');
    }
  }
}
