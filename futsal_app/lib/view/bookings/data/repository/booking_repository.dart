import 'package:dio/dio.dart';
import 'package:ui/core/service/api_const.dart';
import 'package:ui/core/service/api_service.dart';
import '../model/booking.dart';

class BookingRepository {
  final ApiService _api = ApiService();

  Future<List<Booking>> getBookings() async {
    try {
      final res = await _api.get(ApiConst.bookings);
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is List) {
          return data
              .map((e) => Booking.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((e) => Booking.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load bookings: ${res.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to load bookings',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Create a new booking
  Future<void> createBooking({
    required String userId,
    required int groundId,
    required DateTime bookingDate,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final bookingData = {
        'userId': userId,
        'groundId': groundId,
        'bookingDate': bookingDate.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
      };

      final res = await _api.post(ApiConst.bookings, data: bookingData);

      if (res.statusCode == 200 || res.statusCode == 201) {
        // Booking successful - response format may vary
        return;
      } else {
        throw Exception('Failed to create booking: ${res.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to create booking',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
