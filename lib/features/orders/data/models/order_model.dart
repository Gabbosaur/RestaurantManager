import 'package:equatable/equatable.dart';

enum OrderStatus { pending, preparing, ready, served, paid, cancelled }

enum OrderType { table, takeaway }

class OrderModel extends Equatable {
  final String id;
  final String? tableId;
  final String? tableName; // Store table name for display
  final OrderType orderType;
  final String? takeawayNumber; // Numero progressivo asporto (es. "A1", "A2")
  final int? numberOfPeople;
  final List<OrderItem> items;
  final OrderStatus status;
  final double total;
  final String? notes;
  final bool isModified; // true se l'ordine è stato modificato dopo la creazione
  final List<OrderChange>? changes; // Lista delle modifiche (aggiunte/rimozioni)
  final Map<String, int> servedQuantities; // menuItemId -> quantità servita
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    this.tableId,
    this.tableName,
    required this.orderType,
    this.takeawayNumber,
    this.numberOfPeople,
    required this.items,
    required this.status,
    required this.total,
    this.notes,
    this.isModified = false,
    this.changes,
    this.servedQuantities = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTakeaway => orderType == OrderType.takeaway;
  
  /// Ritorna l'identificatore da mostrare (tavolo o numero asporto)
  String get displayIdentifier {
    if (isTakeaway) {
      return takeawayNumber ?? 'Asporto';
    }
    return tableName ?? tableId ?? '?';
  }

  /// Ritorna la quantità servita per un piatto
  int getServedQuantity(String menuItemId) => servedQuantities[menuItemId] ?? 0;
  
  /// Controlla se un piatto è completamente servito
  bool isItemFullyServed(String menuItemId) {
    final item = items.firstWhere(
      (i) => i.menuItemId == menuItemId,
      orElse: () => const OrderItem(menuItemId: '', name: '', quantity: 0, price: 0),
    );
    return getServedQuantity(menuItemId) >= item.quantity;
  }
  
  /// Ritorna quanti piatti restano da servire
  int getRemainingToServe(String menuItemId) {
    final item = items.firstWhere(
      (i) => i.menuItemId == menuItemId,
      orElse: () => const OrderItem(menuItemId: '', name: '', quantity: 0, price: 0),
    );
    return (item.quantity - getServedQuantity(menuItemId)).clamp(0, item.quantity);
  }
  
  /// Controlla se tutti i piatti dell'ordine sono stati serviti
  bool get isFullyServed {
    if (items.isEmpty) return false;
    return items.every((item) => getServedQuantity(item.menuItemId) >= item.quantity);
  }
  
  /// Controlla se tutti i PIATTI (escluse bevande) sono stati serviti
  bool get isFoodFullyServed {
    final foodItems = items.where((item) => !item.isBeverage).toList();
    if (foodItems.isEmpty) return true; // Se solo bevande, considera servito
    return foodItems.every((item) => getServedQuantity(item.menuItemId) >= item.quantity);
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse servedQuantities - può essere mappa o lista (retrocompatibilità)
    Map<String, int> served = {};
    final servedData = json['served_items'];
    if (servedData is Map) {
      served = servedData.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    } else if (servedData is List) {
      // Retrocompatibilità: lista di menuItemId -> assume quantità = totale
      for (final id in servedData) {
        served[id.toString()] = 999; // Valore alto per indicare "tutto servito"
      }
    }
    
    return OrderModel(
      id: json['id'],
      tableId: json['table_id'],
      tableName: json['table_name'],
      orderType: json['order_type'] == 'takeaway' 
          ? OrderType.takeaway 
          : OrderType.table,
      takeawayNumber: json['takeaway_number'],
      numberOfPeople: json['number_of_people'],
      items: (json['items'] as List?)
              ?.map((e) => OrderItem.fromJson(e))
              .toList() ??
          [],
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      total: (json['total'] ?? 0).toDouble(),
      notes: json['notes'],
      isModified: json['is_modified'] ?? false,
      changes: (json['changes'] as List?)
              ?.map((e) => OrderChange.fromJson(e))
              .toList(),
      servedQuantities: served,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'table_id': tableId,
        'table_name': tableName,
        'order_type': orderType.name,
        'takeaway_number': takeawayNumber,
        'number_of_people': numberOfPeople,
        'items': items.map((e) => e.toJson()).toList(),
        'status': status.name,
        'total': total,
        'notes': notes,
        'is_modified': isModified,
        'changes': changes?.map((e) => e.toJson()).toList(),
        'served_items': servedQuantities,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  OrderModel copyWith({
    String? id,
    String? tableId,
    String? tableName,
    OrderType? orderType,
    String? takeawayNumber,
    int? numberOfPeople,
    List<OrderItem>? items,
    OrderStatus? status,
    double? total,
    String? notes,
    bool? isModified,
    List<OrderChange>? changes,
    Map<String, int>? servedQuantities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      orderType: orderType ?? this.orderType,
      takeawayNumber: takeawayNumber ?? this.takeawayNumber,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      items: items ?? this.items,
      status: status ?? this.status,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      isModified: isModified ?? this.isModified,
      changes: changes ?? this.changes,
      servedQuantities: servedQuantities ?? this.servedQuantities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, tableId, tableName, orderType, takeawayNumber, numberOfPeople, items, status, total, notes, isModified, changes, servedQuantities, createdAt, updatedAt];
}

class OrderItem extends Equatable {
  final String menuItemId;
  final String name;
  final String? nameZh; // nome in cinese per la cucina
  final String? category; // categoria per separare bevande da piatti
  final int quantity;
  final double price;
  final String? notes;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    this.nameZh,
    this.category,
    required this.quantity,
    required this.price,
    this.notes,
  });

  /// Ritorna il nome in cinese se disponibile, altrimenti il nome italiano
  String get displayNameZh => nameZh ?? name;

  /// Controlla se è una bevanda
  bool get isBeverage => category?.startsWith('Bevande') ?? false;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menu_item_id'],
      name: json['name'],
      nameZh: json['name_zh'],
      category: json['category'],
      quantity: json['quantity'],
      price: (json['price'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
        'menu_item_id': menuItemId,
        'name': name,
        'name_zh': nameZh,
        'category': category,
        'quantity': quantity,
        'price': price,
        'notes': notes,
      };

  @override
  List<Object?> get props => [menuItemId, name, nameZh, category, quantity, price, notes];
}


/// Rappresenta una modifica all'ordine (aggiunta o rimozione di piatti)
class OrderChange extends Equatable {
  final String name;
  final String? nameZh;
  final int quantity; // positivo = aggiunto, negativo = rimosso
  final DateTime timestamp;

  const OrderChange({
    required this.name,
    this.nameZh,
    required this.quantity,
    required this.timestamp,
  });

  bool get isAddition => quantity > 0;
  bool get isRemoval => quantity < 0;

  factory OrderChange.fromJson(Map<String, dynamic> json) {
    return OrderChange(
      name: json['name'],
      nameZh: json['name_zh'],
      quantity: json['quantity'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'name_zh': nameZh,
        'quantity': quantity,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  List<Object?> get props => [name, nameZh, quantity, timestamp];
}
