import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/restaurant_settings_provider.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../inventory/presentation/providers/ingredients_provider.dart';
import '../../../menu/data/models/menu_item_model.dart';
import '../../../menu/presentation/providers/menu_provider.dart';
import '../../../tables/data/models/table_model.dart';
import '../../../tables/presentation/providers/tables_provider.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';

/// Macro-categorie per i tab
const List<_TabCategory> _tabCategories = [
  _TabCategory('Antipasti', ['Antipasti', 'Zuppe'], Icons.restaurant_menu),
  _TabCategory('Primi', ['Primi - Riso', 'Primi - Spaghetti', 'Primi - Ravioli'], Icons.ramen_dining),
  _TabCategory('Secondi', ['Secondi - Anatra', 'Secondi - Pollo', 'Secondi - Vitello', 'Secondi - Maiale', 'Secondi - Gamberi', 'Secondi - Pesce'], Icons.set_meal),
  _TabCategory('Contorni', ['Contorni'], Icons.eco),
  _TabCategory('Dolci', ['Dolci'], Icons.cake),
  _TabCategory('Bevande', ['Bevande - Vini', 'Bevande - Birre', 'Bevande - Analcoliche', 'Bevande - Altro'], Icons.local_bar),
];

class _TabCategory {
  final String name;
  final List<String> categories;
  final IconData icon;
  const _TabCategory(this.name, this.categories, this.icon);
}

/// Estrae il numero dal nome (es. 21 da "21. Riso Xin Xing")
int? _extractNumber(String name) {
  final match = RegExp(r'^(\d+)\.?\s*').firstMatch(name);
  if (match != null) {
    return int.tryParse(match.group(1)!);
  }
  return null;
}

class CreateOrderSheet extends ConsumerStatefulWidget {
  final TableModel? preselectedTable;

  const CreateOrderSheet({super.key, this.preselectedTable});

  @override
  ConsumerState<CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends ConsumerState<CreateOrderSheet>
    with SingleTickerProviderStateMixin {
  int _numberOfPeople = 2;
  final _notesController = TextEditingController();
  final Map<String, int> _selectedItems = {};
  bool _isLoading = false;
  OrderType _orderType = OrderType.table;
  TableModel? _selectedTable;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCategories.length, vsync: this);
    // Pre-seleziona il tavolo se passato
    if (widget.preselectedTable != null) {
      _selectedTable = widget.preselectedTable;
      _orderType = OrderType.table;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

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

  int get _totalItemsCount {
    return _selectedItems.values.fold(0, (sum, qty) => sum + qty);
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
      final shouldProceed = await _showUnavailableItemsDialog(l10n, unavailableSelected);
      if (shouldProceed == null) return;
      if (!shouldProceed) {
        _removeUnavailableItems(unavailableSelected);
        return;
      }
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
      final numberOfPeople = _orderType == OrderType.table ? _numberOfPeople : null;

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

  Future<bool?> _showUnavailableItemsDialog(
    AppLocalizations l10n,
    List<MenuItemModel> unavailableItems,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 48),
        title: Text(l10n.someItemsUnavailable),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: unavailableItems
              .map((item) => Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red.shade400, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${item.name} (x${_selectedItems[item.id]})')),
                    ],
                  ))
              .toList(),
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

