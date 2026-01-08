import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/view/home/bloc/top_reviewed_futsal/top_reviewed_futsal_event.dart';
import 'package:ui/view/home/bloc/top_reviewed_futsal/top_reviewed_futsal_state.dart';
import 'package:ui/view/home/data/repository/futsal_repository.dart';

class TopReviewedFutsalBloc
    extends Bloc<TopReviewedFutsalEvent, TopReviewedFutsalState> {
  final FutsalRepository _futsalRepository;

  TopReviewedFutsalBloc({FutsalRepository? futsalRepository})
    : _futsalRepository = futsalRepository ?? FutsalRepository(),
      super(const TopReviewedFutsalInitial()) {
    on<LoadTopReviewedFutsals>(_onLoadTopReviewedFutsals);
  }

  Future<void> _onLoadTopReviewedFutsals(
    LoadTopReviewedFutsals event,
    Emitter<TopReviewedFutsalState> emit,
  ) async {
    emit(const TopReviewedFutsalLoading());

    try {
      final futsals = await _futsalRepository.getTopReviewedFutsals();
      emit(TopReviewedFutsalLoaded(futsals));
    } catch (e) {
      emit(TopReviewedFutsalError(e.toString()));
    }
  }
}
