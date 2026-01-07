import 'package:equatable/equatable.dart';

enum OrderStatus { pending, preparing, ready, served, cancelled }

enum OrderType { table, takeaway }

class OrderModel extends Equatable {
  final String id;
  final String? tableId;
  final String? tableName; // Store table name for display
  final OrderType orderType;
  final int? numberOfPeople;
  final List<OrderItem> items;
  final OrderStatus status;
  final double total;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    this.tableId,
    this.tableName,
    required this.orderType,
    this.numberOfPeople,
    required this.items,
    required this.status,
    required this.total,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTakeaway => orderType == OrderType.takeaway;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      tableId: json['table_id'],
      tableName: json['table_name'],
      orderType: json['order_type'] == 'takeaway' 
          ? OrderType.takeaway 
          : OrderType.table,
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
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'table_id': tableId,
        'table_name': tableName,
        'order_type': orderType.name,
        'number_of_people': numberOfPeople,
        'items': items.map((e) => e.toJson()).toList(),
        'status': status.name,
        'total': total,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  OrderModel copyWith({
    String? id,
    String? tableId,
    String? tableName,
    OrderType? orderType,
    int? numberOfPeople,
    List<OrderItem>? items,
    OrderStatus? status,
    double? total,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      orderType: orderType ?? this.orderType,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      items: items ?? this.items,
      status: status ?? this.status,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, tableId, tableName, orderType, numberOfPeople, items, status, total, notes, createdAt, updatedAt];
}

class OrderItem extends Equatable {
  final String menuItemId;
  final String name;
  final String? nameZh; // nome in cinese per la cucina
  final int quantity;
  final double price;
  final String? notes;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    this.nameZh,
    required this.quantity,
    required this.price,
    this.notes,
  });

  /// Ritorna il nome in cinese se disponibile, altrimenti il nome italiano
  String get displayNameZh => nameZh ?? name;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menu_item_id'],
      name: json['name'],
      nameZh: json['name_zh'],
      quantity: json['quantity'],
      price: (json['price'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
        'menu_item_id': menuItemId,
        'name': name,
        'name_zh': nameZh,
        'quantity': quantity,
        'price': price,
        'notes': notes,
      };

  @override
  List<Object?> get props => [menuItemId, name, nameZh, quantity, price, notes];
}
