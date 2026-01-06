import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../services/supabase_service.dart';
import '../../data/models/table_model.dart';

final tablesProvider =
    AsyncNotifierProvider<TablesNotifier, List<TableModel>>(TablesNotifier.new);

final editModeProvider = StateProvider<bool>((ref) => false);

// Provider per tracciare il tavolo target durante il drag (per feedback visivo)
final dragSnapTargetProvider = StateProvider<String?>((ref) => null);

class TablesNotifier extends AsyncNotifier<List<TableModel>> {
  // Snap distance in percentage of floor size (6% = easier detection)
  static const double snapDistance = 6.0;
  // Dimensione fissa dei tavoli in percentuale (tutti i tavoli sono quadrati)
  static const double tableSize = 10.0;

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

  /// Check snap target during drag (for visual feedback, doesn't save)
  String? checkSnapTarget(String tableId, double posX, double posY,
      double tableSizePercentX, double tableSizePercentY) {
    final tables = state.valueOrNull ?? [];

    for (final other in tables) {
      if (other.id == tableId) continue;

      final movingRight = posX + tableSizePercentX;
      final movingBottom = posY + tableSizePercentY;
      final otherRight = other.posX + tableSizePercentX;
      final otherBottom = other.posY + tableSizePercentY;

      // Check all 4 sides
      if ((posX - otherRight).abs() < snapDistance &&
          _verticalOverlap(
              posY, tableSizePercentY, other.posY, tableSizePercentY)) {
        return other.id;
      }
      if ((movingRight - other.posX).abs() < snapDistance &&
          _verticalOverlap(
              posY, tableSizePercentY, other.posY, tableSizePercentY)) {
        return other.id;
      }
      if ((posY - otherBottom).abs() < snapDistance &&
          _horizontalOverlap(
              posX, tableSizePercentX, other.posX, tableSizePercentX)) {
        return other.id;
      }
      if ((movingBottom - other.posY).abs() < snapDistance &&
          _horizontalOverlap(
              posX, tableSizePercentX, other.posX, tableSizePercentX)) {
        return other.id;
      }
    }
    return null;
  }

  Future<void> updateTable(TableModel table) async {
    await SupabaseService.client
        .from('tables')
        .update(table.toJson())
        .eq('id', table.id);
    ref.invalidateSelf();
  }

  /// Update position with snap-to-join behavior
  Future<void> updatePosition(String tableId, double posX, double posY,
      double tableSizePercentX, double tableSizePercentY) async {
    final tables = state.valueOrNull ?? [];
    final movingTable = tables.firstWhere((t) => t.id == tableId);

    // Check if we should snap to another table
    TableModel? snapTarget;
    double snapX = posX;
    double snapY = posY;
    double minDistance = double.infinity;

    for (final other in tables) {
      if (other.id == tableId) continue;

      // Calculate edges
      final movingRight = posX + tableSizePercentX;
      final movingBottom = posY + tableSizePercentY;
      final otherRight = other.posX + tableSizePercentX;
      final otherBottom = other.posY + tableSizePercentY;

      // Check snap to RIGHT of other table
      if ((posX - otherRight).abs() < snapDistance) {
        if (_verticalOverlap(
            posY, tableSizePercentY, other.posY, tableSizePercentY)) {
          final dist = (posX - otherRight).abs();
          if (dist < minDistance) {
            minDistance = dist;
            snapX = otherRight;
            snapY = other.posY;
            snapTarget = other;
          }
        }
      }

      // Check snap to LEFT of other table
      if ((movingRight - other.posX).abs() < snapDistance) {
        if (_verticalOverlap(
            posY, tableSizePercentY, other.posY, tableSizePercentY)) {
          final dist = (movingRight - other.posX).abs();
          if (dist < minDistance) {
            minDistance = dist;
            snapX = other.posX - tableSizePercentX;
            snapY = other.posY;
            snapTarget = other;
          }
        }
      }

      // Check snap to BOTTOM of other table
      if ((posY - otherBottom).abs() < snapDistance) {
        if (_horizontalOverlap(
            posX, tableSizePercentX, other.posX, tableSizePercentX)) {
          final dist = (posY - otherBottom).abs();
          if (dist < minDistance) {
            minDistance = dist;
            snapX = other.posX;
            snapY = otherBottom;
            snapTarget = other;
          }
        }
      }

      // Check snap to TOP of other table
      if ((movingBottom - other.posY).abs() < snapDistance) {
        if (_horizontalOverlap(
            posX, tableSizePercentX, other.posX, tableSizePercentX)) {
          final dist = (movingBottom - other.posY).abs();
          if (dist < minDistance) {
            minDistance = dist;
            snapX = other.posX;
            snapY = other.posY - tableSizePercentY;
            snapTarget = other;
          }
        }
      }
    }

    // Clamp to valid range
    snapX = snapX.clamp(0, 100 - tableSizePercentX);
    snapY = snapY.clamp(0, 100 - tableSizePercentY);

    // Update position
    await SupabaseService.client.from('tables').update({
      'pos_x': snapX,
      'pos_y': snapY,
    }).eq('id', tableId);

    // If snapped, join the tables
    if (snapTarget != null) {
      await _joinTables(movingTable, snapTarget);
    } else {
      // If not snapped and was in a group, remove from group
      if (movingTable.groupId != null) {
        final groupId = movingTable.groupId!;

        // Remove this table from group
        await SupabaseService.client.from('tables').update({
          'group_id': null,
        }).eq('id', tableId);

        // Check if only 1 table remains in the group - if so, remove it too
        final remainingInGroup =
            tables.where((t) => t.groupId == groupId && t.id != tableId).toList();
        if (remainingInGroup.length == 1) {
          await SupabaseService.client.from('tables').update({
            'group_id': null,
          }).eq('id', remainingInGroup.first.id);
        }
      }
    }

    ref.invalidateSelf();
  }

