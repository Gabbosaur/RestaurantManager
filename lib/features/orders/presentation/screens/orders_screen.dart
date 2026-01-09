import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/create_order_sheet.dart';
import '../widgets/edit_order_sheet.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);

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
                  Text(
                    l10n.noOrders,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          final activeOrders = orders
              .where((o) =>
                  o.status != OrderStatus.served &&
                  o.status != OrderStatus.cancelled)
              .toList();
          final completedOrders = orders
              .where((o) =>
                  o.status == OrderStatus.served ||
                  o.status == OrderStatus.cancelled)
              .toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ordersProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (activeOrders.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.pending_actions,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.activeOrders} (${activeOrders.length})',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...activeOrders.map((order) => OrderCard(
                        order: order,
                        l10n: l10n,
                        onStatusChange: (status) {
                          ref.read(ordersProvider.notifier).updateStatus(
                                order.id,
                                status,
                              );
                        },
                        onEdit: () => _showEditOrderSheet(context, order),
                      )),
                ],
                if (completedOrders.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.completedToday} (${completedOrders.length})',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...completedOrders.map((order) => Opacity(
                        opacity: 0.6,
                        child: OrderCard(
                          order: order,
                          l10n: l10n,
                          onStatusChange: (_) {},
                        ),
                      )),
                ],
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

  void _showEditOrderSheet(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => EditOrderSheet(order: order),
    );
  }
}
