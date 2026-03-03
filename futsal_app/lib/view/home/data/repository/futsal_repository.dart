import 'package:ui/core/service/api_service.dart';
import 'package:ui/core/service/api_const.dart';
import 'package:ui/view/home/data/model/futsal_model.dart';

class FutsalRepository {
  final ApiService _apiService;

  FutsalRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// GET /api/v1/futsal/grounds — full ground list
  Future<List<FutsalModel>> getAllFutsals({
    String? search,
    String? groundType,
    double? maxPrice,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (groundType != null) params['ground_type'] = groundType;
      if (maxPrice != null) params['max_price'] = maxPrice.toString();

      final response = await _apiService.get(
        ApiConst.grounds,
        queryParameters: params.isEmpty ? null : params,
      );

      if (response.data is List) {
        return (response.data as List)
            .map((j) => FutsalModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      throw ApiException('Invalid response format');
    } catch (e) {
      throw ApiException('Failed to fetch grounds: $e');
    }
  }

  /// GET /api/v1/futsal/grounds/{id}
  Future<FutsalModel> getGroundById(int groundId) async {
    try {
      final response = await _apiService.get(ApiConst.groundDetail(groundId));
      return FutsalModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException('Failed to fetch ground details: $e');
    }
  }

  /// GET /api/v1/futsal/grounds/{id}/slots?date=YYYY-MM-DD
  Future<List<SlotModel>> getGroundSlots(int groundId, DateTime date) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _apiService.get(
        ApiConst.groundSlots(groundId),
        queryParameters: {'date': dateStr},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((j) => SlotModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiException('Failed to fetch slots: $e');
    }
  }

  // Trending — filter client-side from the full list by rating
  Future<List<FutsalModel>> getTrendingFutsals() async {
    final all = await getAllFutsals();
    final sorted = List<FutsalModel>.from(all)
      ..sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
    return sorted.take(10).toList();
  }

  // Top-reviewed — sort by averageRating
  Future<List<FutsalModel>> getTopReviewedFutsals() async {
    final all = await getAllFutsals();
    final sorted = List<FutsalModel>.from(all)
      ..sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return sorted.take(10).toList();
  }

  /// GET /api/v1/futsal/favourites
  Future<List<FutsalModel>> getFavoriteFutsals() async {
    try {
      final response = await _apiService.get(ApiConst.favourites);
      if (response.data is List) {
        return (response.data as List)
            .map((j) => FutsalModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiException('Failed to fetch favourites: $e');
    }
  }
}
