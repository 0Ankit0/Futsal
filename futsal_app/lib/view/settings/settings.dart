import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/dimension.dart';
import '../../core/simple_theme.dart';
import 'change_password.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: Dimension.font(18),
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),

        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: Dimension.width(16),
          vertical: Dimension.height(8),
        ),
        children: [
          _SectionHeader('APPEARANCE'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimension.width(12)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withOpacity(0.06),
                  blurRadius: Dimension.width(10),
                  offset: const Offset(0, 0),
                  spreadRadius: Dimension.width(2),
                ),
              ],
            ),
            child: _SwitchTile(
              leading: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: 'Switch between light and dark theme',
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (value) {
                final themeNotifier = Provider.of<ThemeNotifier>(
                  context,
                  listen: false,
                );
                themeNotifier.toggle();
              },
              showIcon: true,
              iconImage: context.read<ThemeNotifier>().isDark
                  ? 'assets/icons/sun.png'
                  : 'assets/icons/moon.png',
            ),
          ),
          SizedBox(height: Dimension.height(16)),
          _SectionHeader('NOTIFICATIONS'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimension.width(12)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withOpacity(0.06),
                  blurRadius: Dimension.width(10),
                  offset: const Offset(0, 0),
                  spreadRadius: Dimension.width(2),
                ),
              ],
            ),
            child: _SwitchTile(
              leading: Icons.notifications_outlined,
              title: 'Push Notifications',
              subtitle: 'Get notified about bookings',
              value: pushNotifications,
              onChanged: (value) {
                setState(() {
                  pushNotifications = value;
                });
              },
            ),
          ),
          SizedBox(height: Dimension.height(16)),
          _SectionHeader('SECURITY'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimension.width(12)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withOpacity(0.06),
                  blurRadius: Dimension.width(10),
                  offset: const Offset(0, 0),
                  spreadRadius: Dimension.width(2),
                ),
              ],
            ),
            child: _ListTile(
              leading: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your password',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: Dimension.width(4),
        bottom: Dimension.height(8),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: Dimension.font(12),
          fontWeight: FontWeight.w400,
          color: Theme.of(context).colorScheme.onPrimary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ListTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Dimension.width(15),
          vertical: Dimension.height(15),
        ),
        decoration: BoxDecoration(color: Colors.transparent),
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
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: Dimension.height(4)),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: Dimension.font(12),
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showIcon;
  final String? iconImage;

  const _SwitchTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showIcon = false,
    this.iconImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimension.width(15),
        vertical: Dimension.height(15),
      ),
      decoration: BoxDecoration(color: Colors.transparent),
      child: Row(
        children: [
          if (showIcon) ...[
            if (iconImage != null)
              Image.asset(
                iconImage!,
                width: Dimension.width(20),
                height: Dimension.width(20),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              )
            else
              Icon(
                leading,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: Dimension.width(20),
              ),
            SizedBox(width: Dimension.width(12)),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Dimension.font(14),
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: Dimension.height(2)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: Dimension.font(12),
                    fontWeight: FontWeight.w400,
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
            thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return Colors.white;
            }),
            activeColor: Theme.of(context).primaryColor,
            activeTrackColor: Theme.of(context).primaryColor.withOpacity(0.5),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}
