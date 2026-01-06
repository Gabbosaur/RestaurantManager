import 'package:equatable/equatable.dart';

enum TableStatus { available, occupied, reserved, cleaning }

enum TableShape { square, round, rectangle }

class TableModel extends Equatable {
  final String id;
  final String name;
  final int capacity;
  final TableStatus status;
  final TableShape shape;
  final double posX; // Position X (0-100 percentage)
  final double posY; // Position Y (0-100 percentage)
  final double width; // Width (percentage of floor)
  final double height; // Height (percentage of floor)
  final String? currentOrderId;
  final DateTime? reservedAt;
  final String? reservedBy;

  const TableModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.status,
    this.shape = TableShape.square,
    this.posX = 0,
    this.posY = 0,
    this.width = 12,
    this.height = 12,
    this.currentOrderId,
    this.reservedAt,
    this.reservedBy,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      name: json['name'],
      capacity: json['capacity'] ?? 4,
      status: TableStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TableStatus.available,
      ),
      shape: TableShape.values.firstWhere(
        (e) => e.name == json['shape'],
        orElse: () => TableShape.square,
      ),
      posX: (json['pos_x'] ?? 0).toDouble(),
      posY: (json['pos_y'] ?? 0).toDouble(),
      width: (json['width'] ?? 12).toDouble(),
      height: (json['height'] ?? 12).toDouble(),
      currentOrderId: json['current_order_id'],
      reservedAt: json['reserved_at'] != null
          ? DateTime.parse(json['reserved_at'])
          : null,
      reservedBy: json['reserved_by'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'capacity': capacity,
        'status': status.name,
        'shape': shape.name,
        'pos_x': posX,
        'pos_y': posY,
        'width': width,
        'height': height,
        'current_order_id': currentOrderId,
        'reserved_at': reservedAt?.toIso8601String(),
        'reserved_by': reservedBy,
      };

  TableModel copyWith({
    String? id,
    String? name,
    int? capacity,
    TableStatus? status,
    TableShape? shape,
    double? posX,
    double? posY,
    double? width,
    double? height,
    String? currentOrderId,
    DateTime? reservedAt,
    String? reservedBy,
  }) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      shape: shape ?? this.shape,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      width: width ?? this.width,
      height: height ?? this.height,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      reservedAt: reservedAt ?? this.reservedAt,
      reservedBy: reservedBy ?? this.reservedBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        capacity,
        status,
        shape,
        posX,
        posY,
        width,
        height,
        currentOrderId,
        reservedAt,
        reservedBy,
      ];
}
