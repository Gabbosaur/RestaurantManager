import 'package:equatable/equatable.dart';

class DailySummaryModel extends Equatable {
  final String id;
  final DateTime date;
  final double totalRevenue;
  final int orderCount;
  final int totalCovers;
  final double averagePerOrder;
  final List<DishSale> dishSales; // Tutti i piatti venduti con dettagli
  final int tableOrders;
  final int takeawayOrders;
  final DateTime createdAt;

  const DailySummaryModel({
    required this.id,
    required this.date,
    required this.totalRevenue,
    required this.orderCount,
    required this.totalCovers,
    required this.averagePerOrder,
    required this.dishSales,
    required this.tableOrders,
    required this.takeawayOrders,
    required this.createdAt,
  });

  /// Top dishes ordinati per quantità
  List<DishCount> get topDishes {
    final sorted = List<DishSale>.from(dishSales)
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    return sorted.map((d) => DishCount(name: d.name, count: d.quantity)).toList();
  }

  factory DailySummaryModel.fromJson(Map<String, dynamic> json) {
    // Supporta sia il vecchio formato (top_dishes) che il nuovo (dish_sales)
    List<DishSale> sales = [];
    if (json['dish_sales'] != null) {
      sales = (json['dish_sales'] as List)
          .map((e) => DishSale.fromJson(e))
          .toList();
    } else if (json['top_dishes'] != null) {
      // Retrocompatibilità
      sales = (json['top_dishes'] as List)
          .map((e) => DishSale(
                name: e['name'],
                quantity: e['count'] ?? e['quantity'] ?? 0,
                unitPrice: 0,
                totalRevenue: 0,
                category: '',
              ))
          .toList();
    }

    return DailySummaryModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      orderCount: json['order_count'] ?? 0,
      totalCovers: json['total_covers'] ?? 0,
      averagePerOrder: (json['average_per_order'] ?? 0).toDouble(),
      dishSales: sales,
      tableOrders: json['table_orders'] ?? 0,
      takeawayOrders: json['takeaway_orders'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String().split('T')[0],
        'total_revenue': totalRevenue,
        'order_count': orderCount,
        'total_covers': totalCovers,
        'average_per_order': averagePerOrder,
        'dish_sales': dishSales.map((e) => e.toJson()).toList(),
        // Mantieni top_dishes per retrocompatibilità
        'top_dishes': topDishes.take(10).map((e) => e.toJson()).toList(),
        'table_orders': tableOrders,
        'takeaway_orders': takeawayOrders,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        date,
        totalRevenue,
        orderCount,
        totalCovers,
        averagePerOrder,
        dishSales,
        tableOrders,
        takeawayOrders,
        createdAt,
      ];
}

/// Dettaglio vendita piatto per analytics avanzate
class DishSale extends Equatable {
  final String name;
  final String category;
  final int quantity;
  final double unitPrice;
  final double totalRevenue;

  const DishSale({
    required this.name,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.totalRevenue,
  });

  factory DishSale.fromJson(Map<String, dynamic> json) {
    return DishSale(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_revenue': totalRevenue,
      };

  @override
  List<Object?> get props => [name, category, quantity, unitPrice, totalRevenue];
}

class DishCount extends Equatable {
  final String name;
  final int count;

  const DishCount({required this.name, required this.count});

  factory DishCount.fromJson(Map<String, dynamic> json) {
    return DishCount(
      name: json['name'],
      count: json['count'] ?? json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'count': count,
      };

  @override
  List<Object?> get props => [name, count];
}
