/// Matches FastAPI `BookingResponse` schema from `/api/v1/futsal/bookings`
class Booking {
  final int id;
  final int userId;
  final int groundId;
  final String bookingDate; // YYYY-MM-DD
  final String startTime; // HH:mm:ss
  final String endTime;
  final String status; // pending | confirmed | cancelled | completed
  final double totalAmount;
  final double paidAmount;
  final String? teamName;
  final String? notes;
  final String qrCode;
  final bool isRecurring;
  final String? recurringType;
  final String? cancellationReason;

  Booking({
    required this.id,
    required this.userId,
    required this.groundId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    this.teamName,
    this.notes,
    required this.qrCode,
    required this.isRecurring,
    this.recurringType,
    this.cancellationReason,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      groundId: json['ground_id'] as int? ?? 0,
      bookingDate: json['booking_date'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      teamName: json['team_name'] as String?,
      notes: json['notes'] as String?,
      qrCode: json['qr_code'] as String? ?? '',
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringType: json['recurring_type'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
    );
  }

  /// Convenience: whether the booking can still be cancelled
  bool get isCancellable => status == 'pending' || status == 'confirmed';

  /// Status label for display
  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return 'Pending';
    }
  }
}
