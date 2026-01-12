import 'package:equatable/equatable.dart';
import 'package:ui/view/home/data/model/futsal_model.dart';

abstract class TrendingFutsalState extends Equatable {
  const TrendingFutsalState();

  @override
  List<Object?> get props => [];
}

// Initial state
class TrendingFutsalInitial extends TrendingFutsalState {
  const TrendingFutsalInitial();
}

// Loading state
class TrendingFutsalLoading extends TrendingFutsalState {
  const TrendingFutsalLoading();
}

// Loaded state
class TrendingFutsalLoaded extends TrendingFutsalState {
  final List<FutsalModel> futsals;

  const TrendingFutsalLoaded(this.futsals);

  @override
  List<Object?> get props => [futsals];
}

// Error state
class TrendingFutsalError extends TrendingFutsalState {
  final String message;

  const TrendingFutsalError(this.message);

  @override
  List<Object?> get props => [message];
}