  bool _verticalOverlap(double y1, double h1, double y2, double h2) {
    return (y1 < y2 + h2) && (y1 + h1 > y2);
  }

  bool _horizontalOverlap(double x1, double w1, double x2, double w2) {
    return (x1 < x2 + w2) && (x1 + w1 > x2);
  }

  Future<void> _joinTables(TableModel table1, TableModel table2) async {
    // Create a group ID if neither table has one
    final groupId = table1.groupId ?? table2.groupId ?? const Uuid().v4();

    // Update both tables with the same group ID
    await SupabaseService.client.from('tables').update({
      'group_id': groupId,
    }).eq('id', table1.id);

    await SupabaseService.client.from('tables').update({
      'group_id': groupId,
    }).eq('id', table2.id);
  }

  Future<void> updateStatus(String tableId, TableStatus status) async {
    final tables = state.valueOrNull ?? [];
    final table = tables.firstWhere((t) => t.id == tableId);

    final updates = <String, dynamic>{'status': status.name};

    if (status == TableStatus.available) {
      updates['current_order_id'] = null;
      updates['reserved_at'] = null;
      updates['reserved_by'] = null;
    }

    // Update this table
    await SupabaseService.client
        .from('tables')
        .update(updates)
        .eq('id', tableId);

    // If table is in a group, update all tables in the group
    if (table.groupId != null) {
      final groupTables =
          tables.where((t) => t.groupId == table.groupId && t.id != tableId);
      for (final groupTable in groupTables) {
        await SupabaseService.client
            .from('tables')
            .update(updates)
            .eq('id', groupTable.id);
      }
    }

    ref.invalidateSelf();
  }

  Future<void> makeReservation(
      String tableId, String customerName, DateTime time) async {
    final tables = state.valueOrNull ?? [];
    final table = tables.firstWhere((t) => t.id == tableId);

    final updates = {
      'status': TableStatus.reserved.name,
      'reserved_by': customerName,
      'reserved_at': time.toIso8601String(),
    };

    await SupabaseService.client
        .from('tables')
        .update(updates)
        .eq('id', tableId);

    // Update group tables too
    if (table.groupId != null) {
      final groupTables =
          tables.where((t) => t.groupId == table.groupId && t.id != tableId);
      for (final groupTable in groupTables) {
        await SupabaseService.client
            .from('tables')
            .update(updates)
            .eq('id', groupTable.id);
      }
    }

    ref.invalidateSelf();
  }

  Future<void> deleteTable(String tableId) async {
    await SupabaseService.client.from('tables').delete().eq('id', tableId);
    ref.invalidateSelf();
  }

  /// Occupy a table with an order
  Future<void> occupyTableWithOrder(
      String tableId, String orderId, int numberOfPeople) async {
    final tables = state.valueOrNull ?? [];
    final table = tables.firstWhere((t) => t.id == tableId);

    final updates = {
      'status': TableStatus.occupied.name,
      'current_order_id': orderId,
      'number_of_people': numberOfPeople,
      'reserved_at': null,
      'reserved_by': null,
    };

    await SupabaseService.client
        .from('tables')
        .update(updates)
        .eq('id', tableId);

    // If table is in a group, update all tables in the group
    if (table.groupId != null) {
      final groupTables =
          tables.where((t) => t.groupId == table.groupId && t.id != tableId);
      for (final groupTable in groupTables) {
        await SupabaseService.client
            .from('tables')
            .update(updates)
            .eq('id', groupTable.id);
      }
    }

    ref.invalidateSelf();
  }

  /// Separate a table from its group
  Future<void> separateTable(String tableId) async {
    await SupabaseService.client.from('tables').update({
      'group_id': null,
    }).eq('id', tableId);

    ref.invalidateSelf();
  }

  /// Separate all tables in a group
  Future<void> separateGroup(String groupId) async {
    // Usa una query diretta per aggiornare tutti i tavoli del gruppo
    await SupabaseService.client.from('tables').update({
      'group_id': null,
    }).eq('group_id', groupId);

    ref.invalidateSelf();
  }
}
