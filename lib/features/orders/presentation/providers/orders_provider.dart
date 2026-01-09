import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/supabase_service.dart';
import '../../data/models/order_model.dart';

final ordersProvider =
    AsyncNotifierProvider<OrdersNotifier, List<OrderModel>>(OrdersNotifier.new);

class OrdersNotifier extends AsyncNotifier<List<OrderModel>> {
  @override
  Future<List<OrderModel>> build() async {
    // Subscribe to real-time updates
    SupabaseService.subscribeToOrders((payload) {
      ref.invalidateSelf();
    });

    return _fetchOrders();
  }

  Future<List<OrderModel>> _fetchOrders() async {
    final response = await SupabaseService.client
        .from('orders')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => OrderModel.fromJson(e)).toList();
  }

  Future<void> createOrder(OrderModel order) async {
    await SupabaseService.client.from('orders').insert(order.toJson());
    ref.invalidateSelf();
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await SupabaseService.client.from('orders').update({
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
    ref.invalidateSelf();
  }

  Future<void> deleteOrder(String orderId) async {
    await SupabaseService.client.from('orders').delete().eq('id', orderId);
    ref.invalidateSelf();
  }

  Future<void> updateOrderItems(
      String orderId, List<OrderItem> items, double total) async {
    await SupabaseService.client.from('orders').update({
      'items': items.map((e) => e.toJson()).toList(),
      'total': total,
      'is_modified': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
    ref.invalidateSelf();
  }

  /// Get active order for a specific table
  OrderModel? getActiveOrderForTable(String tableId) {
    final orders = state.valueOrNull ?? [];
    try {
      return orders.firstWhere(
        (o) =>
            o.tableId == tableId &&
            o.status != OrderStatus.served &&
            o.status != OrderStatus.cancelled,
      );
    } catch (_) {
      return null;
    }
  }
}
