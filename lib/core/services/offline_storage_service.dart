import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Servizio per gestire lo storage offline
class OfflineStorageService {
  static const String _pendingActionsBox = 'pending_actions';
  static const String _cachedDataBox = 'cached_data';
  
  static OfflineStorageService? _instance;
  static OfflineStorageService get instance => _instance ??= OfflineStorageService._();
  
  OfflineStorageService._();

  Box? _pendingBox;
  Box? _cacheBox;

  /// Inizializza Hive
  static Future<void> initialize() async {
    await Hive.initFlutter();
    _instance = OfflineStorageService._();
    await _instance!._openBoxes();
  }

  Future<void> _openBoxes() async {
    _pendingBox = await Hive.openBox(_pendingActionsBox);
    _cacheBox = await Hive.openBox(_cachedDataBox);
  }

  // ==================== PENDING ACTIONS ====================

  /// Aggiunge un'azione alla coda offline
  Future<String> addPendingAction(PendingAction action) async {
    final id = const Uuid().v4();
    final actionWithId = action.copyWith(id: id);
    await _pendingBox?.put(id, actionWithId.toJson());
    return id;
  }

  /// Ottiene tutte le azioni pendenti ordinate per timestamp
  List<PendingAction> getPendingActions() {
    if (_pendingBox == null) return [];
    
    final actions = <PendingAction>[];
    for (final key in _pendingBox!.keys) {
      final json = _pendingBox!.get(key);
      if (json != null) {
        actions.add(PendingAction.fromJson(json));
      }
    }
    
    // Ordina per timestamp
    actions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return actions;
  }

  /// Rimuove un'azione dalla coda (dopo sync riuscito)
  Future<void> removePendingAction(String id) async {
    await _pendingBox?.delete(id);
  }

  /// Conta le azioni pendenti
  int get pendingActionsCount => _pendingBox?.length ?? 0;

  /// Verifica se ci sono azioni pendenti
  bool get hasPendingActions => pendingActionsCount > 0;

  // ==================== CACHE ====================

  /// Salva dati in cache
  Future<void> cacheData(String key, dynamic data) async {
    final cacheEntry = {
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _cacheBox?.put(key, jsonEncode(cacheEntry));
  }

  /// Recupera dati dalla cache
  T? getCachedData<T>(String key) {
    final json = _cacheBox?.get(key);
    if (json == null) return null;
    
    try {
      final decoded = jsonDecode(json);
      return decoded['data'] as T?;
    } catch (e) {
      return null;
    }
  }

  /// Ottiene il timestamp della cache
  DateTime? getCacheTimestamp(String key) {
    final json = _cacheBox?.get(key);
    if (json == null) return null;
    
    try {
      final decoded = jsonDecode(json);
      return DateTime.parse(decoded['timestamp']);
    } catch (e) {
      return null;
    }
  }

  /// Pulisce tutta la cache
  Future<void> clearCache() async {
    await _cacheBox?.clear();
  }

  /// Pulisce tutte le azioni pendenti
  Future<void> clearPendingActions() async {
    await _pendingBox?.clear();
  }
}

/// Tipi di azioni offline
enum PendingActionType {
  createOrder,
  updateOrderStatus,
  updateOrderItems,
  deleteOrder,
  markAsPaid,
}

/// Rappresenta un'azione da sincronizzare
class PendingAction {
  final String id;
  final PendingActionType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  PendingAction({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  PendingAction copyWith({
    String? id,
    PendingActionType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
  }) {
    return PendingAction(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'data': jsonEncode(data),
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
  };

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      id: json['id'],
      type: PendingActionType.values[json['type']],
      data: jsonDecode(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
    );
  }
}
