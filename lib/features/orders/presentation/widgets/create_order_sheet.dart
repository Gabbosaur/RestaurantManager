import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/restaurant_settings_provider.dart';
import '../../../../core/constants/menu_categories.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../inventory/presentation/providers/ingredients_provider.dart';
import '../../../menu/data/models/menu_item_model.dart';
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
  int _numberOfPeople = 2;
  final _notesController = TextEditingController();
  final Map<String, int> _selectedItems = {};
  bool _isLoading = false;
  OrderType _orderType = OrderType.table;
  TableModel? _selectedTable;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Trova i piatti selezionati che ora hanno ingredienti non disponibili
  List<MenuItemModel> _getUnavailableSelectedItems(
    List<MenuItemModel> menuItems,
    Set<String> unavailableIngredients,
  ) {
    final unavailableSelected = <MenuItemModel>[];
    for (final itemId in _selectedItems.keys) {
      final menuItem = menuItems.firstWhere(
        (m) => m.id == itemId,
        orElse: () => menuItems.first,
      );
      if (menuItem.ingredientKey != null &&
          unavailableIngredients.contains(menuItem.ingredientKey)) {
        unavailableSelected.add(menuItem);
      }
    }
    return unavailableSelected;
  }

  /// Rimuove i piatti non disponibili dalla selezione
  void _removeUnavailableItems(List<MenuItemModel> unavailableItems) {
    setState(() {
      for (final item in unavailableItems) {
        _selectedItems.remove(item.id);
      }
    });
  }

  double _getItemsTotal() {
    final menuItems = ref.read(menuProvider).valueOrNull ?? [];
    double sum = 0;
    for (final entry in _selectedItems.entries) {
      final item = menuItems.firstWhere(
        (m) => m.id == entry.key,
        orElse: () => menuItems.first,
      );
      sum += item.price * entry.value;
    }
    return sum;
  }

  double _getCoverChargeTotal(double coverCharge) {
    if (_orderType == OrderType.takeaway) return 0;
    return coverCharge * _numberOfPeople;
  }

  double _getTotal(double coverCharge) {
    return _getItemsTotal() + _getCoverChargeTotal(coverCharge);
  }

  Future<void> _createOrder(AppLocalizations l10n, double coverCharge) async {
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

    // Validazione finale: controlla se ci sono piatti con ingredienti ora non disponibili
    final menuItems = ref.read(menuProvider).valueOrNull ?? [];
    final unavailableIngredients = ref
            .read(ingredientsProvider)
            .valueOrNull
            ?.where((i) => !i.isAvailable)
            .map((i) => i.id)
            .toSet() ??
        {};

    final unavailableSelected =
        _getUnavailableSelectedItems(menuItems, unavailableIngredients);

    if (unavailableSelected.isNotEmpty) {
      // Mostra dialog di conferma
      final shouldProceed = await _showUnavailableItemsDialog(
        l10n,
        unavailableSelected,
      );
      if (shouldProceed == null) return; // Dialog dismissed
      if (!shouldProceed) {
        // Rimuovi i piatti non disponibili
        _removeUnavailableItems(unavailableSelected);
        return;
      }
      // shouldProceed == true: procedi comunque (papà ha detto ok)
    }

    setState(() => _isLoading = true);

    try {
      final orderItems = _selectedItems.entries.map((entry) {
        final menuItem = menuItems.firstWhere((m) => m.id == entry.key);
        return OrderItem(
          menuItemId: menuItem.id,
          name: menuItem.name,
          nameZh: menuItem.nameZh,
          quantity: entry.value,
          price: menuItem.price,
        );
      }).toList();

      final orderId = const Uuid().v4();
      final numberOfPeople =
          _orderType == OrderType.table ? _numberOfPeople : null;

      final order = OrderModel(
        id: orderId,
        tableId: _orderType == OrderType.table ? _selectedTable!.id : null,
        tableName: _orderType == OrderType.table ? _selectedTable!.name : null,
        orderType: _orderType,
        numberOfPeople: numberOfPeople,
        items: orderItems,
        status: OrderStatus.pending,
        total: _getTotal(coverCharge),
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

  /// Dialog per gestire piatti con ingredienti non più disponibili
  Future<bool?> _showUnavailableItemsDialog(
    AppLocalizations l10n,
    List<MenuItemModel> unavailableItems,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange.shade700,
          size: 48,
        ),
        title: Text(l10n.someItemsUnavailable),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...unavailableItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red.shade400, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.name} (x${_selectedItems[item.id]})',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            Text(
              l10n.discardChangesQuestion,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.removeUnavailable),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.proceedAnyway),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuProvider);
    final ingredientsAsync = ref.watch(ingredientsProvider);
    final settingsAsync = ref.watch(restaurantSettingsProvider);
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);
    final coverCharge = settingsAsync.valueOrNull?.coverCharge ?? 1.50;

    // Get unavailable ingredient keys
    final unavailableIngredients = ingredientsAsync.valueOrNull
            ?.where((i) => !i.isAvailable)
            .map((i) => i.id)
            .toSet() ??
        {};

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
                const SizedBox(height: 8),
                // People counter with +/- buttons (max 50)
                Row(
                  children: [
                    const Icon(Icons.people, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.people, style: const TextStyle(fontSize: 14)),
                    const Spacer(),
                    IconButton(
                      onPressed: _numberOfPeople > 1
                          ? () => setState(() => _numberOfPeople--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 28,
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '$_numberOfPeople',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _numberOfPeople < 50
                          ? () => setState(() => _numberOfPeople++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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

                    // Raggruppa per categoria, mostrando anche i piatti selezionati
                    // anche se ora non disponibili (con warning)
                    final grouped = <String, List<_MenuItemWithStatus>>{};

                    for (final item in menuItems) {
                      if (!item.isAvailable) continue;

                      final isUnavailable = item.ingredientKey != null &&
                          unavailableIngredients.contains(item.ingredientKey);
                      final isSelected = _selectedItems.containsKey(item.id);

                      // Mostra se: disponibile OPPURE già selezionato (con warning)
                      if (!isUnavailable || isSelected) {
                        grouped.putIfAbsent(item.category, () => []).add(
                              _MenuItemWithStatus(
                                item: item,
                                isUnavailable: isUnavailable,
                              ),
                            );
                      }
                    }

                    // Ordina le categorie secondo l'ordine del menu
                    final sortedCategories = sortCategories(grouped.keys);

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: sortedCategories.length,
                      itemBuilder: (context, index) {
                        final category = sortedCategories[index];
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
                            ...items.map((itemStatus) {
                              final item = itemStatus.item;
                              final isUnavailable = itemStatus.isUnavailable;
                              final quantity = _selectedItems[item.id] ?? 0;

                              return _MenuItemTile(
                                item: item,
                                quantity: quantity,
                                isUnavailable: isUnavailable,
                                l10n: l10n,
                                onIncrement: isUnavailable
                                    ? null
                                    : () => setState(() {
                                          _selectedItems[item.id] =
                                              quantity + 1;
                                        }),
                                onDecrement: quantity > 0
                                    ? () => setState(() {
                                          if (quantity == 1) {
                                            _selectedItems.remove(item.id);
                                          } else {
                                            _selectedItems[item.id] =
                                                quantity - 1;
                                          }
                                        })
                                    : null,
                              );
                            }),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 8),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.notes,
                  prefixIcon: const Icon(Icons.note, size: 20),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_orderType == OrderType.table) ...[
                        Text(
                          '${l10n.coverCharge}: €${_getCoverChargeTotal(coverCharge).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      Text(
                        l10n.total,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '€${_getTotal(coverCharge).toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed:
                        _isLoading ? null : () => _createOrder(l10n, coverCharge),
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

class _MenuItemWithStatus {
  final MenuItemModel item;
  final bool isUnavailable;

  _MenuItemWithStatus({required this.item, required this.isUnavailable});
}

class _MenuItemTile extends StatelessWidget {
  final MenuItemModel item;
  final int quantity;
  final bool isUnavailable;
  final AppLocalizations l10n;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const _MenuItemTile({
    required this.item,
    required this.quantity,
    required this.isUnavailable,
    required this.l10n,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: isUnavailable && quantity > 0
          ? const EdgeInsets.symmetric(vertical: 2)
          : null,
      decoration: isUnavailable && quantity > 0
          ? BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            )
          : null,
      child: ListTile(
        dense: true,
        title: Row(
          children: [
            Expanded(child: Text(item.name)),
            if (isUnavailable && quantity > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber,
                        size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      l10n.ingredientNowUnavailable,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: Text('€${item.price.toStringAsFixed(2)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 20,
            ),
            SizedBox(
              width: 24,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: quantity > 0 ? FontWeight.bold : FontWeight.normal,
                  color: isUnavailable && quantity > 0
                      ? Colors.orange.shade700
                      : null,
                ),
              ),
            ),
            IconButton(
              onPressed: onIncrement,
              icon: Icon(
                Icons.add_circle_outline,
                color: isUnavailable ? Colors.grey.shade400 : null,
              ),
              iconSize: 20,
            ),
          ],
        ),
      ),
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
        // Filter available and reserved tables (not occupied)
        final availableTables = tables
            .where((t) =>
                t.status == TableStatus.available ||
                t.status == TableStatus.reserved)
            .toList();

        if (availableTables.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.noTables,
                    style: const TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }

        // Compact horizontal scrollable list
        return SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: availableTables.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final table = availableTables[index];
              final isSelected = selectedTable?.id == table.id;
              final isReserved = table.status == TableStatus.reserved;
              final color = isReserved ? Colors.orange : Colors.green;

              return InkWell(
                onTap: () => onTableSelected(isSelected ? null : table),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.table_restaurant,
                        size: 20,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : color,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            table.name,
                            style: TextStyle(
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          Text(
                            isReserved && table.reservedBy != null
                                ? table.reservedBy!
                                : '${table.capacity} posti',
                            style: TextStyle(
                              fontSize: 11,
                              color: isReserved
                                  ? Colors.orange.shade700
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
