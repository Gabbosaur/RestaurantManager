import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

class KitchenScreen extends ConsumerWidget {
  const KitchenScreen({super.key});

  void _showIngredientsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => const InventoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.restaurant, size: 28),
            const SizedBox(width: 12),
            Text(
              l10n.kitchen,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // Ingredients button
          IconButton(
            icon: const Icon(Icons.inventory_2, size: 28),
            tooltip: l10n.inventory,
            onPressed: () => _showIngredientsSheet(context),
          ),
          // Exit button
          IconButton(
            icon: const Icon(Icons.exit_to_app, size: 28),
            tooltip: l10n.exit,
            onPressed: () => context.go('/role'),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (orders) {
          final newOrders =
              orders.where((o) => o.status == OrderStatus.pending).toList();
          final preparingOrders =
              orders.where((o) => o.status == OrderStatus.preparing).toList();
          final readyOrders =
              orders.where((o) => o.status == OrderStatus.ready).toList();

          // Use tabs on small screens, columns on large screens
          if (isSmallScreen) {
            return _KitchenTabs(
              newOrders: newOrders,
              preparingOrders: preparingOrders,
              readyOrders: readyOrders,
              l10n: l10n,
              ref: ref,
            );
          }

          return Row(
            children: [
              // Colonna 1: Nuovi ordini
              Expanded(
                child: _OrderColumn(
                  title: l10n.newOrders,
                  orders: newOrders,
                  color: Colors.orange,
                  emptyMessage: l10n.noNewOrders,
                  actionLabel: l10n.startPreparing,
                  onAction: (order) => ref
                      .read(ordersProvider.notifier)
                      .updateStatus(order.id, OrderStatus.preparing),
                  onDismissChanges: (orderId) => ref
                      .read(ordersProvider.notifier)
                      .clearChanges(orderId),
                  l10n: l10n,
                ),
              ),
              const VerticalDivider(width: 1),
              // Colonna 2: In preparazione
              Expanded(
                child: _OrderColumn(
                  title: l10n.inPreparation,
                  orders: preparingOrders,
                  color: Colors.blue,
                  emptyMessage: l10n.noPreparing,
                  actionLabel: l10n.markReady,
                  onAction: (order) => ref
                      .read(ordersProvider.notifier)
                      .updateStatus(order.id, OrderStatus.ready),
                  onDismissChanges: (orderId) => ref
                      .read(ordersProvider.notifier)
                      .clearChanges(orderId),
                  l10n: l10n,
                ),
              ),
              const VerticalDivider(width: 1),
              // Colonna 3: Pronti
              Expanded(
                child: _OrderColumn(
                  title: l10n.readyToServe,
                  orders: readyOrders,
                  color: Colors.green,
                  emptyMessage: l10n.noReady,
                  actionLabel: l10n.served,
                  onAction: (order) => ref
                      .read(ordersProvider.notifier)
                      .updateStatus(order.id, OrderStatus.served),
                  onDismissChanges: (orderId) => ref
                      .read(ordersProvider.notifier)
                      .clearChanges(orderId),
                  l10n: l10n,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Tabbed view for small screens (mobile)
class _KitchenTabs extends StatelessWidget {
  final List<OrderModel> newOrders;
  final List<OrderModel> preparingOrders;
  final List<OrderModel> readyOrders;
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _KitchenTabs({
    required this.newOrders,
    required this.preparingOrders,
    required this.readyOrders,
    required this.l10n,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.newOrders),
                    if (newOrders.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _Badge(count: newOrders.length, color: Colors.orange),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.inPreparation),
                    if (preparingOrders.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _Badge(count: preparingOrders.length, color: Colors.blue),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.readyToServe),
                    if (readyOrders.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _Badge(count: readyOrders.length, color: Colors.green),
                    ],
                  ],
                ),
              ),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OrderColumn(
                  title: l10n.newOrders,
                  orders: newOrders,
                  color: Colors.orange,
                  emptyMessage: l10n.noNewOrders,
                  actionLabel: l10n.startPreparing,
                  onAction: (order) => ref
                      .read(ordersProvider.notifier)
                      .updateStatus(order.id, OrderStatus.preparing),
                  onDismissChanges: (orderId) => ref
                      .read(ordersProvider.notifier)
                      .clearChanges(orderId),
                  l10n: l10n,
                  showHeader: false,
                ),
                _OrderColumn(
                  title: l10n.inPreparation,
                  orders: preparingOrders,
                  color: Colors.blue,
                  emptyMessage: l10n.noPreparing,
                  actionLabel: l10n.markReady,
                  onAction: (order) => ref
                      .read(ordersProvider.notifier)
                      .updateStatus(order.id, OrderStatus.ready),
                  onDismissChanges: (orderId) => ref
                      .read(ordersProvider.notifier)
                      .clearChanges(orderId),
                  l10n: l10n,
                  showHeader: false,
                ),
                _OrderColumn(
                  title: l10n.readyToServe,
                  orders: readyOrders,
                  color: Colors.green,
                  emptyMessage: l10n.noReady,
                  actionLabel: l10n.served,
                  onAction: (order) => ref
                      .read(ordersProvider.notifier)
                      .updateStatus(order.id, OrderStatus.served),
                  onDismissChanges: (orderId) => ref
                      .read(ordersProvider.notifier)
                      .clearChanges(orderId),
                  l10n: l10n,
                  showHeader: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;

  const _Badge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _OrderColumn extends StatelessWidget {
  final String title;
  final List<OrderModel> orders;
  final Color color;
  final String emptyMessage;
  final String actionLabel;
  final void Function(OrderModel) onAction;
  final void Function(String orderId)? onDismissChanges;
  final AppLocalizations l10n;
  final bool showHeader;

  const _OrderColumn({
    required this.title,
    required this.orders,
    required this.color,
    required this.emptyMessage,
    required this.actionLabel,
    required this.onAction,
    required this.l10n,
    this.onDismissChanges,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.05),
      child: Column(
        children: [
          // Header (optional)
          if (showHeader)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: color.withOpacity(0.2),
              child: Column(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${orders.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Orders list
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text(
                      emptyMessage,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _KitchenOrderCard(
                        order: order,
                        color: color,
                        actionLabel: actionLabel,
                        onAction: () => onAction(order),
                        l10n: l10n,
                        onDismissChanges: onDismissChanges,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _KitchenOrderCard extends StatelessWidget {
  final OrderModel order;
  final Color color;
  final String actionLabel;
  final VoidCallback onAction;
  final void Function(String orderId)? onDismissChanges;
  final AppLocalizations l10n;

  const _KitchenOrderCard({
    required this.order,
    required this.color,
    required this.actionLabel,
    required this.onAction,
    required this.l10n,
    this.onDismissChanges,
  });

  String _getTimeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return l10n.justNow;
    return l10n.minutesAgo(diff.inMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = DateTime.now().difference(order.createdAt).inMinutes > 15;
    
    // Crea mappa delle modifiche per menuItemId per lookup veloce
    final changesMap = <String, int>{};
    if (order.changes != null) {
      for (final change in order.changes!) {
        // Cerca il menuItemId corrispondente negli items
        for (final item in order.items) {
          if (item.name == change.name || item.nameZh == change.nameZh) {
            changesMap[item.menuItemId] = (changesMap[item.menuItemId] ?? 0) + change.quantity;
          }
        }
      }
    }
    
    // Modifiche per piatti rimossi (non più in items)
    final removedChanges = order.changes?.where((c) => 
      c.isRemoval && !order.items.any((i) => i.name == c.name || i.nameZh == c.nameZh)
    ).toList() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUrgent
            ? const BorderSide(color: Colors.red, width: 3)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order type + time + modified badge + dismiss button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        order.isTakeaway
                            ? Icons.shopping_bag
                            : Icons.table_restaurant,
                        size: 28,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          order.isTakeaway
                              ? l10n.takeaway
                              : '${l10n.table} ${order.tableName ?? order.tableId ?? "?"}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Modified badge with dismiss
                      if (order.isModified && order.changes != null && order.changes!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onDismissChanges != null ? () => onDismissChanges!(order.id) : null,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, color: Colors.white, size: 12),
                                SizedBox(width: 2),
                                Icon(Icons.check, color: Colors.white, size: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUrgent ? Colors.red : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTimeAgo(order.createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isUrgent ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            // Items list - large and clear (Chinese name for kitchen)
            ...order.items.map((item) {
              final servedQty = order.getServedQuantity(item.menuItemId);
              final isFullyServed = servedQty >= item.quantity;
              final hasPartialServed = servedQty > 0 && servedQty < item.quantity;
              final remaining = item.quantity - servedQty;
              final changeQty = changesMap[item.menuItemId];
              return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Opacity(
                    opacity: isFullyServed ? 0.5 : 1.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quantity badge - più visibile in dark mode
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isFullyServed 
                                ? Colors.grey 
                                : hasPartialServed 
                                    ? Colors.orange 
                                    : color,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isFullyServed
                                ? null
                                : [
                                    BoxShadow(
                                      color: color.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: isFullyServed
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 20)
                                : hasPartialServed
                                    ? Text(
                                        '${remaining}x',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        '${item.quantity}x',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nome cinese (grande) - se disponibile
                              if (item.nameZh != null) ...[
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.nameZh!,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          decoration: isFullyServed
                                              ? TextDecoration.lineThrough
                                              : null,
                                          decorationThickness: 2,
                                        ),
                                      ),
                                    ),
                                    // Change badge inline
                                    if (changeQty != null && changeQty != 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: changeQty > 0 ? Colors.green : Colors.red,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          changeQty > 0 ? '+$changeQty' : '$changeQty',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                // Nome italiano (piccolo sotto) + served info
                                Row(
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        decoration: isFullyServed
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    if (hasPartialServed) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n.servedCountShort(servedQty, item.quantity),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ] else ...[
                                // Solo nome italiano se non c'è cinese
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          decoration: isFullyServed
                                              ? TextDecoration.lineThrough
                                              : null,
                                          decorationThickness: 2,
                                        ),
                                      ),
                                    ),
                                    // Change badge inline
                                    if (changeQty != null && changeQty != 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: changeQty > 0 ? Colors.green : Colors.red,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          changeQty > 0 ? '+$changeQty' : '$changeQty',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (hasPartialServed)
                                  Text(
                                    l10n.servedCountShort(servedQty, item.quantity),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                              if (item.notes != null && item.notes!.isNotEmpty)
                                Text(
                                  '⚠️ ${item.notes}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
            }),
            // Removed items (piatti completamente rimossi)
            ...removedChanges.map((change) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Opacity(
                opacity: 0.6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Badge rosso con X
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${change.quantity.abs()}x ${change.nameZh ?? change.name}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
                          decoration: TextDecoration.lineThrough,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
            // Order notes
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.notes!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Action button - big and easy to tap
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }
}
