import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/orders/data/models/order_model.dart';

void main() {
  group('OrderModel', () {
    final testOrder = OrderModel(
      id: 'test-id',
      tableId: 'table-1',
      tableName: 'T1',
      orderType: OrderType.table,
      numberOfPeople: 4,
      items: [
        const OrderItem(
          menuItemId: 'item-1',
          name: 'Pasta',
          nameZh: '意大利面',
          category: 'Primi',
          quantity: 2,
          price: 8.0,
        ),
        const OrderItem(
          menuItemId: 'item-2',
          name: 'Coca Cola',
          category: 'Bevande',
          quantity: 3,
          price: 3.0,
        ),
      ],
      status: OrderStatus.pending,
      total: 25.0,
      servedQuantities: {'item-1': 1},
      createdAt: DateTime(2024, 1, 15, 20, 30),
      updatedAt: DateTime(2024, 1, 15, 20, 30),
    );

    test('isTakeaway returns false for table orders', () {
      expect(testOrder.isTakeaway, false);
    });

    test('isTakeaway returns true for takeaway orders', () {
      final takeaway = testOrder.copyWith(orderType: OrderType.takeaway);
      expect(takeaway.isTakeaway, true);
    });

    test('getServedQuantity returns correct value', () {
      expect(testOrder.getServedQuantity('item-1'), 1);
      expect(testOrder.getServedQuantity('item-2'), 0);
      expect(testOrder.getServedQuantity('non-existent'), 0);
    });

    test('isItemFullyServed returns correct value', () {
      expect(testOrder.isItemFullyServed('item-1'), false); // 1/2 served
      expect(testOrder.isItemFullyServed('item-2'), false); // 0/3 served
    });

    test('getRemainingToServe returns correct value', () {
      expect(testOrder.getRemainingToServe('item-1'), 1); // 2-1=1
      expect(testOrder.getRemainingToServe('item-2'), 3); // 3-0=3
    });

    test('isFullyServed returns false when items remain', () {
      expect(testOrder.isFullyServed, false);
    });

    test('isFullyServed returns true when all served', () {
      final fullyServed = testOrder.copyWith(
        servedQuantities: {'item-1': 2, 'item-2': 3},
      );
      expect(fullyServed.isFullyServed, true);
    });

    test('fromJson parses correctly', () {
      final json = {
        'id': 'test-id',
        'table_id': 'table-1',
        'table_name': 'T1',
        'order_type': 'table',
        'number_of_people': 4,
        'items': [
          {'menu_item_id': 'item-1', 'name': 'Pasta', 'quantity': 2, 'price': 8.0},
        ],
        'status': 'pending',
        'total': 16.0,
        'is_modified': false,
        'served_items': {'item-1': 1},
        'created_at': '2024-01-15T20:30:00.000',
        'updated_at': '2024-01-15T20:30:00.000',
      };

      final order = OrderModel.fromJson(json);
      expect(order.id, 'test-id');
      expect(order.tableName, 'T1');
      expect(order.status, OrderStatus.pending);
      expect(order.servedQuantities['item-1'], 1);
    });

    test('toJson serializes correctly', () {
      final json = testOrder.toJson();
      expect(json['id'], 'test-id');
      expect(json['order_type'], 'table');
      expect(json['status'], 'pending');
      expect(json['served_items'], {'item-1': 1});
    });
  });

  group('OrderItem', () {
    test('isBeverage returns true for beverage category', () {
      const beverage = OrderItem(
        menuItemId: '1',
        name: 'Coca Cola',
        category: 'Bevande',
        quantity: 1,
        price: 3.0,
      );
      expect(beverage.isBeverage, true);
    });

    test('isBeverage returns false for food category', () {
      const food = OrderItem(
        menuItemId: '1',
        name: 'Pasta',
        category: 'Primi',
        quantity: 1,
        price: 8.0,
      );
      expect(food.isBeverage, false);
    });

    test('displayNameZh returns Chinese name when available', () {
      const item = OrderItem(
        menuItemId: '1',
        name: 'Pasta',
        nameZh: '意大利面',
        quantity: 1,
        price: 8.0,
      );
      expect(item.displayNameZh, '意大利面');
    });

    test('displayNameZh returns Italian name when Chinese not available', () {
      const item = OrderItem(
        menuItemId: '1',
        name: 'Pasta',
        quantity: 1,
        price: 8.0,
      );
      expect(item.displayNameZh, 'Pasta');
    });
  });

  group('OrderChange', () {
    test('isAddition returns true for positive quantity', () {
      final change = OrderChange(
        name: 'Pasta',
        quantity: 2,
        timestamp: DateTime.now(),
      );
      expect(change.isAddition, true);
      expect(change.isRemoval, false);
    });

    test('isRemoval returns true for negative quantity', () {
      final change = OrderChange(
        name: 'Pasta',
        quantity: -1,
        timestamp: DateTime.now(),
      );
      expect(change.isAddition, false);
      expect(change.isRemoval, true);
    });
  });
}
