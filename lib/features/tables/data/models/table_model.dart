import 'package:equatable/equatable.dart';

enum TableStatus { available, occupied, reserved }

class TableModel extends Equatable {
  final String id;
  final String name;
  final int capacity;
  final TableStatus status;
  final String? currentOrderId;
  final int? numberOfPeople;
  final DateTime? reservedAt;
  final String? reservedBy;

  const TableModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.status,
    this.currentOrderId,
    this.numberOfPeople,
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
        currentOrderId,
        numberOfPeople,
        reservedAt,
        reservedBy,
      ];
}
