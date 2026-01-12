import 'package:equatable/equatable.dart';

abstract class AllFutsalEvent extends Equatable {
  const AllFutsalEvent();

  @override
  List<Object?> get props => [];
}

// Load all futsals
class LoadAllFutsals extends AllFutsalEvent {
  const LoadAllFutsals();
}
