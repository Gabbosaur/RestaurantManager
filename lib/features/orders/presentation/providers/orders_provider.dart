import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/notification_sound_service.dart';
import '../../../../services/supabase_service.dart';
import '../../../tables/presentation/providers/tables_provider.dart';
import '../../data/models/order_model.dart';

final ordersProvider =
    AsyncNotifierProvider<OrdersNotifier, List<OrderModel>>(OrdersNotifier.new);

class OrdersNotifier extends AsyncNotifier<List<OrderModel>> {
  RealtimeChannel? _subscription;
  final _soundService = NotificationSoundService();
  Set<String> _knownOrderIds = {};

  @override
  Future<List<OrderModel>> build() async {
    // Chiudi subscription precedente se esiste
    _subscription?.unsubscribe();
    
    // Subscribe to real-time updates
    _subscription = SupabaseService.subscribeToOrders((payload) {
      _handleRealtimeUpdate(payload);
    });

    // Cleanup quando il provider viene distrutto
    ref.onDispose(() {
      _subscription?.unsubscribe();
    });

    final orders = await _fetchOrders();
    // Inizializza gli ID conosciuti
    _knownOrderIds = orders.map((o) => o.id).toSet();
    return orders;
  }
  
  void _handleRealtimeUpdate(dynamic payload) {
    final eventType = payload.eventType;
    
    // Se è un INSERT (nuovo ordine), riproduci il suono
    if (eventType == PostgresChangeEvent.insert) {
      final newRecord = payload.newRecord;
      final orderId = newRecord['id'] as String?;
      
      // Verifica che sia un ordine nuovo (non già conosciuto)
      if (orderId != null && !_knownOrderIds.contains(orderId)) {
        _knownOrderIds.add(orderId);
        // Riproduci suono solo se è un ordine pending (nuovo)
        if (newRecord['status'] == 'pending') {
          _soundService.playNewOrderSound();
        }
      }
    }
    // Se è un UPDATE con is_modified = true, suono leggero
    else if (eventType == PostgresChangeEvent.update) {
      final newRecord = payload.newRecord;
      if (newRecord['is_modified'] == true) {
        _soundService.playOrderModifiedSound();
      }
    }
    
    ref.invalidateSelf();
  }

  Future<List<OrderModel>> _fetchOrders() async {
    // Calcola il giorno lavorativo (dalle 6:00 alle 5:59 del giorno dopo)
    final now = DateTime.now();
    final businessDate = now.hour < 6 
        ? DateTime(now.year, now.month, now.day - 1)
        : DateTime(now.year, now.month, now.day);
    
    // Inizio del giorno lavorativo (6:00 del giorno)
    final businessDayStart = DateTime(businessDate.year, businessDate.month, businessDate.day, 6);
    
    // Query ottimizzata: ordini attivi OR ordini recenti del giorno lavorativo
    // Usiamo due query separate per evitare problemi con OR complessi
    final activeResponse = await SupabaseService.client
        .from('orders')
        .select()
        .not('status', 'in', '(paid,cancelled)')
        .order('created_at', ascending: false);

    final todayResponse = await SupabaseService.client
        .from('orders')
        .select()
        .gte('created_at', businessDayStart.toIso8601String())
        .order('created_at', ascending: false);

    // Combina e deduplica
    final Map<String, OrderModel> ordersMap = {};
    
    for (final json in activeResponse as List) {
      final order = OrderModel.fromJson(json);
      ordersMap[order.id] = order;
    }
    
    for (final json in todayResponse as List) {
      final order = OrderModel.fromJson(json);
      // Filtra solo ordini del giorno lavorativo corrente
      final orderBusinessDate = order.createdAt.hour < 6
          ? DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day - 1)
          : DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day);
      
