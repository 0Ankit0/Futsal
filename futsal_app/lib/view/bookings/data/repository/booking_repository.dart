import 'package:dio/dio.dart';
import 'package:ui/core/service/api_const.dart';
import 'package:ui/core/service/api_service.dart';
import '../model/booking.dart';

class BookingRepository {
  final ApiService _api = ApiService();

  /// GET /api/v1/futsal/bookings — current user's bookings
  Future<List<Booking>> getBookings({String? statusFilter}) async {
    try {
      final Map<String, dynamic> params = {};
      if (statusFilter != null) params['status_filter'] = statusFilter;

      final res = await _api.get(
        ApiConst.bookings,
        queryParameters: params.isEmpty ? null : params,
      );
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is List) {
          return data.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to load bookings');
    }
  }

  /// POST /api/v1/futsal/bookings — create a booking
  Future<Booking> createBooking({
    required int groundId,
    required String bookingDate, // YYYY-MM-DD
    required String startTime, // HH:mm
    required String endTime,
    String? teamName,
    String? notes,
    int loyaltyPointsToRedeem = 0,
  }) async {
    try {
      final res = await _api.post(
        ApiConst.bookings,
        data: {
          'ground_id': groundId,
          'booking_date': bookingDate,
          'start_time': startTime,
          'end_time': endTime,
          if (teamName != null) 'team_name': teamName,
          if (notes != null) 'notes': notes,
          'loyalty_points_to_redeem': loyaltyPointsToRedeem,
        },
      );
      return Booking.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] as String?;
      throw Exception(detail ?? 'Failed to create booking');
    }
  }

  /// PATCH /api/v1/futsal/bookings/{id}/cancel
  Future<Booking> cancelBooking(int bookingId, {String? reason}) async {
    try {
      final res = await _api.patch(
        ApiConst.cancelBooking(bookingId),
        data: reason != null ? {'reason': reason} : null,
      );
      return Booking.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to cancel booking');
    }
  }

  /// GET /api/v1/futsal/bookings/{id}
  Future<Booking> getBookingById(int bookingId) async {
    try {
      final res = await _api.get(ApiConst.bookingDetail(bookingId));
      return Booking.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to fetch booking');
    }
  }
}
