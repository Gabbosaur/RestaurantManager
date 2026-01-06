import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

class KitchenScreen extends ConsumerWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);

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

class _OrderColumn extends StatelessWidget {
  final String title;
  final List<OrderModel> orders;
  final Color color;
  final String emptyMessage;
  final String actionLabel;
  final void Function(OrderModel) onAction;
  final AppLocalizations l10n;

  const _OrderColumn({
    required this.title,
    required this.orders,
    required this.color,
    required this.emptyMessage,
    required this.actionLabel,
    required this.onAction,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.05),
      child: Column(
        children: [
          // Header
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
  final AppLocalizations l10n;

  const _KitchenOrderCard({
    required this.order,
    required this.color,
    required this.actionLabel,
    required this.onAction,
    required this.l10n,
  });

  String _getTimeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return l10n.justNow;
    return l10n.minutesAgo(diff.inMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = DateTime.now().difference(order.createdAt).inMinutes > 15;

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
            // Header: Order type + time
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
            // Items list - large and clear
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${item.quantity}x',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
