import 'package:equatable/equatable.dart';

enum TableStatus { available, occupied, reserved, cleaning }

class TableModel extends Equatable {
  final String id;
  final String name;
  final int capacity;
  final TableStatus status;
  final double posX;
  final double posY;
  final double width;
  final double height;
  final String? groupId; // If set, this table is part of a group
  final String? currentOrderId;
  final int? numberOfPeople; // Number of people currently at the table
  final DateTime? reservedAt;
  final String? reservedBy;

  const TableModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.status,
    this.posX = 0,
    this.posY = 0,
    this.width = 10,
    this.height = 10,
    this.groupId,
    this.currentOrderId,
    this.numberOfPeople,
    this.reservedAt,
    this.reservedBy,
  });

  bool get isGrouped => groupId != null;

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      name: json['name'],
      capacity: json['capacity'] ?? 4,
      status: TableStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TableStatus.available,
      ),
      posX: (json['pos_x'] ?? 0).toDouble(),
      posY: (json['pos_y'] ?? 0).toDouble(),
      width: (json['width'] ?? 10).toDouble(),
      height: (json['height'] ?? 10).toDouble(),
      groupId: json['group_id'],
      currentOrderId: json['current_order_id'],
      numberOfPeople: json['number_of_people'],
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
        'pos_x': posX,
        'pos_y': posY,
        'width': width,
        'height': height,
        'group_id': groupId,
        'current_order_id': currentOrderId,
        'number_of_people': numberOfPeople,
        'reserved_at': reservedAt?.toIso8601String(),
        'reserved_by': reservedBy,
      };

  TableModel copyWith({
    String? id,
    String? name,
    int? capacity,
    TableStatus? status,
    double? posX,
    double? posY,
    double? width,
    double? height,
    String? groupId,
    String? currentOrderId,
    int? numberOfPeople,
    DateTime? reservedAt,
    String? reservedBy,
  }) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      width: width ?? this.width,
      height: height ?? this.height,
      groupId: groupId ?? this.groupId,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
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
        posX,
        posY,
        width,
        height,
        groupId,
        currentOrderId,
        numberOfPeople,
        reservedAt,
        reservedBy,
      ];
}
