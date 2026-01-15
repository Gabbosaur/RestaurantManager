import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/restaurant_settings_provider.dart';
import '../../../../core/constants/menu_categories.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/tutorial/tutorial_service.dart';
import '../../../../core/tutorial/tutorial_wrapper.dart';
import '../../../../core/tutorial/tutorials.dart';
import '../../data/models/menu_item_model.dart';
import '../providers/menu_provider.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TutorialWrapper(
      tutorialId: TutorialService.salaMenu,
      stepsBuilder: getMenuTutorial,
      child: _MenuScreenContent(),
    );
  }
}

class _MenuScreenContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuProvider);
    final settingsAsync = ref.watch(restaurantSettingsProvider);
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);

    return Scaffold(
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (items) {
          final coverCharge = settingsAsync.valueOrNull?.coverCharge ?? 1.50;

          if (items.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Cover charge card (always visible)
                _buildCoverChargeCard(context, ref, l10n, coverCharge),
                const SizedBox(height: 32),
                Center(
                  child: Column(
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
                ),
              ],
            );
          }

          final grouped = <String, List<MenuItemModel>>{};
          for (final item in items) {
            grouped.putIfAbsent(item.category, () => []).add(item);
          }

          // Ordina le categorie secondo l'ordine del menu
          final sortedCategories = sortCategories(grouped.keys);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedCategories.length + 1, // +1 for cover charge
            itemBuilder: (context, index) {
              // First item is cover charge
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCoverChargeCard(context, ref, l10n, coverCharge),
                    const SizedBox(height: 16),
                  ],
                );
              }

              final categoryIndex = index - 1;
              final category = sortedCategories[categoryIndex];
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
                          subtitle: item.nameZh != null
                              ? Text(
                                  item.nameZh!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : (item.description != null
                                  ? Text(item.description!)
                                  : null),
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

  Widget _buildCoverChargeCard(
      BuildContext context, WidgetRef ref, AppLocalizations l10n, double coverCharge) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        leading: Icon(
          Icons.restaurant,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        title: Text(
          l10n.coverCharge,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Per persona',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
        trailing: Text(
          '€${coverCharge.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
        ),
        onTap: () => _showCoverChargeDialog(context, ref, l10n, coverCharge),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, MenuItemModel item,
      AppLocalizations l10n) {
    _showMenuItemDialog(context, ref, item, l10n);
  }

  void _showMenuItemDialog(BuildContext context, WidgetRef ref,
      MenuItemModel? item, AppLocalizations l10n) {
    final nameController = TextEditingController(text: item?.name);
    final nameZhController = TextEditingController(text: item?.nameZh);
    final descController = TextEditingController(text: item?.description);
    final priceController =
        TextEditingController(text: item?.price.toString() ?? '');
    String selectedCategory = item?.category ?? 'Altro';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                  controller: nameZhController,
                  decoration: const InputDecoration(
                    labelText: '中文名 (Nome cinese)',
                    hintText: 'Per la cucina',
                  ),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: l10n.category,
                    border: const OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: menuCategoryOrder.map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCategory = value);
                    }
                  },
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
                  nameZh: nameZhController.text.isNotEmpty
                      ? nameZhController.text
                      : null,
                  description: descController.text.isNotEmpty
                      ? descController.text
                      : null,
                  price: double.tryParse(priceController.text) ?? 0,
                  category: selectedCategory,
                  isAvailable: item?.isAvailable ?? true,
                  ingredientKey: item?.ingredientKey,
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
      ),
    );
  }

  void _showCoverChargeDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n, double currentPrice) {
    final priceController = TextEditingController(text: currentPrice.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.coverCharge),
        content: TextField(
          controller: priceController,
          decoration: InputDecoration(
            labelText: l10n.price,
            prefixText: '€ ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final newPrice = double.tryParse(priceController.text) ?? currentPrice;
              ref.read(restaurantSettingsProvider.notifier).updateCoverCharge(newPrice);
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
