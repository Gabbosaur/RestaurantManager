import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/tutorial/tutorial_service.dart';
import '../../../../core/tutorial/tutorial_wrapper.dart';
import '../../../../core/tutorial/tutorials.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../orders/presentation/widgets/create_order_sheet.dart';
import '../../../orders/presentation/widgets/order_detail_sheet.dart';
import '../../data/models/table_model.dart';
import '../providers/tables_provider.dart';

class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TutorialWrapper(
      tutorialId: TutorialService.salaTables,
      stepsBuilder: getSalaTablesTutorial,
      child: _TablesScreenContent(),
    );
  }
}

class _TablesScreenContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);

    // Ascolta errori e mostra SnackBar
    ref.listen<TableError?>(tableErrorProvider, (previous, next) {
      if (next != null) {
        final message = switch (next) {
          TableError.createFailed => l10n.errorCreateTable,
          TableError.updateFailed => l10n.errorUpdateTable,
          TableError.deleteFailed => l10n.errorDeleteTable,
          TableError.reservationFailed => l10n.errorReservation,
          TableError.occupyFailed => l10n.errorUpdateTable,
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        // Reset errore
        ref.read(tableErrorProvider.notifier).state = null;
      }
    });

    return Scaffold(
      body: Column(
        children: [
          // Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _LegendItem(
                  color: Theme.of(context).colorScheme.primary,
                  label: l10n.available,
                ),
                const SizedBox(width: 16),
                _LegendItem(
                  color: Theme.of(context).colorScheme.error,
                  label: l10n.occupied,
                ),
                const SizedBox(width: 16),
                _LegendItem(
                  color: Theme.of(context).colorScheme.tertiary,
                  label: l10n.reserved,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tables grid
          Expanded(
            child: tablesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      l10n.errorLoadTables,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.checkConnection,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(tablesProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
              data: (tables) {
                if (tables.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_restaurant_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noTables,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate columns based on width
                    final width = constraints.maxWidth;
                    final crossAxisCount = width > 900
                        ? 4
                        : width > 600
                            ? 3
                            : 2;

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: tables.length,
                      itemBuilder: (context, index) {
                        final table = tables[index];
                        return _TableCard(
                          table: table,
                          l10n: l10n,
                          onTap: () =>
                              _handleTableTap(context, ref, table, l10n),
                          onLongPress: table.status == TableStatus.available
                              ? () => _showTableOptionsDialog(context, ref, table, l10n)
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTableDialog(context, ref, l10n),
        icon: const Icon(Icons.add),
        label: Text(l10n.addTable),
      ),
    );
  }

  void _handleTableTap(BuildContext context, WidgetRef ref, TableModel table,
      AppLocalizations l10n) {
    // Tavolo OCCUPATO con ordine → mostra dettaglio ordine
    if (table.status == TableStatus.occupied) {
      final order =
          ref.read(ordersProvider.notifier).getActiveOrderForTable(table.id);
      if (order != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => OrderDetailSheet(order: order),
        );
        return;
      }
    }

    // Tavolo LIBERO → apri direttamente creazione ordine
    if (table.status == TableStatus.available) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => CreateOrderSheet(preselectedTable: table),
      );
      return;
    }

    // Tavolo PRENOTATO → mostra opzioni
    _showReservedTableActions(context, ref, table, l10n);
  }

  void _showTableOptionsDialog(BuildContext context, WidgetRef ref,
      TableModel table, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(table.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(width: 8),
                  _StatusBadge(status: table.status, l10n: l10n),
                ],
              ),
              const SizedBox(height: 24),
              // Reservation option
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showReservationDialog(context, ref, table, l10n);
                },
                icon: const Icon(Icons.event),
                label: Text(l10n.reservation),
              ),
              const SizedBox(height: 8),
              // Edit option
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditTableDialog(context, ref, table, l10n);
                },
                icon: const Icon(Icons.edit),
                label: Text(l10n.edit),
              ),
              const SizedBox(height: 8),
              // Delete option
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteTableDialog(context, ref, table, l10n);
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.delete),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteTableDialog(BuildContext context, WidgetRef ref,
      TableModel table, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text('${l10n.deleteTableConfirm} "${table.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(tablesProvider.notifier).deleteTable(table.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showReservedTableActions(BuildContext context, WidgetRef ref,
      TableModel table, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(table.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(width: 8),
                  _StatusBadge(status: table.status, l10n: l10n),
                ],
              ),
              if (table.reservedBy != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${l10n.reserved}: ${table.reservedBy}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.orange),
                ),
              ],
              const SizedBox(height: 24),
              // Actions
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) =>
                        CreateOrderSheet(preselectedTable: table),
                  );
                },
                icon: const Icon(Icons.receipt_long),
                label: Text(l10n.newOrder),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  ref
                      .read(tablesProvider.notifier)
                      .updateStatus(table.id, TableStatus.available);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.event_busy),
                label: Text(l10n.markAvailable),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTableDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final nameController = TextEditingController();
    final capacityController = TextEditingController(text: '4');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addTable),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '${l10n.name} (T1, T2...)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capacityController,
              decoration: InputDecoration(labelText: l10n.seats),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final tables = ref.read(tablesProvider).valueOrNull ?? [];
              final table = TableModel(
                id: const Uuid().v4(),
                name: nameController.text.isNotEmpty
                    ? nameController.text
                    : 'T${tables.length + 1}',
                capacity: int.tryParse(capacityController.text) ?? 4,
                status: TableStatus.available,
              );
              ref.read(tablesProvider.notifier).addTable(table);
              Navigator.pop(context);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  void _showEditTableDialog(BuildContext context, WidgetRef ref,
      TableModel table, AppLocalizations l10n) {
    final nameController = TextEditingController(text: table.name);
    final capacityController =
        TextEditingController(text: table.capacity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.edit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.name),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capacityController,
              decoration: InputDecoration(labelText: l10n.seats),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final updated = table.copyWith(
                name: nameController.text,
                capacity: int.tryParse(capacityController.text) ?? 4,
              );
              ref.read(tablesProvider.notifier).updateTable(updated);
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showReservationDialog(BuildContext context, WidgetRef ref,
      TableModel table, AppLocalizations l10n) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reservation),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: l10n.customerName),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(tablesProvider.notifier).makeReservation(
                    table.id,
                    nameController.text,
                    DateTime.now(),
                  );
              Navigator.pop(context);
            },
            child: Text(l10n.reserve),
          ),
        ],
      ),
    );
  }
}