    final unavailableIngredients = ingredientsAsync.valueOrNull
            ?.where((i) => !i.isAvailable)
            .map((i) => i.id)
            .toSet() ??
        {};

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header compatto
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  // Tipo ordine + tavolo/asporto
                  Expanded(
                    child: Row(
                      children: [
                        // Toggle Tavolo/Asporto compatto
                        ToggleButtons(
                          isSelected: [
                            _orderType == OrderType.table,
                            _orderType == OrderType.takeaway,
                          ],
                          onPressed: (index) {
                            setState(() {
                              _orderType = index == 0 ? OrderType.table : OrderType.takeaway;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          constraints: const BoxConstraints(minHeight: 36, minWidth: 50),
                          children: const [
                            Icon(Icons.restaurant, size: 20),
                            Icon(Icons.takeout_dining, size: 20),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Tavolo selector o Asporto label
                        if (_orderType == OrderType.table)
                          Expanded(child: _CompactTableSelector(
                            selectedTable: _selectedTable,
                            onTableSelected: (t) => setState(() => _selectedTable = t),
                          ))
                        else
                          Text(l10n.takeaway, style: const TextStyle(fontWeight: FontWeight.bold)),
                        // Persone (solo per tavolo)
                        if (_orderType == OrderType.table) ...[
                          const SizedBox(width: 8),
                          _CompactPeopleSelector(
                            value: _numberOfPeople,
                            onChanged: (v) => setState(() => _numberOfPeople = v),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // Tab bar per categorie
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              tabs: _tabCategories.map((cat) => Tab(
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 18),
                    const SizedBox(width: 4),
                    Text(cat.name, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              )).toList(),
            ),
            // Menu items in griglia
            Expanded(
              child: menuAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (menuItems) {
                  return TabBarView(
                    controller: _tabController,
                    children: _tabCategories.map((tabCat) {
                      // Filtra piatti per questa tab - mostra TUTTI inclusi esauriti
                      final items = menuItems.where((item) {
                        if (!item.isAvailable) return false;
                        if (!tabCat.categories.contains(item.category)) return false;
                        return true;
                      }).toList();

                      // Ordina per numero (estrae il numero dal nome)
                      items.sort((a, b) {
                        final numA = _extractNumber(a.name);
                        final numB = _extractNumber(b.name);
                        if (numA != null && numB != null) {
                          return numA.compareTo(numB);
                        }
                        return a.name.compareTo(b.name);
                      });

                      if (items.isEmpty) {
                        return const Center(child: Text('Nessun piatto'));
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          childAspectRatio: 1.8,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final qty = _selectedItems[item.id] ?? 0;
                          final isUnavailable = item.ingredientKey != null &&
                              unavailableIngredients.contains(item.ingredientKey);

                          return _CompactMenuItem(
                            item: item,
                            quantity: qty,
                            isUnavailable: isUnavailable,
                            onTap: isUnavailable
                                ? null
                                : () => setState(() {
                                      _selectedItems[item.id] = qty + 1;
                                    }),
                            onLongPress: qty > 0
                                ? () => setState(() {
                                      if (qty == 1) {
                                        _selectedItems.remove(item.id);
                                      } else {
                                        _selectedItems[item.id] = qty - 1;
                                      }
                                    })
                                : null,
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            // Footer con totale e bottone
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Note (icona che apre dialog)
                  IconButton(
                    onPressed: () => _showNotesDialog(l10n),
                    icon: Badge(
                      isLabelVisible: _notesController.text.isNotEmpty,
                      child: const Icon(Icons.note_add),
                    ),
                    tooltip: l10n.notes,
                  ),
                  const SizedBox(width: 8),
                  // Totale
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_totalItemsCount piatti',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          '€${_getTotal(coverCharge).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottone crea ordine
                  FilledButton.icon(
                    onPressed: _isLoading || _selectedItems.isEmpty
                        ? null
                        : () => _createOrder(l10n, coverCharge),
                    icon: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(l10n.createOrder),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNotesDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notes),
        content: TextField(
          controller: _notesController,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Es: senza cipolla, allergie...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}


/// Piatto compatto in griglia - tap per aggiungere, long press per rimuovere
class _CompactMenuItem extends StatelessWidget {
  final MenuItemModel item;
  final int quantity;
  final bool isUnavailable;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _CompactMenuItem({
    required this.item,
    required this.quantity,
    required this.isUnavailable,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = quantity > 0;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colori per piatti esauriti che funzionano in entrambi i temi
    final unavailableBgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final unavailableTextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    final unavailableNumberBgColor = isDark ? Colors.grey.shade700 : Colors.grey.shade400;

    return Opacity(
      opacity: isUnavailable ? 0.5 : 1.0,
      child: Material(
        color: isUnavailable
            ? unavailableBgColor
            : isSelected
                ? primaryColor.withOpacity(0.15)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(color: primaryColor, width: 2) : null,
            ),
            child: Row(
              children: [
                // Numero a sinistra in evidenza
                if (_extractNumber(item.name) != null)
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor
                          : isUnavailable
                              ? unavailableNumberBgColor
                              : primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        _extractNumber(item.name)!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : isUnavailable
                                  ? (isDark ? Colors.grey.shade400 : Colors.white)
                                  : primaryColor,
                        ),
                      ),
                    ),
                  ),
                // Nome e prezzo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _extractName(item.name),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isUnavailable ? unavailableTextColor : null,
                          decoration:
                              isUnavailable ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '€${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isUnavailable ? unavailableTextColor : primaryColor,
                          fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge quantità
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  /// Estrae il numero dal nome (es. "01" da "01. Antipasto Misto")
  static String? _extractNumber(String name) {
    final match = RegExp(r'^(\d+)\.?\s*').firstMatch(name);
    return match?.group(1);
  }

  /// Estrae il nome senza numero (es. "Antipasto Misto" da "01. Antipasto Misto")
  static String _extractName(String name) {
    return name.replaceFirst(RegExp(r'^\d+\.?\s*'), '');
  }
}

/// Selettore tavolo compatto (dropdown)
class _CompactTableSelector extends ConsumerWidget {
  final TableModel? selectedTable;
  final void Function(TableModel?) onTableSelected;

  const _CompactTableSelector({
    required this.selectedTable,
    required this.onTableSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);

    return tablesAsync.when(
      loading: () => const SizedBox(width: 80, child: LinearProgressIndicator()),
      error: (e, _) => const Text('Errore'),
      data: (tables) {
        final availableTables = tables
            .where((t) =>
                t.status == TableStatus.available ||
                t.status == TableStatus.reserved)
            .toList();

        if (availableTables.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('No tavoli', style: TextStyle(fontSize: 12)),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedTable?.id,
              hint: const Text('Tavolo', style: TextStyle(fontSize: 13)),
              isDense: true,
              items: availableTables.map((t) => DropdownMenuItem(
                value: t.id,
                child: Text(t.name, style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: (id) {
                if (id == null) {
                  onTableSelected(null);
                } else {
                  onTableSelected(availableTables.firstWhere((t) => t.id == id));
                }
              },
            ),
          ),
        );
      },
    );
  }
}

/// Selettore persone compatto
class _CompactPeopleSelector extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;

  const _CompactPeopleSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: value > 1 ? () => onChanged(value - 1) : null,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.remove, size: 18, color: value > 1 ? null : Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Icon(Icons.people, size: 16),
                const SizedBox(width: 4),
                Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          InkWell(
            onTap: value < 50 ? () => onChanged(value + 1) : null,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.add, size: 18, color: value < 50 ? null : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
