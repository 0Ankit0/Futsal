import 'package:equatable/equatable.dart';

abstract class TrendingFutsalEvent extends Equatable {
  const TrendingFutsalEvent();

  @override
  List<Object?> get props => [];
}

// Load trending futsals
class LoadTrendingFutsals extends TrendingFutsalEvent {
  const LoadTrendingFutsals();
}