/// Card widget for each table in the grid
class _TableCard extends ConsumerWidget {
  final TableModel table;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _TableCard({
    required this.table,
    required this.l10n,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch orders per reagire ai cambiamenti
    final ordersAsync = ref.watch(ordersProvider);
    
    // Get order total if occupied
    double? orderTotal;
    if (table.status == TableStatus.occupied) {
      final orders = ordersAsync.valueOrNull ?? [];
      final order = orders.where(
        (o) => o.tableId == table.id && 
               o.status != OrderStatus.paid && 
               o.status != OrderStatus.cancelled,
      ).firstOrNull;
      orderTotal = order?.total;
    }

    // Colori morbidi che si integrano col tema
    final (bgColor, fgColor, icon) = switch (table.status) {
      TableStatus.available => (
          isDark
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerLow,
          colorScheme.primary,
          Icons.check_circle_outline,
        ),
      TableStatus.occupied => (
          colorScheme.errorContainer,
          colorScheme.error,
          Icons.people,
        ),
      TableStatus.reserved => (
          colorScheme.tertiaryContainer,
          colorScheme.tertiary,
          Icons.event,
        ),
    };

    final statusText = switch (table.status) {
      TableStatus.available => l10n.available,
      TableStatus.occupied => l10n.occupied,
      TableStatus.reserved => l10n.reserved,
    };

    return Card(
      elevation: table.status == TableStatus.occupied ? 4 : 1,
      color: bgColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: fgColor.withOpacity(0.3),
          width: table.status == TableStatus.occupied ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name + Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        table.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: fgColor,
                            ),
                      ),
                    ),
                  ),
                  Icon(icon, color: fgColor, size: 28),
                ],
              ),
              const SizedBox(height: 6),
              // Info row: seats + people (sempre visibile)
              Row(
                children: [
                  Icon(Icons.chair_outlined,
                      size: 18, color: fgColor.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(
                    '${table.capacity}',
                    style: TextStyle(
                      color: fgColor.withOpacity(0.7),
                      fontSize: 15,
                    ),
                  ),
                  // Show people count if occupied
                  if (table.status == TableStatus.occupied &&
                      table.numberOfPeople != null) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.people, size: 18, color: fgColor),
                    const SizedBox(width: 4),
                    Text(
                      '${table.numberOfPeople}',
                      style: TextStyle(
                        color: fgColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              // Order total if occupied
              if (table.status == TableStatus.occupied &&
                  orderTotal != null) ...[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '€${orderTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              // Status text
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              // Reserved by name
              if (table.status == TableStatus.reserved &&
                  table.reservedBy != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: fgColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        table.reservedBy!,
                        style: TextStyle(
                          color: fgColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TableStatus status;
  final AppLocalizations l10n;

  const _StatusBadge({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (color, label) = switch (status) {
      TableStatus.available => (colorScheme.primary, l10n.available),
      TableStatus.occupied => (colorScheme.error, l10n.occupied),
      TableStatus.reserved => (colorScheme.tertiary, l10n.reserved),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}
