part of 'reviews_bloc.dart';

abstract class ReviewsState extends Equatable {
  const ReviewsState();

  @override
  List<Object> get props => [];
}

class ReviewsInitial extends ReviewsState {}

class ReviewsLoading extends ReviewsState {}

class ReviewsLoaded extends ReviewsState {
  final List<ReviewsModel> reviews;

  const ReviewsLoaded(this.reviews);

  @override
  List<Object> get props => [reviews];
}

class ReviewsError extends ReviewsState {
  final String message;

  const ReviewsError(this.message);

  @override
  List<Object> get props => [message];
}
