import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/view/home/bloc/all_futsal/all_futsal_event.dart';
import 'package:ui/view/home/bloc/all_futsal/all_futsal_state.dart';
import 'package:ui/view/home/data/repository/futsal_repository.dart';

class AllFutsalBloc extends Bloc<AllFutsalEvent, AllFutsalState> {
  final FutsalRepository _futsalRepository;

  AllFutsalBloc({FutsalRepository? futsalRepository})
    : _futsalRepository = futsalRepository ?? FutsalRepository(),
      super(const AllFutsalInitial()) {
    on<LoadAllFutsals>(_onLoadAllFutsals);
  }

  Future<void> _onLoadAllFutsals(
    LoadAllFutsals event,
    Emitter<AllFutsalState> emit,
  ) async {
    emit(const AllFutsalLoading());

    try {
      final futsals = await _futsalRepository.getAllFutsals();
      emit(AllFutsalLoaded(futsals));
    } catch (e) {
      emit(AllFutsalError(e.toString()));
    }
  }
}
