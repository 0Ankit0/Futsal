class ReviewRequest {
  final int groundId;
  final int rating;
  final String? comment;
  final int? imageId;

  ReviewRequest({
    required this.groundId,
    required this.rating,
    this.comment,
    this.imageId,
  });

  Map<String, dynamic> toJson() {
    return {
      'groundId': groundId,
      'rating': rating,
      'comment': comment,
      'imageId': imageId,
    };
  }
}
