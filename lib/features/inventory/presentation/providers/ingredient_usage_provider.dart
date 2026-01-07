import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../menu/presentation/providers/menu_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../orders/data/models/order_model.dart';

/// Provider che calcola quante volte ogni ingrediente è stato ordinato oggi
final ingredientUsageTodayProvider = Provider<Map<String, int>>((ref) {
  final ordersAsync = ref.watch(ordersProvider);
  final menuAsync = ref.watch(menuProvider);

  final orders = ordersAsync.valueOrNull ?? [];
  final menuItems = menuAsync.valueOrNull ?? [];

  // Mappa menuItemId -> ingredientKey
  final menuItemToIngredient = <String, String>{};
  for (final item in menuItems) {
    if (item.ingredientKey != null) {
      menuItemToIngredient[item.id] = item.ingredientKey!;
    }
  }

  // Conta per ingrediente (solo ordini di oggi, non cancellati)
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);

  final usageCount = <String, int>{};

  for (final order in orders) {
    // Solo ordini di oggi e non cancellati
    if (order.createdAt.isBefore(startOfDay)) continue;
    if (order.status == OrderStatus.cancelled) continue;

    for (final item in order.items) {
      final ingredientKey = menuItemToIngredient[item.menuItemId];
      if (ingredientKey != null) {
        usageCount[ingredientKey] = (usageCount[ingredientKey] ?? 0) + item.quantity;
      }
    }
  }

  return usageCount;
});
