part of 'bookings_bloc.dart';

enum BookingActionType { none, cancelled, accepted }

class BookingsState extends Equatable {
  final List<Booking> bookings;
  final bool isLoading;
  final int? processingBookingId;
  final String? errorMessage;
  final String? infoMessage;
  final BookingActionType lastActionType;
  final Booking? actionBooking;

  const BookingsState({
    this.bookings = const [],
    this.isLoading = false,
    this.processingBookingId,
    this.errorMessage,
    this.infoMessage,
    this.lastActionType = BookingActionType.none,
    this.actionBooking,
  });

  BookingsState copyWith({
    List<Booking>? bookings,
    bool? isLoading,
    int? processingBookingId,
    bool clearProcessingBookingId = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? infoMessage,
    bool clearInfoMessage = false,
    BookingActionType? lastActionType,
    Booking? actionBooking,
    bool clearActionBooking = false,
  }) {
    return BookingsState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      processingBookingId: clearProcessingBookingId
          ? null
          : (processingBookingId ?? this.processingBookingId),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfoMessage ? null : (infoMessage ?? this.infoMessage),
      lastActionType: lastActionType ?? this.lastActionType,
      actionBooking: clearActionBooking ? null : (actionBooking ?? this.actionBooking),
    );
  }

  @override
  List<Object?> get props => [
    bookings,
    isLoading,
    processingBookingId,
    errorMessage,
    infoMessage,
    lastActionType,
    actionBooking?.id,
    actionBooking?.status,
  ];
}
