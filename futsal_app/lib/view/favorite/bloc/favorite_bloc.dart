import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/view/favorite/bloc/favorite_event.dart';
import 'package:ui/view/favorite/bloc/favorite_state.dart';
import 'package:ui/view/favorite/data/repository/favorite_repository.dart';

class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  final FavoriteRepository _favoriteRepository;

  FavoriteBloc({FavoriteRepository? favoriteRepository})
    : _favoriteRepository = favoriteRepository ?? FavoriteRepository(),
      super(const FavoriteInitial()) {
    // Register event handlers
    on<LoadFavorites>(_onLoadFavorites);
    on<AddToFavorites>(_onAddToFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
  }

  // Load favorite futsals
  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<FavoriteState> emit,
  ) async {
    emit(const FavoriteLoading());

    try {
      final favorites = await _favoriteRepository.getFavoriteFutsals();
      emit(FavoriteLoaded(favorites));
    } catch (e) {
      emit(FavoriteError(e.toString()));
    }
  }

  // Add futsal to favorites
  Future<void> _onAddToFavorites(
    AddToFavorites event,
    Emitter<FavoriteState> emit,
  ) async {
    try {
      await _favoriteRepository.addToFavorites(event.futsalId);

      // Reload favorites after adding
      final favorites = await _favoriteRepository.getFavoriteFutsals();
      emit(FavoriteActionSuccess('Added to favorites', favorites));
    } catch (e) {
      emit(FavoriteError(e.toString()));
    }
  }

  // Remove futsal from favorites
  Future<void> _onRemoveFromFavorites(
    RemoveFromFavorites event,
    Emitter<FavoriteState> emit,
  ) async {
    try {
      await _favoriteRepository.removeFromFavorites(event.futsalId);

      // Reload favorites after removing
      final favorites = await _favoriteRepository.getFavoriteFutsals();
      emit(FavoriteActionSuccess('Removed from favorites', favorites));
    } catch (e) {
      emit(FavoriteError(e.toString()));
    }
  }
}
