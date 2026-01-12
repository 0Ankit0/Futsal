import 'package:flutter/material.dart';
import '../../core/dimension.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool bookingNotifications = true;
  bool paymentNotifications = true;
  bool promotionalNotifications = false;
  bool reminderNotifications = true;

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: Dimension.font(18),
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: Dimension.width(16),
          vertical: Dimension.height(16),
        ),
        children: [
          Text(
            'Manage your notification preferences',
            style: TextStyle(
              fontSize: Dimension.font(14),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: Dimension.height(24)),
          _buildNotificationTile(
            title: 'Booking Notifications',
            subtitle: 'Get notified about booking confirmations and updates',
            value: bookingNotifications,
            onChanged: (value) => setState(() => bookingNotifications = value),
          ),
          SizedBox(height: Dimension.height(12)),
          _buildNotificationTile(
            title: 'Payment Notifications',
            subtitle: 'Receive alerts for payment transactions',
            value: paymentNotifications,
            onChanged: (value) => setState(() => paymentNotifications = value),
          ),
          SizedBox(height: Dimension.height(12)),
          _buildNotificationTile(
            title: 'Promotional Notifications',
            subtitle: 'Get updates about offers and discounts',
            value: promotionalNotifications,
            onChanged: (value) =>
                setState(() => promotionalNotifications = value),
          ),
          SizedBox(height: Dimension.height(12)),
          _buildNotificationTile(
            title: 'Reminder Notifications',
            subtitle: 'Receive reminders before your bookings',
            value: reminderNotifications,
            onChanged: (value) => setState(() => reminderNotifications = value),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(Dimension.width(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimension.width(12)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.06),
            blurRadius: Dimension.width(10),
            offset: const Offset(0, 2),
            spreadRadius: Dimension.width(2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Dimension.font(14),
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: Dimension.height(4)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: Dimension.font(12),
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
            activeTrackColor: Theme.of(context).primaryColor.withOpacity(0.5),
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
