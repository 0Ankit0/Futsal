import 'package:equatable/equatable.dart';
import 'package:ui/view/home/data/model/futsal_model.dart';

abstract class AllFutsalState extends Equatable {
  const AllFutsalState();

  @override
  List<Object?> get props => [];
}

// Initial state
class AllFutsalInitial extends AllFutsalState {
  const AllFutsalInitial();
}

// Loading state
class AllFutsalLoading extends AllFutsalState {
  const AllFutsalLoading();
}

// Loaded state
class AllFutsalLoaded extends AllFutsalState {
  final List<FutsalModel> futsals;

  const AllFutsalLoaded(this.futsals);

  @override
  List<Object?> get props => [futsals];
}

// Error state
class AllFutsalError extends AllFutsalState {
  final String message;

  const AllFutsalError(this.message);

  @override
  List<Object?> get props => [message];
}
