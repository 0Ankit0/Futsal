/// Matches FastAPI `ReviewResponse` schema
class ReviewsModel {
  final int? id;
  final int? userId;
  final int? groundId;
  final int? bookingId;
  final int? rating;
  final String? comment;
  final String? imageUrl;
  final String? ownerReply;
  final bool isVerified;
  final String? createdAt;

  ReviewsModel({
    this.id,
    this.userId,
    this.groundId,
    this.bookingId,
    this.rating,
    this.comment,
    this.imageUrl,
    this.ownerReply,
    this.isVerified = false,
    this.createdAt,
  });

  factory ReviewsModel.fromJson(Map<String, dynamic> json) {
    return ReviewsModel(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      groundId: json['ground_id'] as int?,
      bookingId: json['booking_id'] as int?,
      rating: json['rating'] as int?,
      comment: json['comment'] as String?,
      imageUrl: json['image_url'] as String?,
      ownerReply: json['owner_reply'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ground_id': groundId,
      'booking_id': bookingId,
      'rating': rating,
      'comment': comment,
      'image_url': imageUrl,
      'owner_reply': ownerReply,
      'is_verified': isVerified,
      'created_at': createdAt,
    };
  }
}
