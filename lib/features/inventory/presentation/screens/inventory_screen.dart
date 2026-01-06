import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../data/models/inventory_item_model.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);

    return Scaffold(
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.emptyInventory,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          final lowStock = items.where((i) => i.isLowStock).toList();
          final normalStock = items.where((i) => !i.isLowStock).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (lowStock.isNotEmpty) ...[
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.itemsLowStock(lowStock.length),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.lowStock,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const SizedBox(height: 8),
                ...lowStock.map((item) => _InventoryCard(
                      item: item,
                      l10n: l10n,
                      onTap: () => _showEditDialog(context, ref, item, l10n),
                      onRestock: () =>
                          _showRestockDialog(context, ref, item, l10n),
                    )),
                const SizedBox(height: 16),
              ],
              if (normalStock.isNotEmpty) ...[
                Text(
                  l10n.inStock,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...normalStock.map((item) => _InventoryCard(
                      item: item,
                      l10n: l10n,
                      onTap: () => _showEditDialog(context, ref, item, l10n),
                      onRestock: () =>
                          _showRestockDialog(context, ref, item, l10n),
                    )),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref, l10n),
        icon: const Icon(Icons.add),
        label: Text(l10n.add),
      ),
    );
  }

  void _showAddDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    _showItemDialog(context, ref, null, l10n);
  }

  void _showEditDialog(BuildContext context, WidgetRef ref,
      InventoryItemModel item, AppLocalizations l10n) {
    _showItemDialog(context, ref, item, l10n);
  }

  void _showItemDialog(BuildContext context, WidgetRef ref,
      InventoryItemModel? item, AppLocalizations l10n) {
    final nameController = TextEditingController(text: item?.name);
    final quantityController =
        TextEditingController(text: item?.quantity.toString() ?? '0');
    final unitController = TextEditingController(text: item?.unit ?? 'pz');
    final minController =
        TextEditingController(text: item?.minQuantity.toString() ?? '10');
    final supplierController = TextEditingController(text: item?.supplier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? l10n.newProduct : l10n.editProduct),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.name),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: quantityController,
                      decoration: InputDecoration(labelText: l10n.quantity),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: InputDecoration(labelText: l10n.unit),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: minController,
                decoration: InputDecoration(labelText: l10n.minStock),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: supplierController,
                decoration: InputDecoration(labelText: l10n.supplier),
              ),
            ],
          ),
        ),
        actions: [
          if (item != null)
            TextButton(
              onPressed: () {
                ref.read(inventoryProvider.notifier).deleteItem(item.id);
                Navigator.pop(context);
              },
              child: Text(
                l10n.delete,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final newItem = InventoryItemModel(
                id: item?.id ?? const Uuid().v4(),
                name: nameController.text,
                quantity: double.tryParse(quantityController.text) ?? 0,
                unit: unitController.text,
                minQuantity: double.tryParse(minController.text) ?? 10,
                supplier: supplierController.text.isNotEmpty
                    ? supplierController.text
                    : null,
                lastRestocked: item?.lastRestocked,
                createdAt: item?.createdAt ?? DateTime.now(),
              );

              if (item == null) {
                ref.read(inventoryProvider.notifier).addItem(newItem);
              } else {
                ref.read(inventoryProvider.notifier).updateItem(newItem);
              }
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showRestockDialog(BuildContext context, WidgetRef ref,
      InventoryItemModel item, AppLocalizations l10n) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.restock} ${item.name}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '${l10n.addQuantity} (${item.unit})',
            hintText: '${l10n.quantity}: ${item.quantity.toStringAsFixed(1)}',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final addQty = double.tryParse(controller.text) ?? 0;
              ref.read(inventoryProvider.notifier).updateQuantity(
                    item.id,
                    item.quantity + addQty,
                  );
              Navigator.pop(context);
            },
            child: Text(l10n.restock),
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItemModel item;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onRestock;

  const _InventoryCard({
    required this.item,
    required this.l10n,
    required this.onTap,
    required this.onRestock,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(item.name),
        subtitle: Text(item.supplier ?? l10n.noSupplier),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.quantity.toStringAsFixed(1)} ${item.unit}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.isLowStock
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
                Text(
                  'Min: ${item.minQuantity.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRestock,
              icon: const Icon(Icons.add_circle_outline),
              tooltip: l10n.restock,
            ),
          ],
        ),
      ),
    );
  }
}
