import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/text_size_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/inventory/presentation/providers/ingredients_provider.dart';
import 'features/orders/presentation/providers/orders_provider.dart';

// Legge ENV da dart-define
const _envFromBuild = String.fromEnvironment('ENV');
final bool isDevEnvironment = _envFromBuild == 'dev' || (_envFromBuild.isEmpty && kDebugMode);

class RestaurantApp extends ConsumerStatefulWidget {
  const RestaurantApp({super.key});

  @override
  ConsumerState<RestaurantApp> createState() => _RestaurantAppState();
}

class _RestaurantAppState extends ConsumerState<RestaurantApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quando l'app torna in foreground, forza il refresh dei dati
    if (state == AppLifecycleState.resumed) {
      // Invalida i provider per forzare il refresh
      ref.invalidate(ordersProvider);
      ref.invalidate(ingredientsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);
    final textScale = ref.watch(textScaleProvider);
    
    // Inizializza il provider ingredienti per attivare la subscription realtime
    ref.watch(ingredientsProvider);

    return MaterialApp.router(
      title: 'Xin Xing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Applica la scala del testo
        Widget result = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
        
        // Mostra banner DEV quando si usa ambiente dev
        if (isDevEnvironment) {
          return Banner(
            message: 'DEV',
            location: BannerLocation.topEnd,
            color: Colors.orange,
            child: result,
          );
        }
        return result;
      },
    );
  }
}
