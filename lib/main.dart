import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/services/offline_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Legge l'ambiente da --dart-define=ENV=dev|prod
  // Default: dev in debug mode, prod in release mode
  const envFromBuild = String.fromEnvironment('ENV');
  final bool useDev;
  
  if (envFromBuild.isNotEmpty) {
    // Se specificato esplicitamente, usa quello
    useDev = envFromBuild == 'dev';
  } else {
    // Altrimenti, debug=dev, release=prod
    useDev = kDebugMode;
  }

  final envFile = useDev ? '.env.dev' : '.env';
  try {
    await dotenv.load(fileName: envFile);
  } catch (_) {
    // Fallback to .env if .env.dev doesn't exist
    await dotenv.load(fileName: '.env');
  }

  // Initialize locale data for date formatting
  await initializeDateFormatting('it', null);
  
  // Initialize offline storage (Hive)
  await OfflineStorageService.initialize();

  if (!SupabaseConfig.isConfigured) {
    throw Exception(
      'Supabase not configured! Check your .env file has SUPABASE_URL and SUPABASE_ANON_KEY',
    );
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    const ProviderScope(
      child: RestaurantApp(),
    ),
  );
}
