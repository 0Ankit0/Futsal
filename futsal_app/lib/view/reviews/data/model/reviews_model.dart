class ReviewsModel {
  int? id;
  String? userId;
  String? userName;
  int? userImageId;
  int? reviewImageId;
  String? reviewImageUrl;
  int? groundId;
  int? rating;
  String? comment;
  String? createdAt;

  ReviewsModel({
    this.id,
    this.userId,
    this.userName,
    this.userImageId,
    this.reviewImageId,
    this.reviewImageUrl,
    this.groundId,
    this.rating,
    this.comment,
    this.createdAt,
  });

  ReviewsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    userName = json['userName'];
    userImageId = json['userImageId'];
    reviewImageId = json['reviewImageId'];
    reviewImageUrl = json['reviewImageUrl'];
    groundId = json['groundId'];
    rating = json['rating'];
    comment = json['comment'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['userId'] = userId;
    data['userName'] = userName;
    data['userImageId'] = userImageId;
    data['reviewImageId'] = reviewImageId;
    data['reviewImageUrl'] = reviewImageUrl;
    data['groundId'] = groundId;
    data['rating'] = rating;
    data['comment'] = comment;
    data['createdAt'] = createdAt;
    return data;
  }
}
