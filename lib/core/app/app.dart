import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pfe1/features/authentication/presentation/email_verification_screen.dart';
import 'package:pfe1/features/authentication/presentation/login_screen.dart';
import 'package:pfe1/features/authentication/presentation/signup_screen.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/features/home/presentation/home_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final WidgetRef _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) {
      notifyListeners();
    });
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Your App Name',
      routerConfig: _router(ref),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }

   GoRouter _router(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/signup',  // Change initial location
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
          path: '/verify-email',
          builder: (context, state) {
            final email = state.extra as String? ?? 'your email';
            return EmailVerificationScreen(email: email);
          },
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
  }}