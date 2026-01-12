import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  bookingConfirmed,
  bookingReminder,
  bookingCancelled,
  bookingCompleted,
  reviewReminder,
  paymentSuccess,
  paymentFailed,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final List<VoidCallback> _listeners = [];

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Initialize notification settings
    if (kDebugMode) {
      print('Notification Service Initialized');
    }
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> showNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
      data: data ?? {},
    );

    _notifications.insert(0, notification);
    _notifyListeners();

    if (kDebugMode) {
      print('Notification: $title - $body');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _notifyListeners();
  }

  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    _notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    _notifyListeners();
  }

  // Helper methods for specific notification types
  Future<void> showBookingConfirmed({
    required String groundName,
    required String bookingDate,
    required String timeSlot,
    int? bookingId,
  }) async {
    await showNotification(
      title: 'Booking Confirmed! 🎉',
      body: '$groundName - $bookingDate at $timeSlot',
      type: NotificationType.bookingConfirmed,
      data: {'bookingId': bookingId},
    );
  }

  Future<void> showBookingReminder({
    required String groundName,
    required String timeSlot,
    int? bookingId,
  }) async {
    await showNotification(
      title: 'Upcoming Booking Reminder ⏰',
      body: 'Your booking at $groundName is coming up at $timeSlot',
      type: NotificationType.bookingReminder,
      data: {'bookingId': bookingId},
    );
  }

  Future<void> showBookingCancelled({
    required String groundName,
    required String bookingDate,
  }) async {
    await showNotification(
      title: 'Booking Cancelled',
      body: 'Your booking at $groundName on $bookingDate has been cancelled',
      type: NotificationType.bookingCancelled,
    );
  }

  Future<void> showBookingCompleted({
    required String groundName,
    int? bookingId,
  }) async {
    await showNotification(
      title: 'Booking Completed ✓',
      body: 'Your booking at $groundName has been completed',
      type: NotificationType.bookingCompleted,
      data: {'bookingId': bookingId},
    );
  }

  Future<void> showReviewReminder({
    required String groundName,
    required int groundId,
    int? bookingId,
  }) async {
    await showNotification(
      title: 'How was your experience? ⭐',
      body: 'Please rate your experience at $groundName',
      type: NotificationType.reviewReminder,
      data: {
        'groundId': groundId,
        'bookingId': bookingId,
        'groundName': groundName,
      },
    );
  }

  Future<void> showPaymentSuccess({
    required String groundName,
    required double amount,
  }) async {
    await showNotification(
      title: 'Payment Successful ✓',
      body: 'Rs. ${amount.toStringAsFixed(0)} paid for $groundName',
      type: NotificationType.paymentSuccess,
    );
  }

  Future<void> showPaymentFailed({required String groundName}) async {
    await showNotification(
      title: 'Payment Failed',
      body: 'Payment for $groundName could not be processed',
      type: NotificationType.paymentFailed,
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic> data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data = const {},
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.bookingConfirmed:
        return Icons.check_circle;
      case NotificationType.bookingReminder:
        return Icons.alarm;
      case NotificationType.bookingCancelled:
        return Icons.cancel;
      case NotificationType.bookingCompleted:
        return Icons.done_all;
      case NotificationType.reviewReminder:
        return Icons.rate_review;
      case NotificationType.paymentSuccess:
        return Icons.payment;
      case NotificationType.paymentFailed:
        return Icons.error_outline;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.bookingConfirmed:
        return Colors.green;
      case NotificationType.bookingReminder:
        return Colors.orange;
      case NotificationType.bookingCancelled:
        return Colors.red;
      case NotificationType.bookingCompleted:
        return Colors.blue;
      case NotificationType.reviewReminder:
        return Colors.amber;
      case NotificationType.paymentSuccess:
        return Colors.green;
      case NotificationType.paymentFailed:
        return Colors.red;
    }
  }
}
