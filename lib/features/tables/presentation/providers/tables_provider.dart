import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/supabase_service.dart';
import '../../data/models/table_model.dart';

final tablesProvider =
    AsyncNotifierProvider<TablesNotifier, List<TableModel>>(TablesNotifier.new);

/// Provider per mostrare errori nella UI (usa codici, tradotti nella UI)
final tableErrorProvider = StateProvider<TableError?>((ref) => null);

enum TableError {
  createFailed,
  updateFailed,
  deleteFailed,
  reservationFailed,
  occupyFailed,
}

class TablesNotifier extends AsyncNotifier<List<TableModel>> {
  @override
  Future<List<TableModel>> build() async {
    return _fetchTables();
  }

  Future<List<TableModel>> _fetchTables() async {
    try {
      final response =
          await SupabaseService.client.from('tables').select().order('name');
      return (response as List).map((e) => TableModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Impossibile caricare i tavoli. Controlla la connessione.');
    }
  }

  Future<bool> addTable(TableModel table) async {
    try {
      await SupabaseService.client.from('tables').insert(table.toJson());
      ref.invalidateSelf();
      return true;
    } catch (e) {
      ref.read(tableErrorProvider.notifier).state = TableError.createFailed;
      return false;
    }
  }

  Future<bool> updateTable(TableModel table) async {
    try {
      await SupabaseService.client
          .from('tables')
          .update(table.toJson())
          .eq('id', table.id);
      ref.invalidateSelf();
      return true;
    } catch (e) {
      ref.read(tableErrorProvider.notifier).state = TableError.updateFailed;
      return false;
    }
  }

  Future<bool> updateStatus(String tableId, TableStatus status) async {
    try {
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
      return true;
    } catch (e) {
      ref.read(tableErrorProvider.notifier).state = TableError.updateFailed;
      return false;
    }
  }

  Future<bool> makeReservation(
      String tableId, String customerName, DateTime time) async {
    try {
      await SupabaseService.client.from('tables').update({
        'status': TableStatus.reserved.name,
        'reserved_by': customerName,
        'reserved_at': time.toIso8601String(),
      }).eq('id', tableId);

      ref.invalidateSelf();
      return true;
    } catch (e) {
      ref.read(tableErrorProvider.notifier).state = TableError.reservationFailed;
      return false;
    }
  }

  Future<bool> deleteTable(String tableId) async {
    try {
      await SupabaseService.client.from('tables').delete().eq('id', tableId);
      ref.invalidateSelf();
      return true;
    } catch (e) {
      ref.read(tableErrorProvider.notifier).state = TableError.deleteFailed;
      return false;
    }
  }

  /// Occupy a table with an order
  Future<bool> occupyTableWithOrder(
      String tableId, String orderId, int numberOfPeople) async {
    try {
      await SupabaseService.client.from('tables').update({
        'status': TableStatus.occupied.name,
        'current_order_id': orderId,
        'number_of_people': numberOfPeople,
        'reserved_at': null,
      }).eq('id', tableId);

      ref.invalidateSelf();
      return true;
    } catch (e) {
      ref.read(tableErrorProvider.notifier).state = TableError.occupyFailed;
      return false;
    }
  }
}
