import 'package:equatable/equatable.dart';
import 'package:ui/view/home/data/model/futsal_model.dart';

abstract class TopReviewedFutsalState extends Equatable {
  const TopReviewedFutsalState();

  @override
  List<Object?> get props => [];
}

// Initial state
class TopReviewedFutsalInitial extends TopReviewedFutsalState {
  const TopReviewedFutsalInitial();
}

// Loading state
class TopReviewedFutsalLoading extends TopReviewedFutsalState {
  const TopReviewedFutsalLoading();
}

// Loaded state
class TopReviewedFutsalLoaded extends TopReviewedFutsalState {
  final List<FutsalModel> futsals;

  const TopReviewedFutsalLoaded(this.futsals);

  @override
  List<Object?> get props => [futsals];
}

// Error state
class TopReviewedFutsalError extends TopReviewedFutsalState {
  final String message;

  const TopReviewedFutsalError(this.message);

  @override
  List<Object?> get props => [message];
}
