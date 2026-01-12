import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ui/view/bookings/bookings.dart';
import 'package:ui/view/home/map_view.dart';
import 'package:ui/view/profile/profile.dart';
import 'dart:ui';
import 'home_screen.dart';
import '../../core/dimension.dart';
import 'package:flutter/widgets.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request location permission
    await _requestLocationPermission();

    // Request notification permission
    await _requestNotificationPermission();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  Future<void> _requestNotificationPermission() async {
    // Request notification permission using permission_handler
    // This properly handles Android 13+ runtime permission
    final status = await Permission.notification.status;

    if (status.isDenied || status.isLimited) {
      // Request the permission - this will show the system dialog
      await Permission.notification.request();
    }

    // Also request FCM permission for iOS
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  final List<_NavData> _items = const [
    _NavData(
      label: 'Home',
      assetPath: 'assets/icons/home.png',
      selectedAssetPath: 'assets/icons/selected_home.png',
    ),
    _NavData(
      label: 'Map',
      assetPath: 'assets/icons/map.png',
      selectedAssetPath: 'assets/icons/map.png',
    ),
    _NavData(
      label: 'Booking',
      assetPath: 'assets/icons/booking.png',
      selectedAssetPath: 'assets/icons/selected_booking.png',
    ),
    _NavData(
      label: 'Profile',
      assetPath: 'assets/icons/profile.png',
      selectedAssetPath: 'assets/icons/selected_profile.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.backgroundColor,
        systemNavigationBarIconBrightness:
            Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: _buildBody(),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
              border: Border(
                top: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
              ),
            ),
            child: BottomNavigationBar(
              selectedFontSize: Dimension.font(12),
              unselectedFontSize: Dimension.font(12),
              backgroundColor: Theme.of(
                context,
              ).bottomNavigationBarTheme.backgroundColor,
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: _items.map((e) {
                return BottomNavigationBarItem(
                  icon: Image.asset(
                    e.assetPath,
                    color: Theme.of(
                      context,
                    ).bottomNavigationBarTheme.unselectedItemColor,
                    width: Dimension.width(16),
                    height: Dimension.width(16),
                  ),
                  activeIcon: Image.asset(
                    e.selectedAssetPath ?? e.assetPath,
                    color: Theme.of(
                      context,
                    ).bottomNavigationBarTheme.selectedItemColor,
                    width: Dimension.width(16),
                    height: Dimension.width(16),
                  ),
                  label: e.label,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final screens = [
      const HomeScreen(),
      const MapView(),
      const BookingsScreen(),
      const Profile(),
    ];

    if (_currentIndex >= 0 && _currentIndex < screens.length) {
      return screens[_currentIndex];
    }

    return Center(
      child: Text(
        _items[_currentIndex].label,
        style: TextStyle(
          fontSize: Dimension.font(16),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NavData {
  final String label;
  final String assetPath;
  final String? selectedAssetPath;
  const _NavData({
    required this.label,
    required this.assetPath,
    this.selectedAssetPath,
  });
}
