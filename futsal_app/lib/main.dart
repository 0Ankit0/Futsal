import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/firebase_options.dart';
import 'package:ui/view/splash/splash.dart';
import 'package:ui/view/auth/bloc/auth_bloc.dart';
import 'package:ui/view/auth/data/repositories/auth_repository.dart';
import 'package:ui/view/home/bloc/all_futsal/all_futsal_bloc.dart';
import 'package:ui/view/home/bloc/trending_futsal/trending_futsal_bloc.dart';
import 'package:ui/view/home/bloc/top_reviewed_futsal/top_reviewed_futsal_bloc.dart';
import 'package:ui/view/home/data/repository/futsal_repository.dart';
import 'package:ui/view/favorite/bloc/favorite_bloc.dart';
import 'package:ui/view/favorite/data/repository/favorite_repository.dart';
import 'package:ui/view/profile/bloc/profile_bloc.dart';
import 'package:ui/view/profile/data/repository/profile_repository.dart';
import 'package:ui/core/simple_theme.dart';
import 'package:provider/provider.dart';
import 'package:ui/core/service/api_service.dart';
import 'package:ui/core/service/notification_service.dart';
import 'package:ui/core/service/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ApiService and load saved token
  await ApiService().init();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize NotificationService
  NotificationService();

  // Initialize FCM Service for push notifications
  await FCMService().initialize();

  runApp(
    ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => ThemeNotifier()..loadTheme(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(authRepository: AuthRepository()),
        ),
        BlocProvider(
          create: (context) =>
              AllFutsalBloc(futsalRepository: FutsalRepository()),
        ),
        BlocProvider(
          create: (context) =>
              TrendingFutsalBloc(futsalRepository: FutsalRepository()),
        ),
        BlocProvider(
          create: (context) =>
              TopReviewedFutsalBloc(futsalRepository: FutsalRepository()),
        ),
        BlocProvider(
          create: (context) =>
              FavoriteBloc(favoriteRepository: FavoriteRepository()),
        ),
        BlocProvider(
          create: (context) =>
              ProfileBloc(profileRepository: ProfileRepository()),
        ),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: SimpleAppTheme.lightTheme,
          darkTheme: SimpleAppTheme.darkTheme,
          themeMode: themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
          home: const Splash(),
        ),
      ),
    );
  }
}
