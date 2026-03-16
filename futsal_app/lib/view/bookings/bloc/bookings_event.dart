part of 'bookings_bloc.dart';

abstract class BookingsEvent extends Equatable {
  const BookingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadBookings extends BookingsEvent {
  const LoadBookings();
}

class CancelBookingRequested extends BookingsEvent {
  final Booking booking;

  const CancelBookingRequested(this.booking);

  @override
  List<Object?> get props => [booking.id];
}

class AcceptBookingRequested extends BookingsEvent {
  final Booking booking;

  const AcceptBookingRequested(this.booking);

  @override
  List<Object?> get props => [booking.id];
}
