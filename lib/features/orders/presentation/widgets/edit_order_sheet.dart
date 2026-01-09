import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/restaurant_settings_provider.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../inventory/presentation/providers/ingredients_provider.dart';
import '../../../menu/data/models/menu_item_model.dart';
import '../../../menu/presentation/providers/menu_provider.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';

/// Macro-categorie per i tab (stesse di CreateOrderSheet)
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

int? _extractNumber(String name) {
  final match = RegExp(r'^(\d+)\.?\s*').firstMatch(name);
  if (match != null) {
    return int.tryParse(match.group(1)!);
  }
  return null;
}

class EditOrderSheet extends ConsumerStatefulWidget {
  final OrderModel order;

  const EditOrderSheet({super.key, required this.order});

  @override
  ConsumerState<EditOrderSheet> createState() => _EditOrderSheetState();
}

class _EditOrderSheetState extends ConsumerState<EditOrderSheet>
    with SingleTickerProviderStateMixin {
  final Map<String, int> _selectedItems = {};
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCategories.length, vsync: this);
    // Inizializza con gli item esistenti
    for (final item in widget.order.items) {
      _selectedItems[item.menuItemId] = item.quantity;
    }
    _notesController.text = widget.order.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tabController.dispose();
    super.dispose();
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
    if (widget.order.isTakeaway) return 0;
    return coverCharge * (widget.order.numberOfPeople ?? 0);
  }

  double _getTotal(double coverCharge) {
    return _getItemsTotal() + _getCoverChargeTotal(coverCharge);
  }

  int get _totalItemsCount {
    return _selectedItems.values.fold(0, (sum, qty) => sum + qty);
  }

  Future<void> _saveChanges(AppLocalizations l10n, double coverCharge) async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectAtLeastOne)),
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
          nameZh: menuItem.nameZh,
          quantity: entry.value,
          price: menuItem.price,
        );
      }).toList();

      final total = _getTotal(coverCharge);

      await ref.read(ordersProvider.notifier).updateOrderItems(
            widget.order.id,
            orderItems,
            total,
          );

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
            // Header
            _buildHeader(context, l10n),
            // Tab bar
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
            // Menu items
            Expanded(
              child: menuAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (menuItems) => _buildTabContent(menuItems, unavailableIngredients),
              ),
            ),
            // Footer
            _buildFooter(context, l10n, coverCharge),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            widget.order.isTakeaway ? Icons.takeout_dining : Icons.restaurant,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.order.isTakeaway
                      ? l10n.takeaway
                      : '${l10n.table} ${widget.order.tableName ?? ""}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (!widget.order.isTakeaway && widget.order.numberOfPeople != null)
                  Text(
                    '${widget.order.numberOfPeople} ${l10n.people}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Text(
                  l10n.edit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              if (_hasChanges) {
                _showDiscardDialog(context, l10n);
              } else {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(List<MenuItemModel> menuItems, Set<String> unavailableIngredients) {
    return TabBarView(
      controller: _tabController,
      children: _tabCategories.map((tabCat) {
        final items = menuItems.where((item) {
          if (!item.isAvailable) return false;
          if (!tabCat.categories.contains(item.category)) return false;
          final isUnavailable = item.ingredientKey != null &&
              unavailableIngredients.contains(item.ingredientKey);
          final isSelected = _selectedItems.containsKey(item.id);
          return !isUnavailable || isSelected;
        }).toList();

        items.sort((a, b) {
          final numA = _extractNumber(a.name);
          final numB = _extractNumber(b.name);
          if (numA != null && numB != null) return numA.compareTo(numB);
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
                        _hasChanges = true;
                      }),
              onLongPress: qty > 0
                  ? () => setState(() {
                        if (qty == 1) {
                          _selectedItems.remove(item.id);
                        } else {
                          _selectedItems[item.id] = qty - 1;
                        }
                        _hasChanges = true;
                      })
                  : null,
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n, double coverCharge) {
    return Container(
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
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () => _showNotesDialog(l10n),
              icon: Badge(
                isLabelVisible: _notesController.text.isNotEmpty,
                child: const Icon(Icons.note_add),
              ),
              tooltip: l10n.notes,
            ),
            const SizedBox(width: 8),
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
            FilledButton.icon(
              onPressed: _isLoading || !_hasChanges
                  ? null
                  : () => _saveChanges(l10n, coverCharge),
              icon: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(l10n.save),
            ),
          ],
        ),
      ),
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

  void _showDiscardDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text(l10n.discardChangesQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(l10n.discard),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              final coverCharge = ref.read(restaurantSettingsProvider).valueOrNull?.coverCharge ?? 1.50;
              _saveChanges(l10n, coverCharge);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

/// Piatto compatto (copiato da CreateOrderSheet)
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

    return Material(
      color: isUnavailable
          ? Colors.grey.shade200
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
              if (_extractNumber(item.name) != null)
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : isUnavailable
                            ? Colors.grey.shade400
                            : primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      _extractNumber(item.name)!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected || isUnavailable ? Colors.white : primaryColor,
                      ),
                    ),
                  ),
                ),
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
                        color: isUnavailable ? Colors.grey : null,
                        decoration: isUnavailable ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '€${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isUnavailable ? Colors.grey : primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
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
    );
  }

  static String? _extractNumber(String name) {
    final match = RegExp(r'^(\d+)\.?\s*').firstMatch(name);
    return match?.group(1);
  }

  static String _extractName(String name) {
    return name.replaceFirst(RegExp(r'^\d+\.?\s*'), '');
  }
}
