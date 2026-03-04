import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pfe1/features/authentication/presentation/email_verification_screen.dart';
import 'package:pfe1/features/authentication/presentation/login_screen.dart';
import 'package:pfe1/features/authentication/presentation/signup_screen.dart';
import 'package:pfe1/features/authentication/presentation/user_details_screen.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/features/business/presentation/business_profile_screen.dart';
import 'package:pfe1/features/business/presentation/add_business_screen.dart';
import 'package:pfe1/features/chat/presentation/chat_list_screen.dart';
import 'package:pfe1/features/chat/presentation/chat_room_screen.dart';
import 'package:pfe1/features/chat/presentation/user_search_screen.dart';
import 'package:pfe1/features/home/presentation/create_post_screen.dart';
import 'package:pfe1/features/home/presentation/home_screen.dart';
import 'package:pfe1/features/home/presentation/user_profile_screen.dart';
import 'package:pfe1/features/home/presentation/user_update_screen.dart';
import 'package:pfe1/features/interests/presentation/interests_selection_screen.dart';
import 'package:pfe1/shared/theme/app_colors.dart';
import 'package:pfe1/shared/theme/theme_provider.dart';
import 'package:pfe1/shared/screens/splash_screen.dart'; 

class RouterNotifier extends ChangeNotifier { 
  final WidgetRef _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (previous, next) { 
      if (previous?.status != next.status && 
          (next.status == AuthStatus.authenticated || 
           next.status == AuthStatus.unauthenticated)) { 
        notifyListeners();
      }
    });
  }
}

class MyApp extends ConsumerStatefulWidget {
  final bool isAuthenticated;

  const MyApp({
    Key? key, 
    required this.isAuthenticated
  }) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).restoreSession();
    });
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);

    if (_showSplash) {
      return MaterialApp(
        title: 'PathPal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData.dark().copyWith(
          primaryColor: AppColors.primaryColor,
          scaffoldBackgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        ),
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const SplashScreen(),
      );
    }

    return MaterialApp.router(
      title: 'PathPal',
      debugShowCheckedModeBanner: false,
      routerConfig: _router(ref, widget.isAuthenticated),
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
          path: '/home',
          builder: (context, state) => HomeScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) {
            final email = state.extra as String? ?? '';
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
          path: '/update-profile',
          builder: (context, state) => const UserUpdateScreen(),
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
          builder: (context, state) {
            final Map<String, dynamic>? params = state.extra as Map<String, dynamic>?;
            
            final String? userEmail = params?['userEmail'];
            final bool isOtherUserProfile = params?['isOtherUserProfile'] ?? true;

            if (userEmail == null) {
              return const Scaffold(
                body: Center(
                  child: Text('User email is required'),
                ),
              );
            }

            return UserProfileScreen(
              userEmail: userEmail,
              isOtherUserProfile: isOtherUserProfile,
            );
          },
        ),
        GoRoute(
          path: '/chat/list',
          builder: (context, state) => const ChatListScreen(),
        ),
        GoRoute(
          path: '/chat/search',
          builder: (context, state) => const UserSearchScreen(),
        ),
        GoRoute(
          path: '/chat/room/:roomId',
          builder: (context, state) {
            final roomId = state.pathParameters['roomId']!;
            return ChatRoomScreen(chatRoomId: roomId);
          },
        ),
        GoRoute(
          path: '/business-profile/:businessId',
          builder: (context, state) {
            final businessId = int.parse(state.pathParameters['businessId']!);
            return BusinessProfileScreen(businessId: businessId);
          },
        ),
        GoRoute(
          path: '/add-business',
          builder: (context, state) => const AddBusinessScreen(),
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) {
        final authState = ref.read(authProvider);
        final currentPath = state.uri.path;

        if (currentPath == '/' && authState.status != AuthStatus.authenticated) {
          return '/login';
        }

        return null;
      },
    );
  }
}