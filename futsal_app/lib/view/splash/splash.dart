import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:lottie/lottie.dart';
import 'package:ui/view/auth/bloc/auth_bloc.dart';
import 'package:ui/view/auth/bloc/auth_event.dart';
import 'package:ui/view/auth/bloc/auth_state.dart';
import 'package:ui/view/auth/login.dart';
import 'package:ui/view/home/home.dart';
import 'package:ui/view/home/bloc/all_futsal/all_futsal_bloc.dart';
import 'package:ui/view/home/bloc/all_futsal/all_futsal_event.dart';
import 'package:ui/view/home/bloc/trending_futsal/trending_futsal_bloc.dart';
import 'package:ui/view/home/bloc/trending_futsal/trending_futsal_event.dart';
import 'package:ui/view/home/bloc/top_reviewed_futsal/top_reviewed_futsal_bloc.dart';
import 'package:ui/view/home/bloc/top_reviewed_futsal/top_reviewed_futsal_event.dart';
import 'package:ui/view/favorite/bloc/favorite_bloc.dart';
import 'package:ui/view/favorite/bloc/favorite_event.dart';
import 'package:ui/view/profile/bloc/profile_bloc.dart';
import 'package:ui/view/profile/bloc/profile_event.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    _checkForUpdateAndNavigate();
  }

  Future<void> _checkForUpdateAndNavigate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }

    if (mounted) {
      _checkAuthAndNavigate();
    }
  }

  void _checkAuthAndNavigate() {
    // Check authentication status
    context.read<AuthBloc>().add(const CheckAuthStatus());

    // Preload futsal data (all three categories + favorites)
    context.read<AllFutsalBloc>().add(const LoadAllFutsals());
    context.read<TrendingFutsalBloc>().add(const LoadTrendingFutsals());
    context.read<TopReviewedFutsalBloc>().add(const LoadTopReviewedFutsals());
    context.read<FavoriteBloc>().add(const LoadFavorites());
    context.read<ProfileBloc>().add(const LoadUserInfo());

    // Wait 3 seconds then navigate based on auth state
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      final authState = context.read<AuthBloc>().state;

      if (authState is Authenticated) {
        // User has valid token, navigate to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Home()),
        );
      } else {
        // No valid token, navigate to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Lottie.asset(
          'assets/splash.json',
          fit: BoxFit.cover,
          repeat: false,
          reverse: false,
        ),
      ),
    );
  }
}
