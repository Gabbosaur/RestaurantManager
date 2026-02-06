import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/display_settings_provider.dart';
import '../../../../core/config/text_size_provider.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/tutorial/tutorial_service.dart';
import '../../../../core/utils/bottom_sheet_controller.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final _routes = ['/', '/tables', '/menu'];

  void _onDestinationSelected(int index) {
    // Se clicchi sulla stessa tab e c'è un bottom sheet aperto, chiudilo
    if (_selectedIndex == index) {
      if (BottomSheetController.instance.hasActiveSheet) {
        BottomSheetController.instance.close();
      }
      return;
    }
    
    // Chiudi bottom sheet e naviga alla nuova tab
    if (BottomSheetController.instance.hasActiveSheet) {
      BottomSheetController.instance.close();
    }
    
    setState(() => _selectedIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);

    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.receipt_long_outlined),
        selectedIcon: const Icon(Icons.receipt_long),
        label: l10n.orders,
      ),
      NavigationDestination(
        icon: const Icon(Icons.table_restaurant_outlined),
        selectedIcon: const Icon(Icons.table_restaurant),
        label: l10n.tables,
      ),
      NavigationDestination(
        icon: const Icon(Icons.restaurant_menu_outlined),
        selectedIcon: const Icon(Icons.restaurant_menu),
        label: l10n.menu,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xin Xing 新星'),
        actions: [
          // Close day button
          IconButton(
            icon: const Icon(Icons.summarize),
            tooltip: l10n.closeDay,
            onPressed: () => _showDaySummary(context, ref, l10n),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: () => _showSettingsDialog(context, ref, l10n),
          ),
          // Exit to role selection
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: l10n.exit,
            onPressed: () => context.go('/role'),
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: destinations,
      ),
    );
  }

  /// Calcola il "giorno lavorativo" del ristorante.
  /// Il giorno lavorativo va dalle 6:00 alle 5:59 del giorno dopo.
  /// Es: ordini delle 23:00 del 10/01 e delle 00:30 dell'11/01 sono entrambi del giorno 10/01.
  DateTime _getBusinessDate(DateTime dateTime) {
    // Se è prima delle 6:00, appartiene al giorno precedente
    if (dateTime.hour < 6) {
      return DateTime(dateTime.year, dateTime.month, dateTime.day - 1);
    }
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  void _showDaySummary(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final ordersAsync = ref.read(ordersProvider);
    
    ordersAsync.when(
      data: (orders) {
        // Calcola il giorno lavorativo corrente
        final now = DateTime.now();
        final businessDate = _getBusinessDate(now);
        
        // Filtra ordini pagati del giorno lavorativo corrente
        final paidToday = orders.where((o) {
          if (o.status != OrderStatus.paid) return false;
          final orderBusinessDate = _getBusinessDate(o.createdAt);
          return orderBusinessDate.year == businessDate.year &&
                 orderBusinessDate.month == businessDate.month &&
                 orderBusinessDate.day == businessDate.day;
        }).toList();
        
        // Calcola statistiche
        final totalRevenue = paidToday.fold<double>(0, (sum, o) => sum + o.total);
        final orderCount = paidToday.length;
        final totalCovers = paidToday.fold<int>(0, (sum, o) => sum + (o.numberOfPeople ?? 0));
        final avgPerOrder = orderCount > 0 ? totalRevenue / orderCount : 0.0;
        
        // Top 5 piatti
        final dishCount = <String, int>{};
        for (final order in paidToday) {
          for (final item in order.items) {
            dishCount[item.name] = (dishCount[item.name] ?? 0) + item.quantity;
          }
        }
        final topDishes = dishCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top5 = topDishes.take(5).toList();
        
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.summarize, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.daySummary),
                      Text(
                        '${businessDate.day}/${businessDate.month}/${businessDate.year}',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: orderCount == 0
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(l10n.noDataToday, textAlign: TextAlign.center),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats cards
                      _SummaryCard(
                        icon: Icons.euro,
                        label: l10n.totalRevenue,
                        value: '€${totalRevenue.toStringAsFixed(2)}',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.receipt_long,
                              label: l10n.paidOrders,
                              value: '$orderCount',
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.people,
                              label: l10n.totalCovers,
                              value: '$totalCovers',
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SummaryCard(
                        icon: Icons.analytics,
                        label: l10n.averagePerOrder,
                        value: '€${avgPerOrder.toStringAsFixed(2)}',
                        color: Colors.purple,
                      ),
                      if (top5.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          l10n.topDishes,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...top5.asMap().entries.map((entry) {
                          final index = entry.key;
                          final dish = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: index == 0 ? Colors.amber : 
                                           index == 1 ? Colors.grey.shade400 :
                                           index == 2 ? Colors.brown.shade300 :
                                           Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: index < 3 ? Colors.white : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(dish.key)),
                                Text(
                                  '×${dish.value}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
            actions: [
              // View analytics button
              TextButton.icon(
                icon: const Icon(Icons.bar_chart),
                label: Text(l10n.viewAnalytics),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/analytics');
                },
              ),
              // Save and close button
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: Text(orderCount > 0 ? l10n.closeDay : l10n.close),
                onPressed: () async {
                  if (orderCount > 0) {
                    await ref.read(analyticsProvider.notifier).saveDaySummary(paidToday, businessDate);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.summarySaved)),
                      );
                    }
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  void _showSettingsDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final currentTheme = ref.watch(themeProvider);
          final currentLang = ref.watch(languageProvider);
          final textScale = ref.watch(textScaleProvider);
          
          return AlertDialog(
            title: Text(l10n.settings),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text size section
                  Text(
                    l10n.textSize,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.text_fields, size: 18),
                      Expanded(
                        child: Slider(
                          value: textScale,
                          min: TextScaleNotifier.minScale,
                          max: TextScaleNotifier.maxScale,
                          divisions: 6,
                          label: '${(textScale * 100).round()}%',
                          onChanged: (value) {
                            ref.read(textScaleProvider.notifier).setScale(value);
                          },
                        ),
                      ),
                      const Icon(Icons.text_fields, size: 28),
                    ],
                  ),
                  Center(
                    child: Text(
                      l10n.sampleText,
                      style: TextStyle(fontSize: 14 * textScale),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Hide served items option (most used feature)
                  Text(
                    l10n.display,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.hideServedItemsLabel),
                    subtitle: Text(l10n.hideServedItemsDesc),
                    value: ref.watch(hideServedItemsProvider),
                    onChanged: (value) {
                      ref.read(hideServedItemsProvider.notifier).set(value);
                    },
                  ),
                  const SizedBox(height: 20),
                  // Theme section
                  Text(
                    l10n.theme,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode, size: 18),
                        label: Text(l10n.lightTheme),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode, size: 18),
                        label: Text(l10n.darkTheme),
                      ),
                    ],
                    selected: {currentTheme == ThemeMode.system 
                        ? (MediaQuery.of(context).platformBrightness == Brightness.dark 
                            ? ThemeMode.dark 
                            : ThemeMode.light)
                        : currentTheme},
                    onSelectionChanged: (modes) {
                      ref.read(themeProvider.notifier).setTheme(modes.first);
                    },
                  ),
                  const SizedBox(height: 20),
                  // Language section
                  Text(
                    l10n.languageLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...AppLanguage.values.map((lang) {
                    final isSelected = currentLang == lang;
                    final label = switch (lang) {
                      AppLanguage.italian => '🇮🇹 Italiano',
                      AppLanguage.english => '🇬🇧 English',
                      AppLanguage.chinese => '🇨🇳 中文',
                    };
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(label),
                      trailing: isSelected 
                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) 
                          : null,
                      onTap: () {
                        ref.read(languageProvider.notifier).setLanguage(lang);
                      },
                    );
                  }),
                  const SizedBox(height: 20),
                  // Tutorial reset
                  OutlinedButton.icon(
                    onPressed: () async {
                      await TutorialService.resetAllTutorials();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.tutorialReset)),
                        );
                      }
                    },
                    icon: const Icon(Icons.replay, size: 18),
                    label: Text(l10n.resetTutorial),
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
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
