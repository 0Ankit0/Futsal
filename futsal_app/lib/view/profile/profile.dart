import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/dimension.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../auth/bloc/auth_state.dart';
import '../auth/login.dart';
import '../edit_profile/edit_profile.dart';
import '../settings/settings.dart';
import 'notifications_settings.dart';
import 'privacy_policy.dart';
import 'help_support.dart';
import 'bloc/profile_bloc.dart';
import 'package:provider/provider.dart';
import '../../core/simple_theme.dart';
import 'bloc/profile_event.dart';
import 'bloc/profile_state.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(Dimension.height(200)),
        child: Container(
          width: double.infinity,
          color: Theme.of(context).appBarTheme.backgroundColor,
          padding: EdgeInsets.symmetric(
            horizontal: Dimension.width(20),
            vertical: Dimension.height(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: Dimension.font(16),
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: Dimension.height(10)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimension.width(20),
                  vertical: Dimension.height(10),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimension.width(8)),
                ),
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, state) {
                    if (state is ProfileLoaded) {
                      final userInfo = state.userInfo;
                      return Row(
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(500),
                                child: Image.network(
                                  userInfo.fullImageUrl ??
                                      'https://www.gravatar.com/avatar/placeholder',
                                  width: Dimension.width(80),
                                  height: Dimension.width(80),
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Icon(
                                    Icons.person,
                                    size: Dimension.width(40),
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: Dimension.width(24),
                                  height: Dimension.width(24),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.edit_sharp,
                                    size: Dimension.width(16),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: Dimension.width(16)),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userInfo.username,
                                style: TextStyle(
                                  fontSize: Dimension.font(16),
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                              SizedBox(height: Dimension.height(4)),
                              Text(
                                userInfo.email,
                                style: TextStyle(
                                  fontSize: Dimension.font(14),
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context).colorScheme.onPrimary
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              SizedBox(height: Dimension.height(4)),
                              Text(
                                userInfo.phoneNumber ?? '9869020670',
                                style: TextStyle(
                                  fontSize: Dimension.font(14),
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context).colorScheme.onPrimary
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ProfileBloc>().add(const LoadUserInfo());
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Dimension.width(20),
              vertical: Dimension.height(20),
            ),
            child: Column(
              children: [
                BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, state) {
                    if (state is ProfileLoading) {
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(Dimension.width(10)),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(
                            Dimension.width(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                SizedBox(
                                  width: Dimension.width(40),
                                  height: Dimension.height(24),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: Dimension.height(4)),
                                Text(
                                  'Bookings',
                                  style: TextStyle(
                                    fontSize: Dimension.font(13),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: Dimension.width(1),
                              height: Dimension.height(40),
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.2),
                            ),
                            Column(
                              children: [
                                SizedBox(
                                  width: Dimension.width(40),
                                  height: Dimension.height(24),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: Dimension.height(4)),
                                Text(
                                  'Favorites',
                                  style: TextStyle(
                                    fontSize: Dimension.font(13),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: Dimension.width(1),
                              height: Dimension.height(40),
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.2),
                            ),
                            Column(
                              children: [
                                SizedBox(
                                  width: Dimension.width(40),
                                  height: Dimension.height(24),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: Dimension.height(4)),
                                Text(
                                  'Reviews',
                                  style: TextStyle(
                                    fontSize: Dimension.font(13),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is ProfileError) {
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(Dimension.width(20)),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(
                            Dimension.width(8),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: Dimension.width(48),
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: Dimension.height(12)),
                            Text(
                              'Failed to load profile',
                              style: TextStyle(
                                fontSize: Dimension.font(16),
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: Dimension.height(8)),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: Dimension.width(16),
                              ),
                              child: Text(
                                state.message,
                                style: TextStyle(
                                  fontSize: Dimension.font(13),
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: Dimension.height(12)),
                            ElevatedButton(
                              onPressed: () => context.read<ProfileBloc>().add(
                                const LoadUserInfo(),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is ProfileLoaded) {
                      final userInfo = state.userInfo;
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(Dimension.width(10)),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(
                            Dimension.width(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  userInfo.totalBookings,
                                  style: TextStyle(
                                    fontSize: Dimension.font(20),
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Text(
                                  'Bookings',
                                  style: TextStyle(
                                    fontSize: Dimension.font(13),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: Dimension.width(1),
                              height: Dimension.height(40),
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.2),
                            ),
                            Column(
                              children: [
                                Text(
                                  userInfo.totalFavorites,
                                  style: TextStyle(
                                    fontSize: Dimension.font(20),
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Text(
                                  'Favorites',
                                  style: TextStyle(
                                    fontSize: Dimension.font(13),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: Dimension.width(1),
                              height: Dimension.height(40),
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.2),
                            ),
                            Column(
                              children: [
                                Text(
                                  userInfo.totalReviews,
                                  style: TextStyle(
                                    fontSize: Dimension.font(20),
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Text(
                                  'Reviews',
                                  style: TextStyle(
                                    fontSize: Dimension.font(13),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
                SizedBox(height: Dimension.height(20)),
                Container(
                  padding: EdgeInsets.symmetric(vertical: Dimension.height(10)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimension.width(14)),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: Dimension.width(10),
                        offset: Offset(0, Dimension.height(4)),
                      ),
                    ],
                  ),
                  child: SwitchListTile.adaptive(
                    value: context.watch<ThemeNotifier>().isDark,
                    onChanged: (v) => context.read<ThemeNotifier>().setDark(v),
                    shape: Border.all(color: Colors.transparent),
                    trackOutlineColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: Colors.grey[400],
                    thumbColor: WidgetStateProperty.all(Colors.white),
                    title: Center(
                      child: Text(
                        context.read<ThemeNotifier>().isDark
                            ? 'Light Mode'
                            : 'Dark Mode',
                        style: TextStyle(
                          fontSize: Dimension.font(16),
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    secondary: Container(
                      width: Dimension.width(35),
                      height: Dimension.width(35),
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimension.width(6),
                        vertical: Dimension.width(6),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          Dimension.width(10),
                        ),
                        color: context.read<ThemeNotifier>().isDark
                            ? Colors.deepPurpleAccent
                            : Colors.deepPurpleAccent.withOpacity(0.2),
                      ),
                      child: Image.asset(
                        context.read<ThemeNotifier>().isDark
                            ? 'assets/icons/sun.png'
                            : 'assets/icons/moon.png',
                        width: Dimension.width(12),
                        height: Dimension.width(12),
                        color: context.read<ThemeNotifier>().isDark
                            ? Colors.white
                            : Colors.deepPurpleAccent,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Dimension.height(20)),
                _buildMenuItem(),
                SizedBox(height: Dimension.height(20)),
                ElevatedButton(
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.red.withOpacity(
                        context.read<ThemeNotifier>().isDark ? 0.3 : 0.2,
                      ),
                    ),
                    elevation: WidgetStateProperty.all(0),
                    padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(vertical: Dimension.height(12)),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimension.width(8)),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/logout.png',
                        width: Dimension.width(20),
                        height: Dimension.width(20),
                        color: Colors.red,
                      ),
                      SizedBox(width: Dimension.width(10)),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: Dimension.font(18),
                          fontWeight: FontWeight.w400,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimension.width(10)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.06),
            blurRadius: Dimension.width(10),
            offset: Offset(0, 0),

            spreadRadius: Dimension.width(2),
          ),
        ],
      ),
      child: Column(
        children: [
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoaded) {
                final userInfo = state.userInfo;
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditProfile(userInfo: userInfo),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.1),
                          width: Dimension.height(1),
                        ),
                      ),
                    ),
                    child: menuItems(
                      Colors.lightBlue,
                      'assets/icons/edit_profile.png',
                      'Edit Profile',
                    ),
                  ),
                );
              } else {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.1),
                        width: Dimension.height(1),
                      ),
                    ),
                  ),
                  child: menuItems(
                    Colors.lightBlue,
                    'assets/icons/edit_profile.png',
                    'Edit Profile',
                  ),
                );
              }
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.1),
                    width: Dimension.height(1),
                  ),
                ),
              ),
              child: menuItems(
                Colors.cyan,
                'assets/icons/setting.png',
                'Settings',
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsSettingsScreen(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.1),
                    width: Dimension.height(1),
                  ),
                ),
              ),
              child: menuItems(
                Colors.deepPurpleAccent,
                'assets/icons/notification.png',
                'Notifications',
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.1),
                    width: Dimension.height(1),
                  ),
                ),
              ),
              child: menuItems(
                Colors.orangeAccent,
                'assets/icons/privacyPolicy.png',
                'Privacy & Security',
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(color: Colors.transparent),
              child: menuItems(
                Colors.redAccent,
                'assets/icons/helpSupport.png',
                'Help & Support',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget menuItems(Color bg, String iconPath, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Dimension.width(15),
        vertical: Dimension.height(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: Dimension.width(35),
                height: Dimension.width(35),
                padding: EdgeInsets.symmetric(
                  horizontal: Dimension.width(6),
                  vertical: Dimension.width(6),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimension.width(10)),
                  color: bg.withValues(alpha: 0.2),
                ),
                child: Image.asset(iconPath, color: bg),
              ),
              SizedBox(width: Dimension.width(12)),
              Text(
                title,
                style: TextStyle(
                  fontSize: Dimension.font(16),
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: Dimension.width(16),
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimension.width(20)),
        ),
        title: Row(
          children: [
            Container(
              width: Dimension.width(40),
              height: Dimension.width(40),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(
                  context.read<ThemeNotifier>().isDark ? 0.3 : 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout,
                color: Colors.red,
                size: Dimension.width(22),
              ),
            ),
            SizedBox(width: Dimension.width(12)),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: Dimension.font(20),
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontSize: Dimension.font(15),
            color: Theme.of(
              context,
            ).colorScheme.onPrimary.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: Dimension.font(15),
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.6),
              ),
            ),
          ),
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is Unauthenticated) {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: ElevatedButton(
              onPressed: () =>
                  context.read<AuthBloc>().add(const LogoutRequested()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(10)),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: Dimension.width(20),
                  vertical: Dimension.height(10),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: Dimension.font(15),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
