import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ui/view/bookings/data/model/booking.dart';
import 'package:ui/view/bookings/data/repository/booking_repository.dart';

part 'bookings_event.dart';
part 'bookings_state.dart';

class BookingsBloc extends Bloc<BookingsEvent, BookingsState> {
  final BookingRepository _bookingRepository;

  BookingsBloc({required BookingRepository bookingRepository})
    : _bookingRepository = bookingRepository,
      super(const BookingsState()) {
    on<LoadBookings>(_onLoadBookings);
    on<CancelBookingRequested>(_onCancelBookingRequested);
    on<AcceptBookingRequested>(_onAcceptBookingRequested);
  }

  Future<void> _onLoadBookings(
    LoadBookings event,
    Emitter<BookingsState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
        clearInfoMessage: true,
        lastActionType: BookingActionType.none,
        clearActionBooking: true,
      ),
    );

    try {
      final bookings = await _bookingRepository.getBookings();
      emit(
        state.copyWith(
          bookings: bookings,
          isLoading: false,
          clearErrorMessage: true,
          clearInfoMessage: true,
          clearProcessingBookingId: true,
          lastActionType: BookingActionType.none,
          clearActionBooking: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
          clearProcessingBookingId: true,
          lastActionType: BookingActionType.none,
          clearActionBooking: true,
        ),
      );
    }
  }

  Future<void> _onCancelBookingRequested(
    CancelBookingRequested event,
    Emitter<BookingsState> emit,
  ) async {
    emit(
      state.copyWith(
        processingBookingId: event.booking.id,
        clearErrorMessage: true,
        clearInfoMessage: true,
      ),
    );

    try {
      await _bookingRepository.cancelBooking(event.booking.id);
      final refreshedBookings = await _bookingRepository.getBookings();

      emit(
        state.copyWith(
          bookings: refreshedBookings,
          clearProcessingBookingId: true,
          infoMessage: 'Booking cancelled successfully.',
          lastActionType: BookingActionType.cancelled,
          actionBooking: event.booking,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          clearProcessingBookingId: true,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
          lastActionType: BookingActionType.none,
          clearActionBooking: true,
        ),
      );
    }
  }

  Future<void> _onAcceptBookingRequested(
    AcceptBookingRequested event,
    Emitter<BookingsState> emit,
  ) async {
    emit(
      state.copyWith(
        processingBookingId: event.booking.id,
        clearErrorMessage: true,
        clearInfoMessage: true,
      ),
    );

    try {
      await _bookingRepository.acceptBooking(event.booking.id);
      final refreshedBookings = await _bookingRepository.getBookings();

      emit(
        state.copyWith(
          bookings: refreshedBookings,
          clearProcessingBookingId: true,
          infoMessage: 'Booking accepted successfully.',
          lastActionType: BookingActionType.accepted,
          actionBooking: event.booking,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          clearProcessingBookingId: true,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
          lastActionType: BookingActionType.none,
          clearActionBooking: true,
        ),
      );
    }
  }
}
