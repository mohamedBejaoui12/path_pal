import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pfe1/features/authentication/presentation/email_verification_screen.dart';
import 'package:pfe1/features/authentication/presentation/login_screen.dart';
import 'package:pfe1/features/authentication/presentation/signup_screen.dart';
import 'package:pfe1/features/authentication/presentation/user_details_screen.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/features/home/presentation/create_post_screen.dart';
import 'package:pfe1/features/home/presentation/home_screen.dart';
import 'package:pfe1/features/home/presentation/user_profile_screen.dart';
import 'package:pfe1/features/interests/presentation/interests_selection_screen.dart';
import 'package:pfe1/shared/theme/app_colors.dart';
import 'package:pfe1/shared/theme/theme_provider.dart';

class RouterNotifier extends ChangeNotifier {
  final WidgetRef _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) {
      notifyListeners();
    });
  }
}

class MyApp extends ConsumerWidget {
  final bool isAuthenticated;

  const MyApp({
    Key? key, 
    required this.isAuthenticated
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Restore session on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).restoreSession();
    });

    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'PFE App',
      debugShowCheckedModeBanner: false,
      routerConfig: _router(ref, isAuthenticated),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: isDarkMode ? Colors.white : Colors.black,
          displayColor: isDarkMode ? Colors.white : Colors.black,
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }

  GoRouter _router(WidgetRef ref, bool isAuthenticated) {
    return GoRouter(
      initialLocation: isAuthenticated ? '/' : '/login',  
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/create-post',
          builder: (context, state) => const CreatePostScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) {
            final email = state.extra as String? ?? 'your email';
            return EmailVerificationScreen(email: email);
          },
        ),
        GoRoute(
          path: '/user-details',
          builder: (context, state) {
            final email = state.extra as String;
            return UserDetailsScreen(email: email);
          },
        ),
        
      
   GoRoute(
  path: '/select-interests',
  builder: (context, state) {
    final userId = state.extra as int;
    return InterestsSelectionScreen(userId: userId);
  },
),
GoRoute(
  path: '/user-profile',
  builder: (context, state) => const UserProfileScreen(),
),
      ],
      // Minimal redirect logic
      redirect: (BuildContext context, GoRouterState state) {
        final authState = ref.read(authProvider);
        final currentPath = state.uri.path;

        // Only redirect to login for home screen if not authenticated
        if (currentPath == '/' && authState.status != AuthStatus.authenticated) {
          return '/login';
        }

        return null;
      },
    );
  }
}