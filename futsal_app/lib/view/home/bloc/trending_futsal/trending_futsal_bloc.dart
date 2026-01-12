import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/view/home/bloc/trending_futsal/trending_futsal_event.dart';
import 'package:ui/view/home/bloc/trending_futsal/trending_futsal_state.dart';
import 'package:ui/view/home/data/repository/futsal_repository.dart';

class TrendingFutsalBloc
    extends Bloc<TrendingFutsalEvent, TrendingFutsalState> {
  final FutsalRepository _futsalRepository;

  TrendingFutsalBloc({FutsalRepository? futsalRepository})
    : _futsalRepository = futsalRepository ?? FutsalRepository(),
      super(const TrendingFutsalInitial()) {
    on<LoadTrendingFutsals>(_onLoadTrendingFutsals);
  }

  Future<void> _onLoadTrendingFutsals(
    LoadTrendingFutsals event,
    Emitter<TrendingFutsalState> emit,
  ) async {
    emit(const TrendingFutsalLoading());

    try {
      final futsals = await _futsalRepository.getTrendingFutsals();
      emit(TrendingFutsalLoaded(futsals));
    } catch (e) {
      emit(TrendingFutsalError(e.toString()));
    }
  }
}
