class Booking {
  final int id;
  final String userId;
  final int groundId;
  final DateTime bookingDate;
  final String startTime; // assuming HH:mm or full string from API
  final String endTime;
  final int status; // 0=pending,1=confirmed,2=cancelled etc.
  final double totalAmount;
  final DateTime createdAt;
  final String groundName;

  Booking({
    required this.id,
    required this.userId,
    required this.groundId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.groundName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? '',
      groundId: json['groundId'] ?? 0,
      bookingDate:
          DateTime.tryParse(json['bookingDate'] ?? '') ?? DateTime.now(),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      status: json['status'] ?? 0,
      totalAmount: (json['totalAmount'] is int)
          ? (json['totalAmount'] as int).toDouble()
          : (json['totalAmount'] is double)
          ? json['totalAmount']
          : 0.0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      groundName: json['groundName'] ?? '',
    );
  }
}
