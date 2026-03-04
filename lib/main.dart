import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app/app.dart';
import 'core/config/app_config.dart';
import 'features/authentication/data/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    debug: false,
  );

  final authService = AuthService();
  final sessionMaintained = await authService.maintainSession();

  runApp(
    ProviderScope(
      child: MyApp(isAuthenticated: sessionMaintained),
    ),
  );
}
