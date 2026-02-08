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
    final language = ref.watch(languageProvider);
    
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

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calcola dati aggiuntivi
    final comparison = _viewMode != ViewMode.day 
        ? notifier.calculatePreviousPeriodComparison(
            _selectedDate.year, 
            _selectedDate.month,
            isYearly: _viewMode == ViewMode.year,
          )
        : null;
    final categoryBreakdown = notifier.calculateCategoryBreakdown(filteredSummaries);
    final bestDay = notifier.calculateBestDayOfWeek(filteredSummaries);
    final weekdayStats = notifier.calculateWeekdayStats(filteredSummaries);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GRAFICO IN ALTO (solo per month/year con più dati)
          if (_viewMode != ViewMode.day && filteredSummaries.length > 1) ...[
            _RevenueChart(
              summaries: filteredSummaries,
              viewMode: _viewMode,
              language: ref.watch(languageProvider),
            ),
            const SizedBox(height: 16),
          ],

          // STATS PRINCIPALI - Layout adattivo
          if (isLandscape || screenWidth > 600)
            // Layout orizzontale per landscape/tablet
            _buildWideStatsLayout(totals, l10n, comparison)
          else
            // Layout verticale per portrait/mobile
            _buildCompactStatsLayout(totals, l10n, comparison),
          
          // NUOVE SEZIONI: Categorie e Giorno migliore
          if (_viewMode != ViewMode.day && filteredSummaries.length > 1) ...[
            const SizedBox(height: 16),
            if (isLandscape && screenWidth > 800)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (categoryBreakdown.isNotEmpty)
                    Expanded(child: _buildCategoryPieChart(categoryBreakdown, l10n)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildWeekdayChart(weekdayStats, bestDay, l10n, language)),
                ],
              )
            else ...[
              if (categoryBreakdown.isNotEmpty)
                _buildCategoryPieChart(categoryBreakdown, l10n),
              const SizedBox(height: 16),
              _buildWeekdayChart(weekdayStats, bestDay, l10n, language),
            ],
          ],
          
          // TOP DISHES (solo se ci sono dati)
          if ((totals['topDishes'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTopDishesCard(totals, l10n),
          ],
        ],
      ),
    );
  }

  /// Layout compatto per stats (portrait/mobile)
  Widget _buildCompactStatsLayout(Map<String, dynamic> totals, AppLocalizations l10n, double? comparison) {
    return Column(
      children: [
        // Incasso totale grande con confronto
        _StatCardWithComparison(
          icon: Icons.euro,
          label: l10n.totalRevenue,
          value: '€${(totals['totalRevenue'] as double).toStringAsFixed(2)}',
          color: Colors.green,
          comparison: comparison,
          l10n: l10n,
        ),
        const SizedBox(height: 8),
        // Griglia 2x2 per le altre stats
        Row(
          children: [
            Expanded(child: _MiniStatCard(
              icon: Icons.receipt_long,
              label: l10n.paidOrders,
              value: '${totals['orderCount']}',
              color: Colors.blue,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MiniStatCard(
              icon: Icons.people,
              label: l10n.totalCovers,
              value: '${totals['totalCovers']}',
              color: Colors.orange,
            )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _MiniStatCard(
              icon: Icons.table_restaurant,
              label: l10n.tableOrdersLabel,
              value: '${totals['tableOrders']}',
              color: Colors.teal,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MiniStatCard(
              icon: Icons.takeout_dining,
              label: l10n.takeawayOrdersLabel,
              value: '${totals['takeawayOrders']}',
              color: Colors.deepPurple,
            )),
          ],
        ),
        const SizedBox(height: 8),
        _MiniStatCard(
          icon: Icons.analytics,
          label: l10n.averagePerOrder,
          value: '€${(totals['averagePerOrder'] as double).toStringAsFixed(2)}',
          color: Colors.purple,
        ),
      ],
    );
  }

  /// Layout wide per stats (landscape/tablet)
  Widget _buildWideStatsLayout(Map<String, dynamic> totals, AppLocalizations l10n, double? comparison) {
    return Column(
      children: [
        // Prima riga: Incasso + Media
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _StatCardWithComparison(
                icon: Icons.euro,
                label: l10n.totalRevenue,
                value: '€${(totals['totalRevenue'] as double).toStringAsFixed(2)}',
                color: Colors.green,
                comparison: comparison,
                l10n: l10n,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStatCard(
                icon: Icons.analytics,
                label: l10n.averagePerOrder,
                value: '€${(totals['averagePerOrder'] as double).toStringAsFixed(2)}',
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Seconda riga: 4 stats compatte
        Row(
          children: [
            Expanded(child: _MiniStatCard(
              icon: Icons.receipt_long,
              label: l10n.paidOrders,
              value: '${totals['orderCount']}',
              color: Colors.blue,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MiniStatCard(
              icon: Icons.people,
              label: l10n.totalCovers,
              value: '${totals['totalCovers']}',
              color: Colors.orange,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MiniStatCard(
              icon: Icons.table_restaurant,
              label: l10n.tableOrdersLabel,
              value: '${totals['tableOrders']}',
              color: Colors.teal,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MiniStatCard(
              icon: Icons.takeout_dining,
              label: l10n.takeawayOrdersLabel,
              value: '${totals['takeawayOrders']}',
              color: Colors.deepPurple,
            )),
          ],
        ),
      ],
    );
  }

  /// Card per top dishes
  Widget _buildTopDishesCard(Map<String, dynamic> totals, AppLocalizations l10n) {
    final topDishes = totals['topDishes'] as List<DishCount>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, size: 18, color: Colors.amber),
              const SizedBox(width: 6),
              Text(
                l10n.topDishes,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topDishes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final dish = topDishes[index];
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: index == 0 ? Colors.amber :
                                   index == 1 ? Colors.grey.shade400 :
                                   index == 2 ? Colors.brown.shade300 :
                                   Colors.grey.shade200,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: index < 3 ? Colors.white : Colors.black54,
                    ),
                  ),
                ),
                title: Text(dish.name, style: const TextStyle(fontSize: 14)),
                trailing: Text(
                  '×${dish.count}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Grafico a torta per categorie
  Widget _buildCategoryPieChart(Map<String, double> categoryBreakdown, AppLocalizations l10n) {
    final total = categoryBreakdown.values.fold<double>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    // Colori per categorie
    final categoryColors = <String, Color>{
      'Antipasti': Colors.orange,
      'Zuppe': Colors.brown,
      'Primi - Riso': Colors.amber,
      'Primi - Spaghetti': Colors.yellow.shade700,
      'Primi - Ravioli': Colors.lime,
      'Secondi - Anatra': Colors.red,
      'Secondi - Pollo': Colors.pink,
      'Secondi - Vitello': Colors.purple,
      'Secondi - Maiale': Colors.deepPurple,
      'Secondi - Gamberi': Colors.indigo,
      'Secondi - Pesce': Colors.blue,
      'Contorni': Colors.green,
      'Dolci': Colors.teal,
      'Bevande': Colors.cyan,
      'Altro': Colors.grey,
    };

    final sortedCategories = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = sortedCategories.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = categoryColors[entry.key] ?? Colors.grey;
      return PieChartSectionData(
        value: entry.value,
        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.pie_chart, size: 18, color: Colors.purple),
              const SizedBox(width: 6),
              Text(
                l10n.categoryBreakdown,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Pie chart
                SizedBox(
                  height: 140,
                  width: 140,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 20,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Legenda
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedCategories.take(6).map((entry) {
                      final percentage = (entry.value / total) * 100;
                      final color = categoryColors[entry.key] ?? Colors.grey;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Grafico a barre per giorni della settimana
  Widget _buildWeekdayChart(
    List<Map<String, dynamic>> weekdayStats, 
    Map<String, dynamic>? bestDay,
    AppLocalizations l10n,
    AppLanguage language,
  ) {
    final maxAvg = weekdayStats.map((s) => s['avgRevenue'] as double).reduce((a, b) => a > b ? a : b);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.calendar_view_week, size: 18, color: Colors.orange),
              const SizedBox(width: 6),
              Text(
                l10n.bestDayOfWeek,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (bestDay != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.dayOfWeekFull(bestDay['weekday'] as int),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxAvg > 0 ? maxAvg * 1.2 : 100,
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final weekday = value.toInt() + 1;
                          if (weekday < 1 || weekday > 7) return const SizedBox.shrink();
                          return Text(
                            l10n.dayOfWeek(weekday),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: bestDay != null && bestDay['weekday'] == weekday 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              color: bestDay != null && bestDay['weekday'] == weekday
                                  ? Colors.orange
                                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: weekdayStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stat = entry.value;
                    final weekday = stat['weekday'] as int;
                    final avgRevenue = stat['avgRevenue'] as double;
                    final isBest = bestDay != null && bestDay['weekday'] == weekday;
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: avgRevenue,
                          color: isBest ? Colors.orange : Colors.blue.shade300,
                          width: 24,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => isDark ? Colors.grey.shade800 : Colors.white,
                      tooltipBorder: BorderSide(color: Colors.grey.shade400),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final stat = weekdayStats[groupIndex];
                        final weekday = stat['weekday'] as int;
                        final avgRevenue = stat['avgRevenue'] as double;
                        final daysCount = stat['daysCount'] as int;
                        return BarTooltipItem(
                          '${l10n.dayOfWeekFull(weekday)}\n'
                          '${l10n.avgRevenue}: €${avgRevenue.toStringAsFixed(0)}\n'
                          '$daysCount ${daysCount == 1 ? 'giorno' : 'giorni'}',
                          TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
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

/// Card compatta per stats secondarie
class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
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

/// Card con confronto periodo precedente
class _StatCardWithComparison extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double? comparison;
  final AppLocalizations l10n;

  const _StatCardWithComparison({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.l10n,
    this.comparison,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (comparison != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        comparison! >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: comparison! >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comparison! >= 0 ? '+' : ''}${comparison!.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: comparison! >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.comparedToPrevious,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/// Grafico a barre di andamento incassi
class _RevenueChart extends StatelessWidget {
  final List<DailySummaryModel> summaries;
  final ViewMode viewMode;
  final AppLanguage language;

  const _RevenueChart({
    required this.summaries,
    required this.viewMode,
    required this.language,
  });

  String get _locale => switch (language) {
    AppLanguage.italian => 'it',
    AppLanguage.english => 'en',
    AppLanguage.chinese => 'zh',
  };

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (viewMode == ViewMode.year) {
      return _buildYearlyChart(context, isDark);
    } else {
      return _buildMonthlyChart(context, isDark);
    }
  }

  /// Grafico mensile - mostra tutti i giorni del mese
  Widget _buildMonthlyChart(BuildContext context, bool isDark) {
    // Crea mappa data -> summary per lookup veloce
    final summaryMap = <String, DailySummaryModel>{};
    for (final s in summaries) {
      final key = '${s.date.year}-${s.date.month}-${s.date.day}';
      summaryMap[key] = s;
    }

    // Tutti i giorni del mese selezionato
    final firstDay = summaries.first.date;
    final year = firstDay.year;
    final month = firstDay.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final allDays = List.generate(daysInMonth, (i) => DateTime(year, month, i + 1));

    // Prepara i dati per il bar chart
    final barGroups = <BarChartGroupData>[];
    final dayData = <int, DailySummaryModel?>{};
    double maxY = 0;

    for (int i = 0; i < allDays.length; i++) {
      final day = allDays[i];
      final key = '${day.year}-${day.month}-${day.day}';
      final summary = summaryMap[key];
      dayData[i] = summary;
      
      final revenue = summary?.totalRevenue ?? 0;
      if (revenue > maxY) maxY = revenue;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: revenue,
              color: summary != null ? Colors.green : Colors.grey.shade300,
              width: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    final chartMaxY = maxY * 1.1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: chartMaxY,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? maxY / 4 : 100,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        '€${value.toInt()}',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= allDays.length) {
                        return const SizedBox.shrink();
                      }
                      final day = allDays[index].day;
                      // Mostra 1, 5, 10, 15, 20, 25, ultimo
                      if (day != 1 && day != 5 && day != 10 && day != 15 && 
                          day != 20 && day != 25 && index != allDays.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => isDark ? Colors.grey.shade800 : Colors.white,
                  tooltipBorder: BorderSide(color: Colors.grey.shade400),
                  tooltipPadding: const EdgeInsets.all(8),
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final index = group.x;
                    if (index < 0 || index >= allDays.length) return null;
                    
                    final day = allDays[index];
                    final summary = dayData[index];
                    final textColor = isDark ? Colors.white : Colors.black87;
                    
                    if (summary == null) {
                      return BarTooltipItem(
                        '${DateFormat('EEE d MMM', _locale).format(day)}\nNessun dato',
                        TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      );
                    }
                    
                    return BarTooltipItem(
                      '${DateFormat('EEE d MMM', _locale).format(summary.date)}\n'
                      '€${summary.totalRevenue.toStringAsFixed(2)}\n'
                      '${summary.orderCount} ord • ${summary.totalCovers} cop\n'
                      '🍽️${summary.tableOrders} 📦${summary.takeawayOrders}',
                      TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Grafico annuale - mostra i 12 mesi con totali aggregati
  Widget _buildYearlyChart(BuildContext context, bool isDark) {
    // Estrai l'anno dai dati
    final year = summaries.first.date.year;
    
    // Aggrega per mese
    final monthlyData = <int, _MonthlyAggregate>{};
    for (int m = 1; m <= 12; m++) {
      monthlyData[m] = _MonthlyAggregate();
    }
    
    for (final s in summaries) {
      if (s.date.year == year) {
        final m = s.date.month;
        monthlyData[m]!.totalRevenue += s.totalRevenue;
        monthlyData[m]!.orderCount += s.orderCount;
        monthlyData[m]!.totalCovers += s.totalCovers;
        monthlyData[m]!.tableOrders += s.tableOrders;
        monthlyData[m]!.takeawayOrders += s.takeawayOrders;
        monthlyData[m]!.daysWorked++;
      }
    }

    // Prepara i dati per il bar chart
    final barGroups = <BarChartGroupData>[];
    double maxY = 0;
    // Genera nomi mesi nella lingua corretta
    final monthNames = List.generate(12, (i) => 
      DateFormat('MMM', _locale).format(DateTime(year, i + 1))
    );

    for (int m = 1; m <= 12; m++) {
      final data = monthlyData[m]!;
      if (data.totalRevenue > maxY) maxY = data.totalRevenue;
      
      barGroups.add(
        BarChartGroupData(
          x: m - 1,
          barRods: [
            BarChartRodData(
              toY: data.totalRevenue,
              color: data.daysWorked > 0 ? Colors.green : Colors.grey.shade300,
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    final chartMaxY = maxY > 0 ? maxY * 1.1 : 1000.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: chartMaxY,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? maxY / 4 : 250,
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
                      if (value == 0) return const SizedBox.shrink();
                      // Formatta in K per migliaia
                      if (value >= 1000) {
                        return Text(
                          '€${(value / 1000).toStringAsFixed(1)}k',
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        );
                      }
                      return Text(
                        '€${value.toInt()}',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= 12) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        monthNames[index],
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => isDark ? Colors.grey.shade800 : Colors.white,
                  tooltipBorder: BorderSide(color: Colors.grey.shade400),
                  tooltipPadding: const EdgeInsets.all(8),
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final monthIndex = group.x;
                    if (monthIndex < 0 || monthIndex >= 12) return null;
                    
                    final data = monthlyData[monthIndex + 1]!;
                    final textColor = isDark ? Colors.white : Colors.black87;
                    final monthName = DateFormat('MMMM yyyy', _locale).format(DateTime(year, monthIndex + 1));
                    
                    if (data.daysWorked == 0) {
                      return BarTooltipItem(
                        '$monthName\nNessun dato',
                        TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      );
                    }
                    
                    final avgPerDay = data.totalRevenue / data.daysWorked;
                    
                    return BarTooltipItem(
                      '$monthName\n'
                      '€${data.totalRevenue.toStringAsFixed(2)}\n'
                      '${data.orderCount} ord • ${data.totalCovers} cop\n'
                      '🍽️${data.tableOrders} 📦${data.takeawayOrders}\n'
                      '${data.daysWorked} giorni • €${avgPerDay.toStringAsFixed(0)}/g',
                      TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    );
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

/// Helper class per aggregare dati mensili
class _MonthlyAggregate {
  double totalRevenue = 0;
  int orderCount = 0;
  int totalCovers = 0;
  int tableOrders = 0;
  int takeawayOrders = 0;
  int daysWorked = 0;
}
