import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'connectivity_service.dart';
import 'offline_storage_service.dart';

/// Provider per il servizio di sincronizzazione
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

/// Provider per il conteggio azioni pendenti
final pendingActionsCountProvider = StateProvider<int>((ref) {
  return OfflineStorageService.instance.pendingActionsCount;
});

class SyncService {
  final Ref _ref;
  final _supabase = Supabase.instance.client;
  bool _isSyncing = false;

  SyncService(this._ref);

  /// Sincronizza tutte le azioni pendenti
  Future<SyncResult> syncPendingActions() async {
    if (_isSyncing) return SyncResult(synced: 0, failed: 0, message: 'Sync già in corso');
    
    final connectivity = _ref.read(connectivityProvider);
    if (connectivity == ConnectivityState.offline) {
      return SyncResult(synced: 0, failed: 0, message: 'Offline');
    }

    _isSyncing = true;
    _ref.read(connectivityProvider.notifier).setSyncing();

    final actions = OfflineStorageService.instance.getPendingActions();
    int synced = 0;
    int failed = 0;

    for (final action in actions) {
      try {
        await _executeAction(action);
        await OfflineStorageService.instance.removePendingAction(action.id);
        synced++;
      } catch (e) {
        failed++;
        // Se fallisce troppe volte, rimuovi l'azione
        if (action.retryCount >= 3) {
          await OfflineStorageService.instance.removePendingAction(action.id);
        }
      }
    }

    _isSyncing = false;
    _ref.read(connectivityProvider.notifier).setOnline();
    _ref.read(pendingActionsCountProvider.notifier).state = 
        OfflineStorageService.instance.pendingActionsCount;

    return SyncResult(
      synced: synced,
      failed: failed,
      message: synced > 0 ? 'Sincronizzati $synced ordini' : null,
    );
  }

  /// Esegue una singola azione
  Future<void> _executeAction(PendingAction action) async {
    switch (action.type) {
      case PendingActionType.createOrder:
        await _syncCreateOrder(action.data);
      case PendingActionType.updateOrderStatus:
        await _syncUpdateStatus(action.data);
      case PendingActionType.updateOrderItems:
        await _syncUpdateItems(action.data);
      case PendingActionType.deleteOrder:
        await _syncDeleteOrder(action.data);
      case PendingActionType.markAsPaid:
        await _syncMarkAsPaid(action.data);
    }
  }

  Future<void> _syncCreateOrder(Map<String, dynamic> data) async {
    // Rimuovi l'id locale se presente
    final orderData = Map<String, dynamic>.from(data);
    orderData.remove('local_id');
    
    await _supabase.from('orders').insert(orderData);
  }

  Future<void> _syncUpdateStatus(Map<String, dynamic> data) async {
    final orderId = data['order_id'];
    final status = data['status'];
    
    await _supabase
        .from('orders')
        .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', orderId);
  }

  Future<void> _syncUpdateItems(Map<String, dynamic> data) async {
    final orderId = data['order_id'];
    final items = data['items'];
    final total = data['total'];
    final numberOfPeople = data['number_of_people'];
    
    final updateData = <String, dynamic>{
      'items': items,
      'total': total,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (numberOfPeople != null) {
      updateData['number_of_people'] = numberOfPeople;
    }
    
    await _supabase.from('orders').update(updateData).eq('id', orderId);
  }

  Future<void> _syncDeleteOrder(Map<String, dynamic> data) async {
    final orderId = data['order_id'];
    await _supabase.from('orders').delete().eq('id', orderId);
  }

  Future<void> _syncMarkAsPaid(Map<String, dynamic> data) async {
    final orderId = data['order_id'];
    final total = data['total'];
    
    await _supabase.from('orders').update({
      'status': 'paid',
      'total': total,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  /// Aggiorna il conteggio delle azioni pendenti
  void updatePendingCount() {
    _ref.read(pendingActionsCountProvider.notifier).state = 
        OfflineStorageService.instance.pendingActionsCount;
  }
}

class SyncResult {
  final int synced;
  final int failed;
  final String? message;

  SyncResult({required this.synced, required this.failed, this.message});
}
