import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app/app.dart';
import 'core/config/app_config.dart';
import 'features/authentication/data/auth_service.dart';

Future<void> main() async {
  
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    debug: false, // Only enable debug in debug mode
  );

  // Initialize persistent session
  final authService = AuthService();
  final sessionMaintained = await authService.maintainSession();

  runApp(
    ProviderScope(
      child: MyApp(isAuthenticated: sessionMaintained),
    ),
  );

}