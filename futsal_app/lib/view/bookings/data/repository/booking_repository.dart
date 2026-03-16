import 'package:dio/dio.dart';
import 'package:ui/core/service/api_const.dart';
import 'package:ui/core/service/api_service.dart';
import '../model/booking.dart';

class BookingRepository {
  final ApiService _api = ApiService();

  Future<List<Booking>> getBookings({String? path}) async {
    try {
      final res = await _api.get(path ?? ApiConst.bookings);
      if (res.statusCode == 200) {
        return _parseBookingsResponse(res.data);
      }
      throw Exception('Failed to load bookings: ${res.statusCode}');
    } catch (e) {
      throw _mapException(e, fallback: 'Failed to load bookings.');
    }
  }

  Future<List<Booking>> getPendingBookings() {
    return getBookings(path: ApiConst.pendingBookings);
  }

  Future<List<Booking>> getCompletedBookings() {
    return getBookings(path: ApiConst.completedBookings);
  }

  Future<List<Booking>> getCancelledBookings() {
    return getBookings(path: ApiConst.cancelledBookings);
  }

  Future<void> cancelBooking(int bookingId) async {
    try {
      final res = await _api.patch(ApiConst.cancelBooking(bookingId));
      if (res.statusCode == 200 || res.statusCode == 204) {
        return;
      }
      throw Exception('Failed to cancel booking.');
    } catch (e) {
      throw _mapException(e, fallback: 'Unable to cancel booking right now.');
    }
  }

  Future<void> acceptBooking(int bookingId) async {
    try {
      final res = await _api.patch(ApiConst.acceptBooking(bookingId));
      if (res.statusCode == 200 || res.statusCode == 204) {
        return;
      }
      throw Exception('Failed to accept booking.');
    } catch (e) {
      throw _mapException(e, fallback: 'Unable to accept booking right now.');
    }
  }

  /// Create a new booking
  Future<void> createBooking({
    required int groundId,
    required DateTime bookingDate,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final bookingData = {
        'groundId': groundId,
        'bookingDate': bookingDate.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
      };

      final res = await _api.post(ApiConst.bookings, data: bookingData);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return;
      }
      throw Exception('Failed to create booking: ${res.statusCode}');
    } catch (e) {
      throw _mapException(e, fallback: 'Unable to create booking right now.');
    }
  }

  List<Booking> _parseBookingsResponse(dynamic data) {
    if (data is List) {
      return data.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
    }

    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Exception _mapException(Object error, {required String fallback}) {
    if (error is ApiException) {
      return BookingRepositoryException(
        message: _friendlyStatusMessage(error.statusCode, fallback),
        statusCode: error.statusCode,
      );
    }

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      return BookingRepositoryException(
        message: _friendlyStatusMessage(statusCode, fallback),
        statusCode: statusCode,
      );
    }

    if (error is BookingRepositoryException) {
      return error;
    }

    return BookingRepositoryException(message: fallback);
  }

  String _friendlyStatusMessage(int? statusCode, String fallback) {
    switch (statusCode) {
      case 400:
        return 'Invalid booking request. Please review details and try again.';
      case 401:
        return 'Your session has expired. Please login again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'Booking not found. It may have already been updated.';
      default:
        return fallback;
    }
  }
}

class BookingRepositoryException implements Exception {
  final String message;
  final int? statusCode;

  BookingRepositoryException({required this.message, this.statusCode});

  @override
  String toString() => message;
}
