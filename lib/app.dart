import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

// Legge ENV da dart-define
const _envFromBuild = String.fromEnvironment('ENV');
final bool isDevEnvironment = _envFromBuild == 'dev' || (_envFromBuild.isEmpty && kDebugMode);

class RestaurantApp extends ConsumerWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Xin Xing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Mostra banner DEV quando si usa ambiente dev
        if (isDevEnvironment) {
          return Banner(
            message: 'DEV',
            location: BannerLocation.topEnd,
            color: Colors.orange,
            child: child ?? const SizedBox.shrink(),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
