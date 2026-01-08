import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ui/view/reviews/data/model/reviews_model.dart';
import 'package:ui/view/reviews/data/repository/reviews_repository.dart';

part 'reviews_event.dart';
part 'reviews_state.dart';

class ReviewsBloc extends Bloc<ReviewsEvent, ReviewsState> {
  final ReviewsRepository _reviewsRepository;

  ReviewsBloc({required ReviewsRepository reviewsRepository})
    : _reviewsRepository = reviewsRepository,
      super(ReviewsInitial()) {
    on<LoadReviews>(_onLoadReviews);
  }

  Future<void> _onLoadReviews(
    LoadReviews event,
    Emitter<ReviewsState> emit,
  ) async {
    emit(ReviewsLoading());
    try {
      final reviews = await _reviewsRepository.fetchReviews();
      emit(ReviewsLoaded(reviews));
    } catch (e) {
      emit(ReviewsError(e.toString()));
    }
  }
}
