import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../data/models/menu_item_model.dart';
import '../providers/menu_provider.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuProvider);
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);

    return Scaffold(
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.emptyMenu,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          final grouped = <String, List<MenuItemModel>>{};
          for (final item in items) {
            grouped.putIfAbsent(item.category, () => []).add(item);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final category = grouped.keys.elementAt(index);
              final categoryItems = grouped[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...categoryItems.map((item) => Card(
                        child: ListTile(
                          title: Text(
                            item.name,
                            style: TextStyle(
                              decoration: item.isAvailable
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                          subtitle: item.description != null
                              ? Text(item.description!)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '€${item.price.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: item.isAvailable,
                                onChanged: (value) {
                                  ref
                                      .read(menuProvider.notifier)
                                      .toggleAvailability(item.id, value);
                                },
                              ),
                            ],
                          ),
                          onTap: () =>
                              _showEditDialog(context, ref, item, l10n),
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
              );
            },
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
    _showMenuItemDialog(context, ref, null, l10n);
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, MenuItemModel item,
      AppLocalizations l10n) {
    _showMenuItemDialog(context, ref, item, l10n);
  }

  void _showMenuItemDialog(BuildContext context, WidgetRef ref,
      MenuItemModel? item, AppLocalizations l10n) {
    final nameController = TextEditingController(text: item?.name);
    final descController = TextEditingController(text: item?.description);
    final priceController =
        TextEditingController(text: item?.price.toString() ?? '');
    final categoryController =
        TextEditingController(text: item?.category ?? 'Altro');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? l10n.newDish : l10n.editDish),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.name),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                decoration: InputDecoration(labelText: l10n.description),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: l10n.price,
                  prefixText: '€ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(labelText: l10n.category),
              ),
            ],
          ),
        ),
        actions: [
          if (item != null)
            TextButton(
              onPressed: () {
                ref.read(menuProvider.notifier).deleteMenuItem(item.id);
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
              final newItem = MenuItemModel(
                id: item?.id ?? const Uuid().v4(),
                name: nameController.text,
                description: descController.text.isNotEmpty
                    ? descController.text
                    : null,
                price: double.tryParse(priceController.text) ?? 0,
                category: categoryController.text,
                isAvailable: item?.isAvailable ?? true,
                createdAt: item?.createdAt ?? DateTime.now(),
              );

              if (item == null) {
                ref.read(menuProvider.notifier).addMenuItem(newItem);
              } else {
                ref.read(menuProvider.notifier).updateMenuItem(newItem);
              }
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
