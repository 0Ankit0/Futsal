import 'package:equatable/equatable.dart';
import 'package:ui/view/home/data/model/futsal_model.dart';

abstract class FavoriteState extends Equatable {
  const FavoriteState();

  @override
  List<Object?> get props => [];
}

// Initial state
class FavoriteInitial extends FavoriteState {
  const FavoriteInitial();
}

// Loading state
class FavoriteLoading extends FavoriteState {
  const FavoriteLoading();
}

// Loaded state
class FavoriteLoaded extends FavoriteState {
  final List<FutsalModel> favorites;

  const FavoriteLoaded(this.favorites);

  @override
  List<Object?> get props => [favorites];
}

// Error state
class FavoriteError extends FavoriteState {
  final String message;

  const FavoriteError(this.message);

  @override
  List<Object?> get props => [message];
}

// Action success states (for add/remove)
class FavoriteActionSuccess extends FavoriteState {
  final String message;
  final List<FutsalModel> favorites;

  const FavoriteActionSuccess(this.message, this.favorites);

  @override
  List<Object?> get props => [message, favorites];
}
