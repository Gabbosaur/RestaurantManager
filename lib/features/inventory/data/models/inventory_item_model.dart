import 'package:equatable/equatable.dart';

class InventoryItemModel extends Equatable {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final double minQuantity;
  final String? supplier;
  final DateTime? lastRestocked;
  final DateTime createdAt;

  const InventoryItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.minQuantity,
    this.supplier,
    this.lastRestocked,
    required this.createdAt,
  });

  bool get isLowStock => quantity <= minQuantity;

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'],
      name: json['name'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'units',
      minQuantity: (json['min_quantity'] ?? 0).toDouble(),
      supplier: json['supplier'],
      lastRestocked: json['last_restocked'] != null
          ? DateTime.parse(json['last_restocked'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'min_quantity': minQuantity,
        'supplier': supplier,
        'last_restocked': lastRestocked?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  InventoryItemModel copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    double? minQuantity,
    String? supplier,
    DateTime? lastRestocked,
    DateTime? createdAt,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      minQuantity: minQuantity ?? this.minQuantity,
      supplier: supplier ?? this.supplier,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, quantity, unit, minQuantity, supplier, lastRestocked, createdAt];
}
