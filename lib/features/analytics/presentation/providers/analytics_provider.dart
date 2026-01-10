import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/daily_summary_model.dart';
import '../../../orders/data/models/order_model.dart';

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AsyncValue<List<DailySummaryModel>>>(
  (ref) => AnalyticsNotifier(),
);

class AnalyticsNotifier extends StateNotifier<AsyncValue<List<DailySummaryModel>>> {
  AnalyticsNotifier() : super(const AsyncValue.loading()) {
    loadSummaries();
  }

  final _supabase = Supabase.instance.client;

  Future<void> loadSummaries() async {
    try {
      final response = await _supabase
          .from('daily_summaries')
          .select()
          .order('date', ascending: false);

      final summaries = (response as List)
          .map((e) => DailySummaryModel.fromJson(e))
          .toList();

      state = AsyncValue.data(summaries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Salva il riepilogo giornaliero (chiamato da "Chiudi Giornata")
  /// [businessDate] è il giorno lavorativo (può essere diverso dalla data corrente se dopo mezzanotte)
  Future<void> saveDaySummary(List<OrderModel> paidOrders, DateTime businessDate) async {
    final dateStr = '${businessDate.year}-${businessDate.month.toString().padLeft(2, '0')}-${businessDate.day.toString().padLeft(2, '0')}';
    
    // Calcola statistiche
    final totalRevenue = paidOrders.fold<double>(0, (sum, o) => sum + o.total);
    final orderCount = paidOrders.length;
    final totalCovers = paidOrders.fold<int>(0, (sum, o) => sum + (o.numberOfPeople ?? 0));
    final avgPerOrder = orderCount > 0 ? totalRevenue / orderCount : 0.0;
    final tableOrders = paidOrders.where((o) => o.orderType == OrderType.table).length;
    final takeawayOrders = paidOrders.where((o) => o.orderType == OrderType.takeaway).length;
    
    // Dettaglio vendite piatti (tutti i piatti con quantità, prezzo, ricavo)
    final dishData = <String, Map<String, dynamic>>{};
    for (final order in paidOrders) {
      for (final item in order.items) {
        if (!dishData.containsKey(item.name)) {
          // Estrai categoria dal nome (es. "01. Antipasto" -> "Antipasti")
          final category = _extractCategory(item.name);
          dishData[item.name] = {
            'name': item.name,
            'category': category,
            'quantity': 0,
            'unit_price': item.price,
            'total_revenue': 0.0,
          };
        }
        dishData[item.name]!['quantity'] = 
            (dishData[item.name]!['quantity'] as int) + item.quantity;
        dishData[item.name]!['total_revenue'] = 
            (dishData[item.name]!['total_revenue'] as double) + (item.price * item.quantity);
      }
    }
    
    final dishSales = dishData.values.toList()
      ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
    
    // Top 10 per retrocompatibilità
    final top10 = dishSales.take(10).map((e) => {
      'name': e['name'],
      'count': e['quantity'],
    }).toList();

    try {
      // Upsert - aggiorna se esiste già per oggi
      await _supabase.from('daily_summaries').upsert({
        'id': const Uuid().v4(),
        'date': dateStr,
        'total_revenue': totalRevenue,
        'order_count': orderCount,
        'total_covers': totalCovers,
        'average_per_order': avgPerOrder,
        'dish_sales': dishSales,
        'top_dishes': top10,
        'table_orders': tableOrders,
        'takeaway_orders': takeawayOrders,
      }, onConflict: 'date');

      await loadSummaries();
    } catch (e) {
      rethrow;
    }
  }

  /// Estrae la categoria dal nome del piatto
  String _extractCategory(String dishName) {
    // Basato sul numero del piatto
    final match = RegExp(r'^(\d+)\.').firstMatch(dishName);
    if (match != null) {
      final num = int.tryParse(match.group(1) ?? '') ?? 0;
      if (num >= 1 && num <= 9) return 'Antipasti';
      if (num >= 10 && num <= 14) return 'Zuppe';
      if (num >= 21 && num <= 31) return 'Primi - Riso';
      if (num >= 32 && num <= 40) return 'Primi - Spaghetti';
      if (num >= 41 && num <= 45) return 'Primi - Ravioli';
      if (num >= 46 && num <= 49) return 'Secondi - Anatra';
      if (num >= 50 && num <= 56) return 'Secondi - Pollo';
      if (num >= 57 && num <= 59) return 'Secondi - Vitello';
      if (num >= 60 && num <= 64) return 'Secondi - Maiale';
      if (num >= 65 && num <= 71) return 'Secondi - Gamberi';
      if (num >= 72 && num <= 78) return 'Secondi - Pesce';
      if (num >= 81 && num <= 90) return 'Contorni';
      if (num >= 91 && num <= 98) return 'Dolci';
    }
    // Bevande
    if (dishName.contains('Vino') || dishName.contains('Birra')) return 'Bevande';
    if (dishName.contains('Acqua') || dishName.contains('Coca') || 
        dishName.contains('Fanta') || dishName.contains('Sprite') ||
        dishName.contains('Tè') || dishName.contains('Estathé')) return 'Bevande';
    if (dishName.contains('Sakè') || dishName.contains('Liquore') || 
        dishName.contains('Caffè') || dishName.contains('Cappuccino')) return 'Bevande';
    return 'Altro';
  }

  /// Ottiene i riepiloghi per un mese specifico
  List<DailySummaryModel> getSummariesForMonth(int year, int month) {
    return state.value?.where((s) => 
      s.date.year == year && s.date.month == month
    ).toList() ?? [];
  }

  /// Ottiene i riepiloghi per un anno specifico
  List<DailySummaryModel> getSummariesForYear(int year) {
    return state.value?.where((s) => s.date.year == year).toList() ?? [];
  }

  /// Calcola totali per un periodo
  Map<String, dynamic> calculateTotals(List<DailySummaryModel> summaries) {
    if (summaries.isEmpty) {
      return {
        'totalRevenue': 0.0,
        'orderCount': 0,
        'totalCovers': 0,
        'averagePerOrder': 0.0,
        'tableOrders': 0,
        'takeawayOrders': 0,
        'topDishes': <DishCount>[],
      };
    }

    final totalRevenue = summaries.fold<double>(0, (sum, s) => sum + s.totalRevenue);
    final orderCount = summaries.fold<int>(0, (sum, s) => sum + s.orderCount);
    final totalCovers = summaries.fold<int>(0, (sum, s) => sum + s.totalCovers);
    final tableOrders = summaries.fold<int>(0, (sum, s) => sum + s.tableOrders);
    final takeawayOrders = summaries.fold<int>(0, (sum, s) => sum + s.takeawayOrders);

    // Aggrega top dishes
    final dishCount = <String, int>{};
    for (final summary in summaries) {
      for (final dish in summary.topDishes) {
        dishCount[dish.name] = (dishCount[dish.name] ?? 0) + dish.count;
      }
    }
    final topDishes = dishCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top10 = topDishes.take(10).map((e) => DishCount(name: e.key, count: e.value)).toList();

    return {
      'totalRevenue': totalRevenue,
      'orderCount': orderCount,
      'totalCovers': totalCovers,
      'averagePerOrder': orderCount > 0 ? totalRevenue / orderCount : 0.0,
      'tableOrders': tableOrders,
      'takeawayOrders': takeawayOrders,
      'topDishes': top10,
    };
  }
}
