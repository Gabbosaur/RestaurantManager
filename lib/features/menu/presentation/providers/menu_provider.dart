import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/supabase_service.dart';
import '../../data/models/menu_item_model.dart';

final menuProvider =
    AsyncNotifierProvider<MenuNotifier, List<MenuItemModel>>(MenuNotifier.new);

class MenuNotifier extends AsyncNotifier<List<MenuItemModel>> {
  @override
  Future<List<MenuItemModel>> build() async {
    return _fetchMenuItems();
  }

  Future<List<MenuItemModel>> _fetchMenuItems() async {
    final response = await SupabaseService.client
        .from('menu_items')
        .select()
        .order('category')
        .order('name');

    return (response as List).map((e) => MenuItemModel.fromJson(e)).toList();
  }

  Future<void> addMenuItem(MenuItemModel item) async {
    await SupabaseService.client.from('menu_items').insert(item.toJson());
    ref.invalidateSelf();
  }

  Future<void> updateMenuItem(MenuItemModel item) async {
    await SupabaseService.client
        .from('menu_items')
        .update(item.toJson())
        .eq('id', item.id);
    ref.invalidateSelf();
  }

  Future<void> toggleAvailability(String itemId, bool isAvailable) async {
    await SupabaseService.client
        .from('menu_items')
        .update({'is_available': isAvailable}).eq('id', itemId);
    ref.invalidateSelf();
  }

  Future<void> deleteMenuItem(String itemId) async {
    await SupabaseService.client.from('menu_items').delete().eq('id', itemId);
    ref.invalidateSelf();
  }
}
