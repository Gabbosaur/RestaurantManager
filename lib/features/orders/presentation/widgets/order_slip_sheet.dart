import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../menu/data/models/menu_item_model.dart';
import '../../../menu/presentation/providers/menu_provider.dart';
import '../../../tables/data/models/table_model.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';

/// Order slip widget that simulates a paper notepad
/// Layout: Table number + people (top-left), Drinks (top-right), Food (below)
class OrderSlipSheet extends ConsumerStatefulWidget {
  final TableModel table;
  final OrderModel order;

  const OrderSlipSheet({
    super.key,
    required this.table,
    required this.order,
  });

  @override
  ConsumerState<OrderSlipSheet> createState() => _OrderSlipSheetState();
}

class _OrderSlipSheetState extends ConsumerState<OrderSlipSheet> {
  late Map<String, int> _items; // menuItemId -> quantity
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing order items
    _items = {};
    for (final item in widget.order.items) {
      _items[item.menuItemId] = item.quantity;
    }
  }

  double _calculateTotal(List<MenuItemModel> menuItems) {
    double sum = 0;
    for (final entry in _items.entries) {
      final menuItem = menuItems.firstWhere(
        (m) => m.id == entry.key,
        orElse: () => MenuItemModel(
          id: '',
          name: '',
          price: 0,
          category: '',
          createdAt: DateTime.now(),
        ),
      );
      sum += menuItem.price * entry.value;
    }
    return sum;
  }

  void _updateQuantity(String menuItemId, int delta) {
    setState(() {
      final current = _items[menuItemId] ?? 0;
      final newQty = current + delta;
      if (newQty <= 0) {
        _items.remove(menuItemId);
      } else {
        _items[menuItemId] = newQty;
      }
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges(List<MenuItemModel> menuItems) async {
    setState(() => _isLoading = true);

    try {
      final orderItems = _items.entries.map((entry) {
        final menuItem = menuItems.firstWhere((m) => m.id == entry.key);
        return OrderItem(
          menuItemId: menuItem.id,
          name: menuItem.name,
          quantity: entry.value,
          price: menuItem.price,
        );
      }).toList();

      final total = _calculateTotal(menuItems);

      await ref
          .read(ordersProvider.notifier)
          .updateOrderItems(widget.order.id, orderItems, total);

      if (mounted) {
        Navigator.pop(context);
      }
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
        return Container(
          decoration: BoxDecoration(
            // Paper-like background
            color: const Color(0xFFFFFBE6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: menuAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (menuItems) {
              // Separate drinks and food
              final drinks = menuItems
                  .where((m) => m.category == 'Bevande' && m.isAvailable)
                  .toList();
              final food = menuItems
                  .where((m) => m.category != 'Bevande' && m.isAvailable)
                  .toList();

              // Group food by category
              final foodByCategory = <String, List<MenuItemModel>>{};
              for (final item in food) {
                foodByCategory.putIfAbsent(item.category, () => []).add(item);
              }

              return Column(
                children: [
                  // Header - like top of notepad
                  _buildHeader(context, l10n, menuItems),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top section: Drinks
                          _buildSection(
                            context,
                            l10n.drinks,
                            Icons.local_bar,
                            Colors.blue,
                            drinks,
                          ),
                          const Divider(height: 32),
                          // Food sections by category
                          ...foodByCategory.entries.map((entry) {
                            return _buildSection(
                              context,
                              entry.key,
                              Icons.restaurant,
                              Colors.orange,
                              entry.value,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  // Footer with total and save
                  _buildFooter(context, l10n, menuItems),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, AppLocalizations l10n, List<MenuItemModel> menu) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(color: Colors.brown.shade300, width: 2),
        ),
      ),
      child: Row(
        children: [
          // Table info (top-left of notepad)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.table_restaurant,
                        color: Colors.brown.shade700, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      widget.table.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                if (widget.order.numberOfPeople != null)
                  Row(
                    children: [
                      Icon(Icons.people,
                          color: Colors.brown.shade600, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.order.numberOfPeople} ${l10n.people}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.brown.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Close button
          IconButton(
            onPressed: () {
              if (_hasChanges) {
                _showDiscardDialog(context, l10n, menu);
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

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<MenuItemModel> items,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => _buildMenuItem(item, color)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMenuItem(MenuItemModel item, Color accentColor) {
    final quantity = _items[item.id] ?? 0;
    final isSelected = quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: accentColor.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          // Quick add button
          InkWell(
            onTap: () => _updateQuantity(item.id, 1),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.add_circle,
                color: isSelected ? accentColor : Colors.grey,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Item name and price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: Colors.brown.shade800,
                  ),
                ),
                Text(
                  '€${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.brown.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Quantity controls
          if (isSelected) ...[
            IconButton(
              onPressed: () => _updateQuantity(item.id, -1),
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 20,
              color: Colors.red,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Container(
              width: 32,
              alignment: Alignment.center,
              child: Text(
                '$quantity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _updateQuantity(item.id, 1),
              icon: const Icon(Icons.add_circle_outline),
              iconSize: 20,
              color: Colors.green,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(
      BuildContext context, AppLocalizations l10n, List<MenuItemModel> menu) {
    final total = _calculateTotal(menu);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        border: Border(
          top: BorderSide(color: Colors.brown.shade300, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Total
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.total,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.brown.shade600,
                    ),
                  ),
                  Text(
                    '€${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800,
                    ),
                  ),
                ],
              ),
            ),
            // Save button
            FilledButton.icon(
              onPressed:
                  _isLoading || !_hasChanges ? null : () => _saveChanges(menu),
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(l10n.save),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.brown,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDiscardDialog(
      BuildContext context, AppLocalizations l10n, List<MenuItemModel> menu) {
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
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close sheet
            },
            child: Text(l10n.discard),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _saveChanges(menu);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
