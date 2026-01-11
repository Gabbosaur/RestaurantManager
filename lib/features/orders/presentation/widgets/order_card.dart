import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../data/models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final AppLocalizations l10n;
  final void Function(OrderStatus) onStatusChange;
  final VoidCallback? onEdit;
  final double coverCharge;

  const OrderCard({
    super.key,
    required this.order,
    required this.l10n,
    required this.onStatusChange,
    this.onEdit,
    this.coverCharge = 1.50,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      order.isTakeaway
                          ? Icons.takeout_dining
                          : Icons.restaurant,
                      size: 20,
                      color: order.isTakeaway ? Colors.orange : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.isTakeaway
                          ? '${l10n.takeaway} #${order.id.substring(0, 6).toUpperCase()}'
                          : '${l10n.table} ${order.tableName ?? order.tableId ?? "?"} #${order.id.substring(0, 6).toUpperCase()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                _StatusChip(status: order.status, l10n: l10n),
              ],
            ),
            if (!order.isTakeaway && order.numberOfPeople != null) ...[
              const SizedBox(height: 4),
              Text(
                '${order.numberOfPeople} ${l10n.people.toLowerCase()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
            const Divider(height: 24),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.name}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '€${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )),
            // Cover charge row (only for table orders with people)
            if (!order.isTakeaway && (order.numberOfPeople ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.numberOfPeople}x ${l10n.coverCharge}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      '€${(coverCharge * order.numberOfPeople!).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.total,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '€${order.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(order.notes!)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side: time + edit button
                Row(
                  children: [
                    Text(
                      DateFormat('HH:mm - d MMM').format(order.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    // Edit button (only for active orders) - on the left, away from action button
                    if (onEdit != null &&
                        order.status != OrderStatus.served &&
                        order.status != OrderStatus.cancelled) ...[
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(l10n.edit),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
                // Right side: status action button
                _StatusActions(
                  currentStatus: order.status,
                  l10n: l10n,
                  onStatusChange: onStatusChange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  final AppLocalizations l10n;

  const _StatusChip({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      OrderStatus.pending => (Colors.orange, l10n.pending),
      OrderStatus.preparing => (Colors.blue, l10n.preparing),
      OrderStatus.ready => (Colors.green, l10n.ready),
      OrderStatus.served => (Colors.grey, l10n.served),
      OrderStatus.paid => (Colors.grey, l10n.paid),
      OrderStatus.cancelled => (Colors.red, l10n.cancelled),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  final OrderStatus currentStatus;
  final AppLocalizations l10n;
  final void Function(OrderStatus) onStatusChange;

  const _StatusActions({
    required this.currentStatus,
    required this.l10n,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    if (currentStatus == OrderStatus.served ||
        currentStatus == OrderStatus.cancelled) {
      return const SizedBox.shrink();
    }

    final nextStatus = switch (currentStatus) {
      OrderStatus.pending => OrderStatus.preparing,
      OrderStatus.preparing => OrderStatus.ready,
      OrderStatus.ready => OrderStatus.served,
      _ => null,
    };

    if (nextStatus == null) return const SizedBox.shrink();

    final label = switch (nextStatus) {
      OrderStatus.preparing => l10n.prepare,
      OrderStatus.ready => l10n.ready,
      OrderStatus.served => l10n.served,
      _ => '',
    };

    return FilledButton.tonal(
      onPressed: () => onStatusChange(nextStatus),
      child: Text(label),
    );
  }
}
