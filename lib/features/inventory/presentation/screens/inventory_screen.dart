import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../data/models/ingredient_model.dart';
import '../providers/ingredients_provider.dart';
import '../providers/ingredient_usage_provider.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientsAsync = ref.watch(ingredientsProvider);
    final usageToday = ref.watch(ingredientUsageTodayProvider);
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);

    return Scaffold(
      body: ingredientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (ingredients) {
          if (ingredients.isEmpty) {
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

          final unavailable = ingredients.where((i) => !i.isAvailable).toList();
          final available = ingredients.where((i) => i.isAvailable).toList();

          // Ordina per utilizzo (più usati prima)
          available.sort((a, b) {
            final usageA = usageToday[a.id] ?? 0;
            final usageB = usageToday[b.id] ?? 0;
            return usageB.compareTo(usageA);
          });

          return Column(
            children: [
              // Header con info
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.ingredientsInfo,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Lista ingredienti
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Ingredienti non disponibili (in rosso)
                    if (unavailable.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.unavailableIngredients,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...unavailable.map((ingredient) => _IngredientTile(
                            ingredient: ingredient,
                            usageCount: usageToday[ingredient.id] ?? 0,
                            l10n: l10n,
                            onToggle: (value) {
                              ref
                                  .read(ingredientsProvider.notifier)
                                  .toggleAvailability(ingredient.id, value);
                            },
                          )),
                      const SizedBox(height: 24),
                    ],
                    // Ingredienti disponibili
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.availableIngredients,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            ref.read(ingredientsProvider.notifier).setAllAvailable();
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: Text(l10n.resetAll),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...available.map((ingredient) => _IngredientTile(
                          ingredient: ingredient,
                          usageCount: usageToday[ingredient.id] ?? 0,
                          l10n: l10n,
                          onToggle: (value) {
                            ref
                                .read(ingredientsProvider.notifier)
                                .toggleAvailability(ingredient.id, value);
                          },
                        )),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final IngredientModel ingredient;
  final int usageCount;
  final AppLocalizations l10n;
  final ValueChanged<bool> onToggle;

  const _IngredientTile({
    required this.ingredient,
    required this.usageCount,
    required this.l10n,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = ingredient.isAvailable;
    final isHighUsage = usageCount >= 10; // Soglia per "molto richiesto"

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isAvailable
          ? null
          : Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
      child: ListTile(
        leading: Icon(
          isAvailable ? Icons.check_circle : Icons.cancel,
          color: isAvailable
              ? Colors.green
              : Theme.of(context).colorScheme.error,
          size: 28,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                ingredient.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  decoration: isAvailable ? null : TextDecoration.lineThrough,
                  color: isAvailable ? null : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            // Badge con conteggio ordini oggi
            if (usageCount > 0) ...[
              const SizedBox(width: 8),
              _UsageBadge(
                count: usageCount,
                isHighUsage: isHighUsage,
                l10n: l10n,
              ),
            ],
          ],
        ),
        subtitle: usageCount > 0
            ? Text(
                l10n.orderedToday(usageCount),
                style: TextStyle(
                  fontSize: 12,
                  color: isHighUsage
                      ? Colors.orange.shade700
                      : Theme.of(context).colorScheme.outline,
                ),
              )
            : null,
        trailing: Switch(
          value: isAvailable,
          onChanged: onToggle,
          activeColor: Colors.green,
        ),
      ),
    );
  }
}

class _UsageBadge extends StatelessWidget {
  final int count;
  final bool isHighUsage;
  final AppLocalizations l10n;

  const _UsageBadge({
    required this.count,
    required this.isHighUsage,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighUsage
            ? Colors.orange.shade100
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isHighUsage
            ? Border.all(color: Colors.orange.shade400)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isHighUsage) ...[
            Icon(
              Icons.local_fire_department,
              size: 14,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isHighUsage
                  ? Colors.orange.shade700
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
