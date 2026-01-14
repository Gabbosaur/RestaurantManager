import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/supabase_service.dart';
import '../../data/models/table_model.dart';

final tablesProvider =
    AsyncNotifierProvider<TablesNotifier, List<TableModel>>(TablesNotifier.new);

class TablesNotifier extends AsyncNotifier<List<TableModel>> {
  @override
  Future<List<TableModel>> build() async {
    return _fetchTables();
  }

  Future<List<TableModel>> _fetchTables() async {
    final response =
        await SupabaseService.client.from('tables').select().order('name');

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

  Future<void> updateStatus(String tableId, TableStatus status) async {
    final updates = <String, dynamic>{'status': status.name};

    if (status == TableStatus.available) {
      updates['current_order_id'] = null;
      updates['number_of_people'] = null;
      updates['reserved_at'] = null;
      updates['reserved_by'] = null;
    }

    await SupabaseService.client
        .from('tables')
        .update(updates)
        .eq('id', tableId);

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

  /// Occupy a table with an order
  Future<void> occupyTableWithOrder(
      String tableId, String orderId, int numberOfPeople) async {
    await SupabaseService.client.from('tables').update({
      'status': TableStatus.occupied.name,
      'current_order_id': orderId,
      'number_of_people': numberOfPeople,
      // Non cancelliamo reserved_by così sappiamo se era prenotato
      // in caso di annullamento ordine
      'reserved_at': null,
    }).eq('id', tableId);

    ref.invalidateSelf();
  }
}
