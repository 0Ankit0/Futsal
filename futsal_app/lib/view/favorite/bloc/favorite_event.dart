import 'package:equatable/equatable.dart';

abstract class FavoriteEvent extends Equatable {
  const FavoriteEvent();

  @override
  List<Object?> get props => [];
}

// Load favorite futsals
class LoadFavorites extends FavoriteEvent {
  const LoadFavorites();
}

// Add futsal to favorites
class AddToFavorites extends FavoriteEvent {
  final int futsalId;

  const AddToFavorites(this.futsalId);

  @override
  List<Object?> get props => [futsalId];
}

// Remove futsal from favorites
class RemoveFromFavorites extends FavoriteEvent {
  final int futsalId;

  const RemoveFromFavorites(this.futsalId);

  @override
  List<Object?> get props => [futsalId];
}
