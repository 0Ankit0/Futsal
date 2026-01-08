import 'package:ui/core/service/api_const.dart';
import 'package:ui/core/service/api_service.dart';
import 'package:ui/view/reviews/data/model/reviews_model.dart';
import 'package:ui/view/reviews/data/model/review_request.dart';

class ReviewsRepository {
  final ApiService _apiService;

  ReviewsRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<List<ReviewsModel>> fetchReviews() async {
    try {
      final response = await _apiService.get(ApiConst.reviews);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ReviewsModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      throw Exception('Failed to load reviews: $e');
    }
  }

  Future<int> createReview(ReviewRequest reviewRequest) async {
    try {
      final response = await _apiService.post(
        ApiConst.reviews,
        data: reviewRequest.toJson(),
      );
      if (response.statusCode == 200) {
        return response.data as int;
      } else {
        throw Exception('Failed to create review');
      }
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }
}
