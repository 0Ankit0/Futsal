import 'package:equatable/equatable.dart';

abstract class TopReviewedFutsalEvent extends Equatable {
  const TopReviewedFutsalEvent();

  @override
  List<Object?> get props => [];
}

// Load top reviewed futsals
class LoadTopReviewedFutsals extends TopReviewedFutsalEvent {
  const LoadTopReviewedFutsals();
}
