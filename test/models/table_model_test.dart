import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/tables/data/models/table_model.dart';

void main() {
  group('TableModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'table-1',
        'name': 'T1',
        'capacity': 4,
        'status': 'available',
        'current_order_id': null,
        'number_of_people': null,
        'reserved_by': null,
      };

      final table = TableModel.fromJson(json);
      expect(table.id, 'table-1');
      expect(table.name, 'T1');
      expect(table.capacity, 4);
      expect(table.status, TableStatus.available);
    });

    test('fromJson parses occupied status', () {
      final json = {
        'id': 'table-1',
        'name': 'T1',
        'capacity': 4,
        'status': 'occupied',
        'current_order_id': 'order-123',
        'number_of_people': 3,
      };

      final table = TableModel.fromJson(json);
      expect(table.status, TableStatus.occupied);
      expect(table.currentOrderId, 'order-123');
      expect(table.numberOfPeople, 3);
    });

    test('fromJson parses reserved status', () {
      final json = {
        'id': 'table-1',
        'name': 'T1',
        'capacity': 4,
        'status': 'reserved',
        'reserved_by': 'Mario Rossi',
      };

      final table = TableModel.fromJson(json);
      expect(table.status, TableStatus.reserved);
      expect(table.reservedBy, 'Mario Rossi');
    });

    test('toJson serializes correctly', () {
      const table = TableModel(
        id: 'table-1',
        name: 'T1',
        capacity: 4,
        status: TableStatus.occupied,
        currentOrderId: 'order-123',
        numberOfPeople: 3,
      );

      final json = table.toJson();
      expect(json['id'], 'table-1');
      expect(json['status'], 'occupied');
      expect(json['current_order_id'], 'order-123');
    });

    test('copyWith creates new instance with updated values', () {
      const original = TableModel(
        id: 'table-1',
        name: 'T1',
        capacity: 4,
        status: TableStatus.available,
      );

      final updated = original.copyWith(
        status: TableStatus.occupied,
        numberOfPeople: 2,
      );

      expect(updated.id, 'table-1');
      expect(updated.status, TableStatus.occupied);
      expect(updated.numberOfPeople, 2);
      // Original unchanged
      expect(original.status, TableStatus.available);
    });
  });
}
