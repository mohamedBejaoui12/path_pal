import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app/app.dart';
import 'core/config/app_config.dart';
import 'features/authentication/data/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // this line is to intialize supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl, // supabase url
    anonKey: AppConfig.supabaseAnonKey, // supabase anon key
    debug: false, // debug mode
  );

  // Initialize persistent session
  final authService = AuthService(); // initialize auth service
  final sessionMaintained =
      await authService.maintainSession(); // maintain session

  runApp(
    ProviderScope(
      // wrap it with provider scope to use riverpod
      child: MyApp(isAuthenticated: sessionMaintained),
    ),
  );
}
