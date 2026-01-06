import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/supabase_service.dart';
import '../../data/models/table_model.dart';

final tablesProvider =
    AsyncNotifierProvider<TablesNotifier, List<TableModel>>(TablesNotifier.new);

final editModeProvider = StateProvider<bool>((ref) => false);

class TablesNotifier extends AsyncNotifier<List<TableModel>> {
  @override
  Future<List<TableModel>> build() async {
    return _fetchTables();
  }

  Future<List<TableModel>> _fetchTables() async {
    final response = await SupabaseService.client
        .from('tables')
        .select()
        .order('name');

    return (response as List).map((e) => TableModel.fromJson(e)).toList();
  }

  Future<void> addTable(TableModel table) async {
    await SupabaseService.client.from('tables').insert(table.toJson());
    ref.invalidateSelf();
  }

  Future<void> updateTable(TableModel table) async {
    await SupabaseService.client
        .from('tables')
        .update(table.toJson())
        .eq('id', table.id);
    ref.invalidateSelf();
  }

  Future<void> updatePosition(String tableId, double posX, double posY) async {
    await SupabaseService.client.from('tables').update({
      'pos_x': posX,
      'pos_y': posY,
    }).eq('id', tableId);
    ref.invalidateSelf();
  }

  Future<void> updateSize(String tableId, double width, double height) async {
    await SupabaseService.client.from('tables').update({
      'width': width,
      'height': height,
    }).eq('id', tableId);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(String tableId, TableStatus status) async {
    final updates = <String, dynamic>{'status': status.name};
    
    if (status == TableStatus.available) {
      updates['current_order_id'] = null;
      updates['reserved_at'] = null;
      updates['reserved_by'] = null;
    }

    await SupabaseService.client.from('tables').update(updates).eq('id', tableId);
    ref.invalidateSelf();
  }

  Future<void> assignOrder(String tableId, String orderId) async {
    await SupabaseService.client.from('tables').update({
      'status': TableStatus.occupied.name,
      'current_order_id': orderId,
    }).eq('id', tableId);
    ref.invalidateSelf();
  }

  Future<void> makeReservation(
      String tableId, String customerName, DateTime time) async {
    await SupabaseService.client.from('tables').update({
      'status': TableStatus.reserved.name,
      'reserved_by': customerName,
      'reserved_at': time.toIso8601String(),
    }).eq('id', tableId);
    ref.invalidateSelf();
  }

  Future<void> deleteTable(String tableId) async {
    await SupabaseService.client.from('tables').delete().eq('id', tableId);
    ref.invalidateSelf();
  }
}
