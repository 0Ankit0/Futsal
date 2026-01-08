import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/dimension.dart';
import '../../core/service/notification_service.dart';
import '../bookings/bookings.dart';
import '../reviews/reviews.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onNotificationsChanged);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    final notifications = _notificationService.notifications;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: Dimension.font(20),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onSelected: (value) {
                if (value == 'markAllRead') {
                  _notificationService.markAllAsRead();
                } else if (value == 'clearAll') {
                  _showClearAllDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'markAllRead',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: Dimension.width(20)),
                      SizedBox(width: Dimension.width(12)),
                      const Text('Mark all as read'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clearAll',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: Dimension.width(20)),
                      SizedBox(width: Dimension.width(12)),
                      const Text('Clear all'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {});
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: Dimension.width(16),
                  vertical: Dimension.height(12),
                ),
                itemCount: notifications.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: Dimension.height(12)),
                itemBuilder: (context, index) {
                  return _NotificationCard(
                    notification: notifications[index],
                    onTap: () => _handleNotificationTap(notifications[index]),
                    onDismiss: () => _notificationService.deleteNotification(
                      notifications[index].id,
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: Dimension.width(80),
            color: Colors.grey[400],
          ),
          SizedBox(height: Dimension.height(16)),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: Dimension.font(18),
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: Dimension.height(8)),
          Text(
            'You\'ll see notifications here when you\nhave new updates',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Dimension.font(14),
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    _notificationService.markAsRead(notification.id);

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.bookingConfirmed:
      case NotificationType.bookingReminder:
      case NotificationType.bookingCancelled:
      case NotificationType.bookingCompleted:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookingsScreen()),
        );
        break;
      case NotificationType.reviewReminder:
        // Could navigate to futsal details or show review dialog
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Reviews()),
        );
        break;
      case NotificationType.paymentSuccess:
      case NotificationType.paymentFailed:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookingsScreen()),
        );
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimension.width(16)),
        ),
        title: Text(
          'Clear All Notifications?',
          style: TextStyle(
            fontSize: Dimension.font(18),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will remove all notifications from your list.',
          style: TextStyle(fontSize: Dimension.font(14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: Dimension.font(14),
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _notificationService.clearAll();
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimension.width(8)),
              ),
            ),
            child: Text(
              'Clear All',
              style: TextStyle(
                fontSize: Dimension.font(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo(notification.timestamp);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: Dimension.width(20)),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(Dimension.width(12)),
        ),
        child: Icon(
          Icons.delete,
          color: Colors.white,
          size: Dimension.width(24),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimension.width(12)),
        child: Container(
          padding: EdgeInsets.all(Dimension.width(16)),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Theme.of(context).cardColor
                : Theme.of(context).cardColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(Dimension.width(12)),
            border: Border.all(
              color: notification.isRead
                  ? Colors.transparent
                  : Theme.of(context).primaryColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: Dimension.width(40),
                height: Dimension.width(40),
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimension.width(10)),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: Dimension.width(22),
                ),
              ),
              SizedBox(width: Dimension.width(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: Dimension.font(15),
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: Dimension.width(8),
                            height: Dimension.width(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: Dimension.height(4)),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: Dimension.font(13),
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: Dimension.height(6)),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: Dimension.font(11),
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }
}
