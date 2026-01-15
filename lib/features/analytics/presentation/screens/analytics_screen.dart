import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../data/models/daily_summary_model.dart';
import '../providers/analytics_provider.dart';

enum ViewMode { day, month, year }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  ViewMode _viewMode = ViewMode.month;
  late DateTime _selectedDate;
  
  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analytics),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: l10n.exportExcel,
            onPressed: () => _exportToExcel(context, ref, l10n),
          ),
        ],
      ),
      body: Column(
        children: [
          // View mode selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<ViewMode>(
                    segments: [
                      ButtonSegment(value: ViewMode.day, label: Text(l10n.daily)),
                      ButtonSegment(value: ViewMode.month, label: Text(l10n.monthly)),
                      ButtonSegment(value: ViewMode.year, label: Text(l10n.yearly)),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (modes) {
                      setState(() => _viewMode = modes.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          // Date selector
          _buildDateSelector(l10n),
          const Divider(),
          // Content
          Expanded(
            child: analyticsAsync.when(
              data: (summaries) => _buildContent(summaries, l10n),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(AppLocalizations l10n) {
    final dateFormat = switch (_viewMode) {
      ViewMode.day => DateFormat('d MMMM yyyy', 'it'),
      ViewMode.month => DateFormat('MMMM yyyy', 'it'),
      ViewMode.year => DateFormat('yyyy'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeDate(-1),
          ),
          TextButton(
            onPressed: () => _selectDate(context),
            child: Text(
              dateFormat.format(_selectedDate),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  void _changeDate(int delta) {
    setState(() {
      switch (_viewMode) {
        case ViewMode.day:
          _selectedDate = _selectedDate.add(Duration(days: delta));
        case ViewMode.month:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + delta);
        case ViewMode.year:
          _selectedDate = DateTime(_selectedDate.year + delta);
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_viewMode == ViewMode.day) {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (picked != null) setState(() => _selectedDate = picked);
    }
  }

  Widget _buildContent(List<DailySummaryModel> allSummaries, AppLocalizations l10n) {
    final notifier = ref.read(analyticsProvider.notifier);
    
    List<DailySummaryModel> filteredSummaries;
    Map<String, dynamic> totals;

    switch (_viewMode) {
      case ViewMode.day:
        filteredSummaries = allSummaries.where((s) =>
          s.date.year == _selectedDate.year &&
          s.date.month == _selectedDate.month &&
          s.date.day == _selectedDate.day
        ).toList();
        totals = notifier.calculateTotals(filteredSummaries);
      case ViewMode.month:
        filteredSummaries = notifier.getSummariesForMonth(_selectedDate.year, _selectedDate.month);
        totals = notifier.calculateTotals(filteredSummaries);
      case ViewMode.year:
        filteredSummaries = notifier.getSummariesForYear(_selectedDate.year);
        totals = notifier.calculateTotals(filteredSummaries);
    }

    if (filteredSummaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(l10n.noDataToday, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main stats
          _StatCard(
            icon: Icons.euro,
            label: l10n.totalRevenue,
            value: '€${(totals['totalRevenue'] as double).toStringAsFixed(2)}',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.receipt_long,
                  label: l10n.paidOrders,
                  value: '${totals['orderCount']}',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.people,
                  label: l10n.totalCovers,
                  value: '${totals['totalCovers']}',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.table_restaurant,
                  label: l10n.tableOrdersLabel,
                  value: '${totals['tableOrders']}',
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.takeout_dining,
                  label: l10n.takeawayOrdersLabel,
                  value: '${totals['takeawayOrders']}',
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.analytics,
            label: l10n.averagePerOrder,
            value: '€${(totals['averagePerOrder'] as double).toStringAsFixed(2)}',
            color: Colors.purple,
          ),
          
          // Top dishes
          if ((totals['topDishes'] as List).isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              l10n.topDishes,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: (totals['topDishes'] as List<DishCount>).length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final dish = (totals['topDishes'] as List<DishCount>)[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: index == 0 ? Colors.amber :
                                       index == 1 ? Colors.grey.shade400 :
                                       index == 2 ? Colors.brown.shade300 :
                                       Colors.grey.shade200,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: index < 3 ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                    title: Text(dish.name),
                    trailing: Text(
                      '×${dish.count}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  );
                },
              ),
            ),
          ],

          // Daily breakdown for month/year view
          if (_viewMode != ViewMode.day && filteredSummaries.length > 1) ...[
            const SizedBox(height: 24),
            Text(
              l10n.revenueTrend,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _RevenueChart(
              summaries: filteredSummaries,
              viewMode: _viewMode,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.dailyBreakdown,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredSummaries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final summary = filteredSummaries[index];
                  return ListTile(
                    title: Text(DateFormat('EEEE d MMMM', 'it').format(summary.date)),
                    subtitle: Text('${summary.orderCount} ${l10n.orders.toLowerCase()} • ${summary.totalCovers} ${l10n.totalCovers.toLowerCase()}'),
                    trailing: Text(
                      '€${summary.totalRevenue.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _exportToExcel(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final summaries = ref.read(analyticsProvider).value ?? [];
    if (summaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noDataToday)),
      );
      return;
    }

    try {
      final excel = xl.Excel.createExcel();
      
      // ===== FOGLIO 1: Riepilogo Giornaliero =====
      final summarySheet = excel['Riepilogo Giornaliero'];
      summarySheet.appendRow([
        xl.TextCellValue('Data'),
        xl.TextCellValue('Giorno'),
        xl.TextCellValue('Incasso (€)'),
        xl.TextCellValue('N. Ordini'),
        xl.TextCellValue('Coperti'),
        xl.TextCellValue('Media/Ordine (€)'),
        xl.TextCellValue('Ordini Tavolo'),
        xl.TextCellValue('Ordini Asporto'),
      ]);
      for (final s in summaries) {
        summarySheet.appendRow([
          xl.TextCellValue(DateFormat('dd/MM/yyyy').format(s.date)),
          xl.TextCellValue(DateFormat('EEEE', 'it').format(s.date)),
          xl.DoubleCellValue(s.totalRevenue),
          xl.IntCellValue(s.orderCount),
          xl.IntCellValue(s.totalCovers),
          xl.DoubleCellValue(s.averagePerOrder),
          xl.IntCellValue(s.tableOrders),
          xl.IntCellValue(s.takeawayOrders),
        ]);
      }

      // ===== FOGLIO 2: Dettaglio Piatti per Giorno =====
      final dishesSheet = excel['Vendite Piatti'];
      dishesSheet.appendRow([
        xl.TextCellValue('Data'),
        xl.TextCellValue('Piatto'),
        xl.TextCellValue('Categoria'),
        xl.TextCellValue('Quantità'),
        xl.TextCellValue('Prezzo Unit. (€)'),
        xl.TextCellValue('Ricavo (€)'),
      ]);
      for (final s in summaries) {
        for (final dish in s.dishSales) {
          dishesSheet.appendRow([
            xl.TextCellValue(DateFormat('dd/MM/yyyy').format(s.date)),
            xl.TextCellValue(dish.name),
            xl.TextCellValue(dish.category),
            xl.IntCellValue(dish.quantity),
            xl.DoubleCellValue(dish.unitPrice),
            xl.DoubleCellValue(dish.totalRevenue),
          ]);
        }
      }

      // ===== FOGLIO 3: Aggregato per Piatto =====
      final aggDishSheet = excel['Totale per Piatto'];
      aggDishSheet.appendRow([
        xl.TextCellValue('Piatto'),
        xl.TextCellValue('Categoria'),
        xl.TextCellValue('Quantità Totale'),
        xl.TextCellValue('Ricavo Totale (€)'),
        xl.TextCellValue('N. Giorni Venduto'),
      ]);
      // Aggrega tutti i piatti
      final dishAgg = <String, Map<String, dynamic>>{};
      for (final s in summaries) {
        for (final dish in s.dishSales) {
          if (!dishAgg.containsKey(dish.name)) {
            dishAgg[dish.name] = {
              'category': dish.category,
              'quantity': 0,
              'revenue': 0.0,
              'days': 0,
            };
          }
          dishAgg[dish.name]!['quantity'] = 
              (dishAgg[dish.name]!['quantity'] as int) + dish.quantity;
          dishAgg[dish.name]!['revenue'] = 
              (dishAgg[dish.name]!['revenue'] as double) + dish.totalRevenue;
          dishAgg[dish.name]!['days'] = 
              (dishAgg[dish.name]!['days'] as int) + 1;
        }
      }
      final sortedDishes = dishAgg.entries.toList()
        ..sort((a, b) => (b.value['quantity'] as int).compareTo(a.value['quantity'] as int));
      for (final entry in sortedDishes) {
        aggDishSheet.appendRow([
          xl.TextCellValue(entry.key),
          xl.TextCellValue(entry.value['category'] as String),
          xl.IntCellValue(entry.value['quantity'] as int),
          xl.DoubleCellValue(entry.value['revenue'] as double),
          xl.IntCellValue(entry.value['days'] as int),
        ]);
      }

      // ===== FOGLIO 4: Aggregato per Categoria =====
      final catSheet = excel['Totale per Categoria'];
      catSheet.appendRow([
        xl.TextCellValue('Categoria'),
        xl.TextCellValue('Quantità Totale'),
        xl.TextCellValue('Ricavo Totale (€)'),
        xl.TextCellValue('% Ricavo'),
      ]);
      final catAgg = <String, Map<String, dynamic>>{};
      double totalRev = 0;
      for (final s in summaries) {
        for (final dish in s.dishSales) {
          final cat = dish.category.isEmpty ? 'Altro' : dish.category;
          if (!catAgg.containsKey(cat)) {
            catAgg[cat] = {'quantity': 0, 'revenue': 0.0};
          }
          catAgg[cat]!['quantity'] = (catAgg[cat]!['quantity'] as int) + dish.quantity;
          catAgg[cat]!['revenue'] = (catAgg[cat]!['revenue'] as double) + dish.totalRevenue;
          totalRev += dish.totalRevenue;
        }
      }
      final sortedCats = catAgg.entries.toList()
        ..sort((a, b) => (b.value['revenue'] as double).compareTo(a.value['revenue'] as double));
      for (final entry in sortedCats) {
        final pct = totalRev > 0 ? (entry.value['revenue'] as double) / totalRev * 100 : 0.0;
        catSheet.appendRow([
          xl.TextCellValue(entry.key),
          xl.IntCellValue(entry.value['quantity'] as int),
          xl.DoubleCellValue(entry.value['revenue'] as double),
          xl.TextCellValue('${pct.toStringAsFixed(1)}%'),
        ]);
      }

      // ===== FOGLIO 5: Riepilogo Mensile =====
      final monthSheet = excel['Riepilogo Mensile'];
      monthSheet.appendRow([
        xl.TextCellValue('Mese'),
        xl.TextCellValue('Incasso (€)'),
        xl.TextCellValue('N. Ordini'),
        xl.TextCellValue('Coperti'),
        xl.TextCellValue('Media/Ordine (€)'),
        xl.TextCellValue('Giorni Lavorati'),
      ]);
      final monthAgg = <String, Map<String, dynamic>>{};
      for (final s in summaries) {
        final monthKey = DateFormat('yyyy-MM').format(s.date);
        final monthLabel = DateFormat('MMMM yyyy', 'it').format(s.date);
        if (!monthAgg.containsKey(monthKey)) {
          monthAgg[monthKey] = {
            'label': monthLabel,
            'revenue': 0.0,
            'orders': 0,
            'covers': 0,
            'days': 0,
          };
        }
        monthAgg[monthKey]!['revenue'] = (monthAgg[monthKey]!['revenue'] as double) + s.totalRevenue;
        monthAgg[monthKey]!['orders'] = (monthAgg[monthKey]!['orders'] as int) + s.orderCount;
        monthAgg[monthKey]!['covers'] = (monthAgg[monthKey]!['covers'] as int) + s.totalCovers;
        monthAgg[monthKey]!['days'] = (monthAgg[monthKey]!['days'] as int) + 1;
      }
      final sortedMonths = monthAgg.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key));
      for (final entry in sortedMonths) {
        final orders = entry.value['orders'] as int;
        final revenue = entry.value['revenue'] as double;
        monthSheet.appendRow([
          xl.TextCellValue(entry.value['label'] as String),
          xl.DoubleCellValue(revenue),
          xl.IntCellValue(orders),
          xl.IntCellValue(entry.value['covers'] as int),
          xl.DoubleCellValue(orders > 0 ? revenue / orders : 0),
          xl.IntCellValue(entry.value['days'] as int),
        ]);
      }

      // Remove default sheet
      excel.delete('Sheet1');

      // Save file
      final bytes = excel.save();
      if (bytes != null) {
        final fileName = 'XinXing_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
        final downloadsDir = Directory('/storage/emulated/0/Download');
        final file = File('${downloadsDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.exportSuccess}: $fileName')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.exportError}: $e')),
        );
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/// Grafico di andamento incassi
class _RevenueChart extends StatelessWidget {
  final List<DailySummaryModel> summaries;
  final ViewMode viewMode;

  const _RevenueChart({
    required this.summaries,
    required this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedSummaries = List<DailySummaryModel>.from(summaries)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Prepara i dati per il grafico
    final spots = <FlSpot>[];
    final labels = <int, String>{};
    
    for (int i = 0; i < sortedSummaries.length; i++) {
      final summary = sortedSummaries[i];
      spots.add(FlSpot(i.toDouble(), summary.totalRevenue));
      
      // Label per l'asse X
      if (viewMode == ViewMode.month) {
        labels[i] = summary.date.day.toString();
      } else {
        labels[i] = DateFormat('MMM', 'it').format(summary.date);
      }
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;
    final chartMaxY = maxY + (range * 0.1);
    final chartMinY = (minY - (range * 0.1)).clamp(0.0, double.infinity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: range > 0 ? range / 4 : 100,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '€${value.toInt()}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: viewMode == ViewMode.month 
                        ? (sortedSummaries.length / 6).ceilToDouble().clamp(1, 10)
                        : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= sortedSummaries.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[index] ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (sortedSummaries.length - 1).toDouble(),
              minY: chartMinY,
              maxY: chartMaxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: sortedSummaries.length <= 15,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.green,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.15),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => isDark ? Colors.grey.shade800 : Colors.white,
                  tooltipBorder: BorderSide(color: Colors.grey.shade400),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      if (index < 0 || index >= sortedSummaries.length) return null;
                      final summary = sortedSummaries[index];
                      return LineTooltipItem(
                        '${DateFormat('d MMM', 'it').format(summary.date)}\n€${summary.totalRevenue.toStringAsFixed(2)}',
                        TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
