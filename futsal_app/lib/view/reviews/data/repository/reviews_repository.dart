import 'package:ui/core/service/api_const.dart';
import 'package:ui/core/service/api_service.dart';
import 'package:ui/view/reviews/data/model/reviews_model.dart';
import 'package:ui/view/reviews/data/model/review_request.dart';

class ReviewsRepository {
  final ApiService _apiService;

  ReviewsRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// GET /api/v1/futsal/grounds/{groundId}/reviews
  Future<List<ReviewsModel>> fetchGroundReviews(int groundId) async {
    try {
      final response = await _apiService.get(ApiConst.groundReviews(groundId));
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data
            .map((j) => ReviewsModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load reviews: $e');
    }
  }

  /// POST /api/v1/futsal/grounds/{groundId}/reviews
  Future<ReviewsModel> createReview(int groundId, ReviewRequest reviewRequest) async {
    try {
      final response = await _apiService.post(
        ApiConst.createReview(groundId),
        data: reviewRequest.toJson(),
      );
      return ReviewsModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  /// DELETE /api/v1/futsal/reviews/{reviewId}
  Future<void> deleteReview(int reviewId) async {
    try {
      await _apiService.delete(ApiConst.reviewDetail(reviewId));
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }
}
