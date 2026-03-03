/// Matches FastAPI `ReviewCreate` schema — POST /api/v1/futsal/grounds/{id}/reviews
class ReviewRequest {
  final int rating;
  final String? comment;
  final String? imageUrl;

  ReviewRequest({
    required this.rating,
    this.comment,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      if (comment != null) 'comment': comment,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}
