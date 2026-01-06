import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../menu/presentation/providers/menu_provider.dart';
import '../../../tables/data/models/table_model.dart';
import '../../../tables/presentation/providers/tables_provider.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';

class CreateOrderSheet extends ConsumerStatefulWidget {
  const CreateOrderSheet({super.key});

  @override
  ConsumerState<CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends ConsumerState<CreateOrderSheet> {
  final _peopleController = TextEditingController(text: '2');
  final _notesController = TextEditingController();
  final Map<String, int> _selectedItems = {};
  bool _isLoading = false;
  OrderType _orderType = OrderType.table;
  TableModel? _selectedTable;

  @override
  void dispose() {
    _peopleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _total {
    final menuItems = ref.read(menuProvider).valueOrNull ?? [];
    double sum = 0;
    for (final entry in _selectedItems.entries) {
      final item = menuItems.firstWhere((m) => m.id == entry.key);
      sum += item.price * entry.value;
    }
    return sum;
  }

  Future<void> _createOrder(AppLocalizations l10n) async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectAtLeastOne)),
      );
      return;
    }

    if (_orderType == OrderType.table && _selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterTableNumber)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final menuItems = ref.read(menuProvider).valueOrNull ?? [];
      final orderItems = _selectedItems.entries.map((entry) {
        final menuItem = menuItems.firstWhere((m) => m.id == entry.key);
        return OrderItem(
          menuItemId: menuItem.id,
          name: menuItem.name,
          quantity: entry.value,
          price: menuItem.price,
        );
      }).toList();

      final orderId = const Uuid().v4();
      final numberOfPeople = _orderType == OrderType.table
          ? int.tryParse(_peopleController.text) ?? 2
          : null;

      final order = OrderModel(
        id: orderId,
        tableId: _orderType == OrderType.table ? _selectedTable!.id : null,
        tableName: _orderType == OrderType.table ? _selectedTable!.name : null,
        orderType: _orderType,
        numberOfPeople: numberOfPeople,
        items: orderItems,
        status: OrderStatus.pending,
        total: _total,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(ordersProvider.notifier).createOrder(order);

      // Update table status to occupied with number of people
      if (_orderType == OrderType.table && _selectedTable != null) {
        await ref.read(tablesProvider.notifier).occupyTableWithOrder(
              _selectedTable!.id,
              orderId,
              numberOfPeople ?? 2,
            );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuProvider);
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.newOrder,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedButton<OrderType>(
                segments: [
                  ButtonSegment(
                    value: OrderType.table,
                    icon: const Icon(Icons.restaurant),
                    label: Text(l10n.table),
                  ),
                  ButtonSegment(
                    value: OrderType.takeaway,
                    icon: const Icon(Icons.takeout_dining),
                    label: Text(l10n.takeaway),
                  ),
                ],
                selected: {_orderType},
                onSelectionChanged: (types) {
                  setState(() => _orderType = types.first);
                },
              ),
              const SizedBox(height: 16),
              if (_orderType == OrderType.table) ...[
                _TableSelector(
                  selectedTable: _selectedTable,
                  onTableSelected: (table) {
                    setState(() => _selectedTable = table);
                  },
                  l10n: l10n,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _peopleController,
                  decoration: InputDecoration(
                    labelText: l10n.people,
                    prefixIcon: const Icon(Icons.people),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: menuAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (menuItems) {
                    if (menuItems.isEmpty) {
                      return Center(child: Text(l10n.emptyMenu));
                    }

                    final grouped = <String, List<dynamic>>{};
                    for (final item in menuItems.where((m) => m.isAvailable)) {
                      grouped.putIfAbsent(item.category, () => []).add(item);
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final category = grouped.keys.elementAt(index);
                        final items = grouped[category]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                category,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ),
                            ...items.map((item) {
                              final quantity = _selectedItems[item.id] ?? 0;
                              return ListTile(
                                dense: true,
                                title: Text(item.name),
                                subtitle:
                                    Text('€${item.price.toStringAsFixed(2)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: quantity > 0
                                          ? () => setState(() {
                                                if (quantity == 1) {
                                                  _selectedItems
                                                      .remove(item.id);
                                                } else {
                                                  _selectedItems[item.id] =
                                                      quantity - 1;
                                                }
                                              })
                                          : null,
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      iconSize: 20,
                                    ),
                                    SizedBox(
                                      width: 24,
                                      child: Text(
                                        '$quantity',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: quantity > 0
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => setState(() {
                                        _selectedItems[item.id] = quantity + 1;
                                      }),
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.notes,
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.total,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '€${_total.toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : () => _createOrder(l10n),
                    icon: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(l10n.createOrder),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}


class _TableSelector extends ConsumerWidget {
  final TableModel? selectedTable;
  final void Function(TableModel?) onTableSelected;
  final AppLocalizations l10n;

  const _TableSelector({
    required this.selectedTable,
    required this.onTableSelected,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);

    return tablesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (tables) {
        // Filter available and reserved tables (not occupied or cleaning)
        final availableTables = tables
            .where((t) =>
                t.status == TableStatus.available ||
                t.status == TableStatus.reserved)
            .toList();

        if (availableTables.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.noTables,
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableTables.map((table) {
            final isSelected = selectedTable?.id == table.id;
            final color = table.status == TableStatus.reserved
                ? Colors.orange
                : Colors.green;

            return InkWell(
              onTap: () => onTableSelected(isSelected ? null : table),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : color,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.table_restaurant,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      table.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    Text(
                      '${table.capacity} ${l10n.seats}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (table.status == TableStatus.reserved &&
                        table.reservedBy != null)
                      Text(
                        table.reservedBy!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade700,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
