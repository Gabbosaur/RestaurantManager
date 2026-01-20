import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/restaurant_settings_provider.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/tutorial/tutorial_service.dart';
import '../../../../core/tutorial/tutorial_wrapper.dart';
import '../../../../core/tutorial/tutorials.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';
import '../widgets/create_order_sheet.dart';
import '../widgets/order_detail_sheet.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TutorialWrapper(
      tutorialId: TutorialService.salaOrders,
      stepsBuilder: getSalaOrdersTutorial,
      child: _OrdersScreenContent(),
    );
  }
}

class _OrdersScreenContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final settingsAsync = ref.watch(restaurantSettingsProvider);
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);
    final coverCharge = settingsAsync.valueOrNull?.coverCharge ?? 1.50;

    return Scaffold(
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(ordersProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.noOrders,
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            );
          }

          final activeOrders = orders
              .where((o) =>
                  o.status != OrderStatus.paid &&
                  o.status != OrderStatus.cancelled)
              .toList();
          final completedOrders = orders
              .where((o) =>
                  o.status == OrderStatus.paid ||
                  o.status == OrderStatus.cancelled)
              .toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ordersProvider),
            child: CustomScrollView(
              slivers: [
                // Active orders header
                if (activeOrders.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.pending_actions,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            '${l10n.activeOrders} (${activeOrders.length})',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Active orders grid
                if (activeOrders.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = activeOrders[index];
                          return _CompactOrderCard(
                            order: order,
                            l10n: l10n,
                            language: language,
                            coverCharge: coverCharge,
                            onTap: () => _showOrderDetail(context, order),
                          );
                        },
                        childCount: activeOrders.length,
                      ),
                    ),
                  ),

                // Completed orders header
                if (completedOrders.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 8),
                          Text(
                            '${l10n.completedToday} (${completedOrders.length})',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Completed orders grid
                if (completedOrders.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = completedOrders[index];
                          return Opacity(
                            opacity: 0.5,
                            child: _CompactOrderCard(
                              order: order,
                              l10n: l10n,
                              language: language,
                              coverCharge: coverCharge,
                              onTap: () => _showOrderDetail(context, order),
                            ),
                          );
                        },
                        childCount: completedOrders.length,
                      ),
                    ),
                  ),
                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOrderSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.newOrder),
      ),
    );
  }

  void _showCreateOrderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const CreateOrderSheet(),
    );
  }

  void _showOrderDetail(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => OrderDetailSheet(order: order),
    );
  }
}


/// Card compatta stile "foglietto" per la griglia ordini
class _CompactOrderCard extends StatelessWidget {
  final OrderModel order;
  final AppLocalizations l10n;
  final AppLanguage language;
  final double coverCharge;
  final VoidCallback onTap;

  const _CompactOrderCard({
    required this.order,
    required this.l10n,
    required this.language,
    required this.coverCharge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      OrderStatus.pending => Colors.orange,
      OrderStatus.preparing => Colors.blue,
      OrderStatus.ready => Colors.green,
      OrderStatus.served => Colors.teal,
      OrderStatus.paid => Colors.grey,
      OrderStatus.cancelled => Colors.red,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header colorato con tavolo/asporto
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: statusColor.withOpacity(0.15),
              child: Row(
                children: [
                  Icon(
                    order.isTakeaway
                        ? Icons.takeout_dining
                        : Icons.table_restaurant,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.isTakeaway
                          ? order.takeawayNumber ?? l10n.takeaway
                          : order.tableName ?? 'T?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: statusColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(order.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            // Lista piatti compatta - bevande in cima, poi piatti
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bevande in cima (compatte su una riga)
                    ..._buildBeveragesSection(order),
                    // Piatti
                    ..._buildFoodSection(order),
                  ],
                ),
              ),
            ),
            // Footer con totale
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Persone (se tavolo)
                  if (!order.isTakeaway && order.numberOfPeople != null)
                    Row(
                      children: [
                        Icon(Icons.people,
                            size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 2),
                        Text(
                          '${order.numberOfPeople}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
                  // Totale
                  Text(
                    '€${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ottiene il nome da mostrare in base alla lingua
  String _getDisplayName(OrderItem item) {
    if (language == AppLanguage.chinese && item.nameZh != null && item.nameZh!.isNotEmpty) {
      return item.nameZh!;
    }
    return _shortName(item.name);
  }

  /// Accorcia il nome rimuovendo il numero iniziale
  String _shortName(String name) {
    return name.replaceFirst(RegExp(r'^\d+\.?\s*'), '');
  }

  /// Costruisce la sezione bevande (compatta, in cima)
  List<Widget> _buildBeveragesSection(OrderModel order) {
    final beverages = order.items.where((item) => item.isBeverage).toList();
    if (beverages.isEmpty) return [];
    
    // Mostra bevande compatte su una riga
    final beverageText = beverages.map((b) => '${b.quantity}x ${_getDisplayName(b)}').join(', ');
    
    return [
      Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Row(
            children: [
              Icon(Icons.local_bar, size: 10, color: isDark ? Colors.grey.shade500 : Colors.blue.shade400),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  beverageText,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey.shade400 : Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
      Divider(height: 8, thickness: 1, color: Colors.grey.shade300),
    ];
  }

  /// Costruisce la sezione piatti
  List<Widget> _buildFoodSection(OrderModel order) {
    final foodItems = order.items.where((item) => !item.isBeverage).toList();
    if (foodItems.isEmpty) return [];
    
    final displayItems = foodItems.take(4).toList();
    final remaining = foodItems.length - 4;
    
    return [
      ...displayItems.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          '${item.quantity}x ${_getDisplayName(item)}',
          style: const TextStyle(fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      )),
      if (remaining > 0)
        Text(
          '+$remaining ${l10n.others}...',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
    ];
  }
}
