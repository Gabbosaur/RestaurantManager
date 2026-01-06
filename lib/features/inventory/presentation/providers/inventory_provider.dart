import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/supabase_service.dart';
import '../../data/models/inventory_item_model.dart';

final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, List<InventoryItemModel>>(
        InventoryNotifier.new);

class InventoryNotifier extends AsyncNotifier<List<InventoryItemModel>> {
  @override
  Future<List<InventoryItemModel>> build() async {
    // Subscribe to real-time updates
    SupabaseService.subscribeToInventory((payload) {
      ref.invalidateSelf();
    });

    return _fetchInventory();
  }

  Future<List<InventoryItemModel>> _fetchInventory() async {
    final response = await SupabaseService.client
        .from('inventory_items')
        .select()
        .order('name');

    return (response as List)
        .map((e) => InventoryItemModel.fromJson(e))
        .toList();
  }

  Future<void> addItem(InventoryItemModel item) async {
    await SupabaseService.client.from('inventory_items').insert(item.toJson());
    ref.invalidateSelf();
  }

  Future<void> updateItem(InventoryItemModel item) async {
    await SupabaseService.client
        .from('inventory_items')
        .update(item.toJson())
        .eq('id', item.id);
    ref.invalidateSelf();
  }

  Future<void> updateQuantity(String itemId, double newQuantity) async {
    await SupabaseService.client.from('inventory_items').update({
      'quantity': newQuantity,
      'last_restocked': DateTime.now().toIso8601String(),
    }).eq('id', itemId);
    ref.invalidateSelf();
  }

  Future<void> deleteItem(String itemId) async {
    await SupabaseService.client
        .from('inventory_items')
        .delete()
        .eq('id', itemId);
    ref.invalidateSelf();
  }
}
