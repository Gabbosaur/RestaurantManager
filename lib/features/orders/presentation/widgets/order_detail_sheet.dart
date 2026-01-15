import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/restaurant_settings_provider.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';
import 'edit_order_sheet.dart';

class OrderDetailSheet extends ConsumerWidget {
  final OrderModel order;

  const OrderDetailSheet({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);
    final settingsAsync = ref.watch(restaurantSettingsProvider);
    final coverCharge = settingsAsync.valueOrNull?.coverCharge ?? 1.50;
    
    // Watch orders to get real-time updates for served items
    final ordersAsync = ref.watch(ordersProvider);
    final currentOrder = ordersAsync.valueOrNull?.firstWhere(
      (o) => o.id == order.id,
      orElse: () => order,
    ) ?? order;

    final itemsTotal = currentOrder.items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final coverTotal = currentOrder.isTakeaway ? 0.0 : coverCharge * (currentOrder.numberOfPeople ?? 0);
    final grandTotal = itemsTotal + coverTotal;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(context, l10n, currentOrder),
                      // Content - only items list
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Bevande in cima (compatte)
                            ..._buildBeveragesSection(context, ref, currentOrder, l10n, language),
                            // Piatti sotto
                            ..._buildFoodSection(context, ref, currentOrder, l10n, language),
                            // Notes
                            if (currentOrder.notes != null && currentOrder.notes!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.note, color: Colors.amber.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        currentOrder.notes!,
                                        style: TextStyle(color: Colors.amber.shade900),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Footer with totals and edit button
                      _buildFooter(context, l10n, itemsTotal, coverTotal, coverCharge, grandTotal, currentOrder),
                    ],
                  ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, OrderModel currentOrder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            currentOrder.isTakeaway ? Icons.takeout_dining : Icons.restaurant,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentOrder.isTakeaway
                      ? l10n.takeaway
                      : '${l10n.table} ${currentOrder.tableName ?? ""}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                if (!currentOrder.isTakeaway && currentOrder.numberOfPeople != null)
                  Text(
                    '${currentOrder.numberOfPeople} ${l10n.people}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          // Status badge
          _buildStatusBadge(context, l10n, currentOrder),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, AppLocalizations l10n, OrderModel currentOrder) {
    final (color, label) = switch (currentOrder.status) {
      OrderStatus.pending => (Colors.orange, l10n.pending),
      OrderStatus.preparing => (Colors.blue, l10n.preparing),
      OrderStatus.ready => (Colors.green, l10n.ready),
      OrderStatus.served => (Colors.teal, l10n.served),
      OrderStatus.paid => (Colors.grey, l10n.paid),
      OrderStatus.cancelled => (Colors.red, l10n.cancelled),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, WidgetRef ref, OrderItem item, OrderModel currentOrder, AppLocalizations l10n, AppLanguage language) {
    final servedQty = currentOrder.getServedQuantity(item.menuItemId);
    final isFullyServed = servedQty >= item.quantity;
    final hasPartialServed = servedQty > 0 && servedQty < item.quantity;
    final remaining = item.quantity - servedQty;
    
    return InkWell(
      onTap: () {
        ref.read(ordersProvider.notifier).toggleItemServed(
              currentOrder.id,
              item.menuItemId,
            );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Opacity(
          opacity: isFullyServed ? 0.5 : 1.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Served indicator / Quantity badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isFullyServed
                      ? Colors.green
                      : hasPartialServed
                          ? Colors.orange
                          : Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: isFullyServed
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : hasPartialServed
                          ? Text(
                              '$remaining',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            )
                          : Text(
                              '${item.quantity}x',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 12),
              // Item name with served count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplayName(item, language),
                      style: TextStyle(
                        fontSize: 15,
                        decoration: isFullyServed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (hasPartialServed)
                      Text(
                        l10n.servedCount(servedQty, item.quantity),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              // Price
              Text(
                '€${(item.price * item.quantity).toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  decoration: isFullyServed ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n,
      double itemsTotal, double coverTotal, double coverCharge, double grandTotal, OrderModel currentOrder) {
    final canEdit = currentOrder.status != OrderStatus.served &&
        currentOrder.status != OrderStatus.paid &&
        currentOrder.status != OrderStatus.cancelled;
    final canMarkPaid = currentOrder.status == OrderStatus.served;
    final canCancel = currentOrder.status != OrderStatus.paid &&
        currentOrder.status != OrderStatus.cancelled;

    return Consumer(
      builder: (context, ref, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Totals section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Piatti',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Text(
                    '€${itemsTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              if (!currentOrder.isTakeaway && (currentOrder.numberOfPeople ?? 0) > 0) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.coverCharge} (${currentOrder.numberOfPeople}×€${coverCharge.toStringAsFixed(2)})',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    Text(
                      '€${coverTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.total,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '€${grandTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Buttons
              if (canMarkPaid) ...[
                // Show big "Mark as Paid" button when order is completed
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      ref.read(ordersProvider.notifier).markAsPaid(currentOrder.id);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.payments),
                    label: Text(l10n.markAsPaid),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Cancel button
                    IconButton(
                      onPressed: () => _showCancelDialog(context, ref, l10n, currentOrder),
                      icon: const Icon(Icons.cancel_outlined),
                      color: Colors.red,
                      tooltip: l10n.cancelOrder,
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.close),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (context) => EditOrderSheet(order: currentOrder),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(l10n.edit),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    // Cancel button (if allowed)
                    if (canCancel)
                      IconButton(
                        onPressed: () => _showCancelDialog(context, ref, l10n, currentOrder),
                        icon: const Icon(Icons.cancel_outlined),
                        color: Colors.red,
                        tooltip: l10n.cancelOrder,
                      ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.close),
                      ),
                    ),
                    if (canEdit) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (context) => EditOrderSheet(order: currentOrder),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: Text(l10n.edit),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelOrder),
        content: Text(l10n.cancelOrderConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(ordersProvider.notifier).cancelOrder(order.id);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close detail sheet
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.orderCancelled)),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  /// Ottiene il nome da mostrare in base alla lingua
  String _getDisplayName(OrderItem item, AppLanguage language) {
    if (language == AppLanguage.chinese && item.nameZh != null && item.nameZh!.isNotEmpty) {
      return item.nameZh!;
    }
    return item.name;
  }

  /// Sezione bevande compatta in cima
  List<Widget> _buildBeveragesSection(BuildContext context, WidgetRef ref, OrderModel order, AppLocalizations l10n, AppLanguage language) {
    final beverages = order.items.where((item) => item.isBeverage).toList();
    if (beverages.isEmpty) return [];

    final beverageTotal = beverages.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_bar, size: 16, color: isDark ? Colors.grey.shade500 : Colors.blue.shade700),
                const SizedBox(width: 6),
                Text(
                  'Bevande',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade400 : Colors.blue.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '€${beverageTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade400 : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: beverages.map((item) {
                final servedQty = order.getServedQuantity(item.menuItemId);
                final isFullyServed = servedQty >= item.quantity;
                return InkWell(
                  onTap: () {
                    ref.read(ordersProvider.notifier).toggleItemServed(order.id, item.menuItemId);
                  },
                  child: Opacity(
                    opacity: isFullyServed ? 0.5 : 1.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFullyServed)
                          Icon(Icons.check_circle, size: 14, color: Colors.green.shade600)
                        else
                          Text(
                            '${item.quantity}x',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey.shade300 : Colors.blue.shade900,
                            ),
                          ),
                        const SizedBox(width: 3),
                        Text(
                          _getDisplayName(item, language),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade300 : Colors.blue.shade900,
                            decoration: isFullyServed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Divider(color: Colors.grey.shade300),
      const SizedBox(height: 4),
    ];
  }

  /// Sezione piatti
  List<Widget> _buildFoodSection(BuildContext context, WidgetRef ref, OrderModel order, AppLocalizations l10n, AppLanguage language) {
    final foodItems = order.items.where((item) => !item.isBeverage).toList();
    return foodItems.map((item) => _buildItemRow(context, ref, item, order, l10n, language)).toList();
  }

  /// Accorcia il nome della bevanda
  String _shortBeverageName(String name) {
    return name.replaceFirst(RegExp(r'^\d+\.?\s*'), '');
  }
}
