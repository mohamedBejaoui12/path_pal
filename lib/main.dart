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
  );

  // Initialize persistent session
  final authService = AuthService();
  await authService.initializeSession();

  runApp(
     ProviderScope(
      child: MyApp(),
    ),
  );
}