      if (orderBusinessDate.year == businessDate.year &&
          orderBusinessDate.month == businessDate.month &&
          orderBusinessDate.day == businessDate.day) {
        ordersMap[order.id] = order;
      }
    }

    // Ordina per data decrescente
    final orders = ordersMap.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return orders;
  }

  Future<void> createOrder(OrderModel order) async {
    var orderToInsert = order;
    
    // Se è un ordine takeaway, genera il numero progressivo
    if (order.isTakeaway) {
      final takeawayNumber = await _generateTakeawayNumber();
      orderToInsert = order.copyWith(takeawayNumber: takeawayNumber);
    }
    
    await SupabaseService.client.from('orders').insert(orderToInsert.toJson());
    ref.invalidateSelf();
  }
  
  /// Genera il prossimo numero takeaway del giorno (A1, A2, A3...)
  Future<String> _generateTakeawayNumber() async {
    // Calcola il giorno lavorativo (dalle 6:00 alle 5:59 del giorno dopo)
    final now = DateTime.now();
    final businessDate = now.hour < 6 
        ? DateTime(now.year, now.month, now.day - 1)
        : DateTime(now.year, now.month, now.day);
    final businessDayStart = DateTime(businessDate.year, businessDate.month, businessDate.day, 6);
    final businessDayEnd = businessDayStart.add(const Duration(hours: 24));
    
    // Conta gli ordini takeaway del giorno lavorativo
    final response = await SupabaseService.client
        .from('orders')
        .select('id')
        .eq('order_type', 'takeaway')
        .gte('created_at', businessDayStart.toIso8601String())
        .lt('created_at', businessDayEnd.toIso8601String());
    
    final count = (response as List).length;
    return 'A${count + 1}';
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    // Quando lo stato cambia (es. inizia preparazione), pulisci le modifiche
    // così il cuoco sa che ha visto le modifiche
    final Map<String, dynamic> updateData = {
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Se passa a "preparing", pulisci le modifiche e il flag is_modified
    if (status == OrderStatus.preparing) {
      updateData['changes'] = null;
      updateData['is_modified'] = false;
    }
    
    await SupabaseService.client.from('orders').update(updateData).eq('id', orderId);
    ref.invalidateSelf();
  }

  Future<void> deleteOrder(String orderId) async {
    await SupabaseService.client.from('orders').delete().eq('id', orderId);
    ref.invalidateSelf();
  }

  Future<void> updateOrderItems(
      String orderId,
      List<OrderItem> newItems,
      double total,
      List<OrderItem> oldItems,
      {String? notes}) async {
    // Calcola le modifiche confrontando vecchi e nuovi items
    final changes = _calculateChanges(oldItems, newItems);

    // Recupera le modifiche esistenti e aggiungi le nuove
    final existingOrder = state.valueOrNull?.firstWhere(
      (o) => o.id == orderId,
      orElse: () => throw Exception('Order not found'),
    );
    final existingChanges = existingOrder?.changes ?? [];
    final allChanges = [...existingChanges, ...changes];

    // Controlla se ci sono nuovi piatti aggiunti
    final hasNewItems = changes.any((c) => c.isAddition);
    
    // Se l'ordine era "served" (completato) e sono stati aggiunti piatti, torna a "preparing"
    final shouldChangeStatus = hasNewItems && 
        existingOrder?.status == OrderStatus.served;

    final Map<String, dynamic> updateData = {
      'items': newItems.map((e) => e.toJson()).toList(),
      'total': total,
      'is_modified': true,
      'changes': allChanges.map((e) => e.toJson()).toList(),
      'notes': notes?.isNotEmpty == true ? notes : null,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (shouldChangeStatus) {
      updateData['status'] = OrderStatus.preparing.name;
    }

    await SupabaseService.client.from('orders').update(updateData).eq('id', orderId);
    ref.invalidateSelf();
  }

  /// Calcola le differenze tra vecchi e nuovi items
  List<OrderChange> _calculateChanges(
      List<OrderItem> oldItems, List<OrderItem> newItems) {
    final changes = <OrderChange>[];
    final now = DateTime.now();

    // Mappa per confronto rapido
    final oldMap = {for (var item in oldItems) item.menuItemId: item};
    final newMap = {for (var item in newItems) item.menuItemId: item};

    // Trova aggiunte e modifiche quantità
    for (final newItem in newItems) {
      final oldItem = oldMap[newItem.menuItemId];
      if (oldItem == null) {
        // Nuovo piatto aggiunto
        changes.add(OrderChange(
          name: newItem.name,
          nameZh: newItem.nameZh,
          quantity: newItem.quantity,
          timestamp: now,
        ));
      } else if (newItem.quantity > oldItem.quantity) {
        // Quantità aumentata
        changes.add(OrderChange(
          name: newItem.name,
          nameZh: newItem.nameZh,
          quantity: newItem.quantity - oldItem.quantity,
          timestamp: now,
        ));
      } else if (newItem.quantity < oldItem.quantity) {
        // Quantità diminuita
        changes.add(OrderChange(
          name: newItem.name,
          nameZh: newItem.nameZh,
          quantity: newItem.quantity - oldItem.quantity, // negativo
          timestamp: now,
        ));
      }
    }

    // Trova rimozioni complete
    for (final oldItem in oldItems) {
      if (!newMap.containsKey(oldItem.menuItemId)) {
        changes.add(OrderChange(
          name: oldItem.name,
          nameZh: oldItem.nameZh,
          quantity: -oldItem.quantity, // negativo = rimosso
          timestamp: now,
        ));
      }
    }

    return changes;
  }

  /// Get active order for a specific table
  OrderModel? getActiveOrderForTable(String tableId) {
    final orders = state.valueOrNull ?? [];
    try {
      return orders.firstWhere(
        (o) =>
            o.tableId == tableId &&
            o.status != OrderStatus.paid &&
            o.status != OrderStatus.cancelled,
      );
    } catch (_) {
      return null;
    }
  }

  /// Pulisce le modifiche di un ordine (quando il cuoco le ha viste)
  Future<void> clearChanges(String orderId) async {
    await SupabaseService.client.from('orders').update({
      'changes': null,
      'is_modified': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
    ref.invalidateSelf();
  }

  /// Incrementa di 1 la quantità servita per un piatto (o decrementa se già tutto servito)
  /// Se tutti i piatti sono serviti, l'ordine passa automaticamente a "served"
  Future<void> toggleItemServed(String orderId, String menuItemId) async {
    final order = state.valueOrNull?.firstWhere(
      (o) => o.id == orderId,
      orElse: () => throw Exception('Order not found'),
    );
    if (order == null) return;

    final item = order.items.firstWhere(
      (i) => i.menuItemId == menuItemId,
      orElse: () => const OrderItem(menuItemId: '', name: '', quantity: 0, price: 0),
    );
    if (item.menuItemId.isEmpty) return;

    final servedQuantities = Map<String, int>.from(order.servedQuantities);
    final currentServed = servedQuantities[menuItemId] ?? 0;
    
    if (currentServed >= item.quantity) {
      // Già tutto servito -> reset a 0
      servedQuantities.remove(menuItemId);
    } else {
      // Incrementa di 1
      servedQuantities[menuItemId] = currentServed + 1;
    }

    // Controlla se tutti i piatti sono ora serviti
    final updatedOrder = order.copyWith(servedQuantities: servedQuantities);
    final allServed = updatedOrder.isFullyServed;
    
    final Map<String, dynamic> updateData = {
      'served_items': servedQuantities,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Se tutti serviti e non già in stato served/paid, aggiorna automaticamente
    if (allServed && order.status != OrderStatus.served && order.status != OrderStatus.paid) {
      updateData['status'] = OrderStatus.served.name;
    }
    // Se non tutti serviti ma era in served, torna a preparing (qualcuno ha aggiunto piatti)
    else if (!allServed && order.status == OrderStatus.served) {
      updateData['status'] = OrderStatus.preparing.name;
    }

    await SupabaseService.client.from('orders').update(updateData).eq('id', orderId);
    ref.invalidateSelf();
  }
  
  /// Segna tutte le quantità di un piatto come servite
  Future<void> markItemFullyServed(String orderId, String menuItemId) async {
    final order = state.valueOrNull?.firstWhere(
      (o) => o.id == orderId,
      orElse: () => throw Exception('Order not found'),
    );
    if (order == null) return;

    final item = order.items.firstWhere(
      (i) => i.menuItemId == menuItemId,
      orElse: () => const OrderItem(menuItemId: '', name: '', quantity: 0, price: 0),
    );
    if (item.menuItemId.isEmpty) return;

    final servedQuantities = Map<String, int>.from(order.servedQuantities);
    servedQuantities[menuItemId] = item.quantity;

    await SupabaseService.client.from('orders').update({
      'served_items': servedQuantities,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
    ref.invalidateSelf();
  }

  /// Segna l'ordine come pagato e libera il tavolo
  Future<void> markAsPaid(String orderId) async {
    final order = state.valueOrNull?.firstWhere(
      (o) => o.id == orderId,
      orElse: () => throw Exception('Order not found'),
    );
    if (order == null) return;

    // Aggiorna lo stato dell'ordine a "paid"
    await SupabaseService.client.from('orders').update({
      'status': OrderStatus.paid.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);

    // Se è un ordine al tavolo, libera il tavolo completamente
    if (order.tableId != null && !order.isTakeaway) {
      await SupabaseService.client.from('tables').update({
        'status': 'available',
        'current_order_id': null,
        'number_of_people': null,
        'reserved_by': null, // Prenotazione completata
      }).eq('id', order.tableId!);
      ref.invalidate(tablesProvider); // Refresh UI tavoli
    }

    ref.invalidateSelf();
  }

  /// Annulla l'ordine e ripristina lo stato del tavolo
  Future<void> cancelOrder(String orderId) async {
    final order = state.valueOrNull?.firstWhere(
      (o) => o.id == orderId,
      orElse: () => throw Exception('Order not found'),
    );
    if (order == null) return;

    // Aggiorna lo stato dell'ordine a "cancelled"
    await SupabaseService.client.from('orders').update({
      'status': OrderStatus.cancelled.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);

    // Se è un ordine al tavolo, ripristina lo stato del tavolo
    if (order.tableId != null && !order.isTakeaway) {
      // Controlla se il tavolo era prenotato (reserved_by ancora presente)
      final tableData = await SupabaseService.client
          .from('tables')
          .select('reserved_by')
          .eq('id', order.tableId!)
          .single();
      
      final wasReserved = tableData['reserved_by'] != null;
      
      await SupabaseService.client.from('tables').update({
        'status': wasReserved ? 'reserved' : 'available',
        'current_order_id': null,
        'number_of_people': null,
        // Se non era prenotato, pulisci anche reserved_by
        if (!wasReserved) 'reserved_by': null,
      }).eq('id', order.tableId!);
      
      ref.invalidate(tablesProvider); // Refresh UI tavoli
    }

    ref.invalidateSelf();
  }
}
