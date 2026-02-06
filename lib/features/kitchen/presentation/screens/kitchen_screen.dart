import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/display_settings_provider.dart';
import '../../../../core/config/text_size_provider.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/tutorial/tutorial_service.dart';
import '../../../../core/tutorial/tutorial_wrapper.dart';
import '../../../../core/tutorial/tutorials.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

class KitchenScreen extends ConsumerWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TutorialWrapper(
      tutorialId: TutorialService.kitchen,
      stepsBuilder: getKitchenTutorial,
      child: _KitchenScreenContent(),
    );
  }
}

class _KitchenScreenContent extends ConsumerWidget {
  void _showIngredientsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => const InventoryScreen(),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final currentTheme = ref.watch(themeProvider);
          final currentLang = ref.watch(languageProvider);
          final textScale = ref.watch(textScaleProvider);
          final hideBeverages = ref.watch(hideKitchenBeveragesProvider);

          return AlertDialog(
            title: Text(l10n.settings),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text size section
                  Text(
                    l10n.textSize,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.text_fields, size: 18),
                      Expanded(
                        child: Slider(
                          value: textScale,
                          min: TextScaleNotifier.minScale,
                          max: TextScaleNotifier.maxScale,
                          divisions: 6,
                          label: '${(textScale * 100).round()}%',
                          onChanged: (value) {
                            ref.read(textScaleProvider.notifier).setScale(value);
                          },
                        ),
                      ),
                      const Icon(Icons.text_fields, size: 28),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Beverages visibility
                  Text(
                    l10n.display,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(hideBeverages ? l10n.showBeverages : l10n.hideBeverages),
                    subtitle: Text(l10n.beveragesInOrders),
                    value: !hideBeverages,
                    onChanged: (value) {
                      ref.read(hideKitchenBeveragesProvider.notifier).set(!value);
                    },
                  ),
                  const SizedBox(height: 20),
                  // Theme section
                  Text(
                    l10n.theme,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode, size: 18),
                        label: Text(l10n.lightTheme),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode, size: 18),
                        label: Text(l10n.darkTheme),
                      ),
                    ],
                    selected: {currentTheme == ThemeMode.system 
                        ? (MediaQuery.of(context).platformBrightness == Brightness.dark 
                            ? ThemeMode.dark 
                            : ThemeMode.light)
                        : currentTheme},
                    onSelectionChanged: (modes) {
                      ref.read(themeProvider.notifier).setTheme(modes.first);
                    },
                  ),
                  const SizedBox(height: 20),
                  // Language section
                  Text(
                    l10n.languageLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...AppLanguage.values.map((lang) {
                    final isSelected = currentLang == lang;
                    final label = switch (lang) {
                      AppLanguage.italian => '🇮🇹 Italiano',
                      AppLanguage.english => '🇬🇧 English',
                      AppLanguage.chinese => '🇨🇳 中文',
                    };
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(label),
                      trailing: isSelected 
                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) 
                          : null,
                      onTap: () {
                        ref.read(languageProvider.notifier).setLanguage(lang);
                      },
                    );
                  }),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800;
    final hideBeverages = ref.watch(hideKitchenBeveragesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.restaurant, size: 28),
            const SizedBox(width: 12),
            Text(
              l10n.kitchen,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // Ingredients button
          IconButton(
            icon: const Icon(Icons.inventory_2, size: 28),
            tooltip: l10n.inventory,
            onPressed: () => _showIngredientsSheet(context),
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings, size: 28),
            tooltip: l10n.settings,
            onPressed: () => _showSettingsDialog(context, ref, l10n),
          ),
          // Exit button
          IconButton(
            icon: const Icon(Icons.exit_to_app, size: 28),
            tooltip: l10n.exit,
            onPressed: () => context.go('/role'),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (orders) {
          final newOrders =
              orders.where((o) => o.status == OrderStatus.pending).toList();
          final preparingOrders =
              orders.where((o) => o.status == OrderStatus.preparing).toList();
          final readyOrders =
              orders.where((o) => o.status == OrderStatus.ready).toList();

          // Use tabs on small screens, columns on large screens
          if (isSmallScreen) {
            return _KitchenTabs(
              newOrders: newOrders,
              preparingOrders: preparingOrders,
              readyOrders: readyOrders,
              l10n: l10n,
              ref: ref,
              hideBeverages: hideBeverages,
            );
          }

          return Row(
            children: [
              // Colonna 1: Nuovi ordini
              Expanded(
                child: _OrderColumn(
                  title: l10n.newOrders,
                  orders: newOrders,
                  color: Colors.orange,
                  emptyMessage: l10n.noNewOrders,
                  actionLabel: l10n.startPreparing,
                  onAction: (order) => ref
                      .read(ordersProvider.notifier)
                      .updateStatus(order.id, OrderStatus.preparing),
                  onDismissChanges: (orderId) => ref
                      .read(ordersProvider.notifier)
                      .clearChanges(orderId),
                  l10n: l10n,
                  hideBeverages: hideBeverages,
                ),
              ),
              const VerticalDivider(width: 1),
              // Colonna 2: In preparazione
              Expanded(
                child: _OrderColumn(
                  title: l10n.inPreparation,
                  orders: preparingOrders,
                  color: Colors.blue,
                  emptyMessage: l10n.noPreparing,
                  actionLabel: l10n.markReady,
                  onAction: (order) => ref
                      .read(ordersProvider.notifier)
                      .updateStatus(order.id, OrderStatus.ready),
                  onDismissChanges: (orderId) => ref
                      .read(ordersProvider.notifier)
                      .clearChanges(orderId),
                  l10n: l10n,
                  hideBeverages: hideBeverages,
                ),
              ),
              const VerticalDivider(width: 1),
              // Colonna 3: Pronti
              Expanded(
                child: _OrderColumn(
                  title: l10n.readyToServe,
                  orders: readyOrders,
                  color: Colors.green,
                  emptyMessage: l10n.noReady,
                  actionLabel: l10n.served,
                  onAction: (order) => ref
                      .read(ordersProvider.notifier)
                      .updateStatus(order.id, OrderStatus.served),
                  onDismissChanges: (orderId) => ref
                      .read(ordersProvider.notifier)
                      .clearChanges(orderId),
                  l10n: l10n,
                  hideBeverages: hideBeverages,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Tabbed view for small screens (mobile)
class _KitchenTabs extends StatelessWidget {
  final List<OrderModel> newOrders;
  final List<OrderModel> preparingOrders;
  final List<OrderModel> readyOrders;
  final AppLocalizations l10n;
  final WidgetRef ref;
  final bool hideBeverages;

  const _KitchenTabs({
    required this.newOrders,
    required this.preparingOrders,
    required this.readyOrders,
    required this.l10n,
    required this.ref,
    required this.hideBeverages,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fiber_new, size: 20),
                    if (newOrders.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _Badge(count: newOrders.length, color: Colors.orange),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.soup_kitchen, size: 20),
                    if (preparingOrders.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _Badge(count: preparingOrders.length, color: Colors.blue),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 20),
                    if (readyOrders.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _Badge(count: readyOrders.length, color: Colors.green),
                    ],
                  ],
                ),
              ),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OrderColumn(
                  title: l10n.newOrders,
                  orders: newOrders,
                  color: Colors.orange,
                  emptyMessage: l10n.noNewOrders,
                  actionLabel: l10n.startPreparing,
                  onAction: (order) => ref
                      .read(ordersProvider.notifier)
                      .updateStatus(order.id, OrderStatus.preparing),
                  onDismissChanges: (orderId) => ref
                      .read(ordersProvider.notifier)
                      .clearChanges(orderId),
                  l10n: l10n,
                  showHeader: false,
                  hideBeverages: hideBeverages,
                ),
                _OrderColumn(
                  title: l10n.inPreparation,
                  orders: preparingOrders,
                  color: Colors.blue,
                  emptyMessage: l10n.noPreparing,
                  actionLabel: l10n.markReady,
                  onAction: (order) => ref
                      .read(ordersProvider.notifier)
                      .updateStatus(order.id, OrderStatus.ready),
                  onDismissChanges: (orderId) => ref
                      .read(ordersProvider.notifier)
                      .clearChanges(orderId),
                  l10n: l10n,
                  showHeader: false,
                  hideBeverages: hideBeverages,
                ),
                _OrderColumn(
                  title: l10n.readyToServe,
                  orders: readyOrders,
                  color: Colors.green,
                  emptyMessage: l10n.noReady,
                  actionLabel: l10n.served,
                  onAction: (order) => ref
                      .read(ordersProvider.notifier)
                      .updateStatus(order.id, OrderStatus.served),
                  onDismissChanges: (orderId) => ref
                      .read(ordersProvider.notifier)
                      .clearChanges(orderId),
                  l10n: l10n,
                  showHeader: false,
                  hideBeverages: hideBeverages,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;

  const _Badge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _OrderColumn extends StatelessWidget {
  final String title;
  final List<OrderModel> orders;
  final Color color;
  final String emptyMessage;
  final String actionLabel;
  final void Function(OrderModel) onAction;
  final void Function(String orderId)? onDismissChanges;
  final AppLocalizations l10n;
  final bool showHeader;
  final bool hideBeverages;

  const _OrderColumn({
    required this.title,
    required this.orders,
    required this.color,
    required this.emptyMessage,
    required this.actionLabel,
    required this.onAction,
    required this.l10n,
    this.onDismissChanges,
    this.showHeader = true,
    this.hideBeverages = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.05),
      child: Column(
        children: [
          // Header (optional)
          if (showHeader)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: color.withOpacity(0.2),
              child: Column(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${orders.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Orders list
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text(
                      emptyMessage,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _KitchenOrderCard(
                        order: order,
                        color: color,
                        actionLabel: actionLabel,
                        onAction: () => onAction(order),
                        l10n: l10n,
                        onDismissChanges: onDismissChanges,
                        hideBeverages: hideBeverages,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _KitchenOrderCard extends StatelessWidget {
  final OrderModel order;
  final Color color;
  final String actionLabel;
  final VoidCallback onAction;
  final void Function(String orderId)? onDismissChanges;
  final AppLocalizations l10n;
  final bool hideBeverages;

  const _KitchenOrderCard({
    required this.order,
    required this.color,
    required this.actionLabel,
    required this.onAction,
    required this.l10n,
    this.onDismissChanges,
    this.hideBeverages = true,
  });

  String _getTimeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return l10n.justNow;
    return l10n.minutesAgo(diff.inMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = DateTime.now().difference(order.createdAt).inMinutes > 15;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Colori per asporto adattati al tema
    final takeawayBgColor = isDark 
        ? const Color(0xFF3D2E1F) // marrone scuro per dark mode
        : Colors.orange.shade50;
    final takeawayBorderColor = isDark
        ? Colors.orange.shade700
        : Colors.orange.shade300;
    final takeawayIconColor = isDark
        ? Colors.orange.shade300
        : Colors.orange.shade700;
    final takeawayTextColor = isDark
        ? Colors.orange.shade200
        : Colors.orange.shade800;
    
    // Crea mappa delle modifiche per menuItemId per lookup veloce
    final changesMap = <String, int>{};
    if (order.changes != null) {
      for (final change in order.changes!) {
        // Cerca il menuItemId corrispondente negli items
        for (final item in order.items) {
          if (item.name == change.name || item.nameZh == change.nameZh) {
            changesMap[item.menuItemId] = (changesMap[item.menuItemId] ?? 0) + change.quantity;
          }
        }
      }
    }
    
    // Modifiche per piatti rimossi (non più in items)
    final removedChanges = order.changes?.where((c) => 
      c.isRemoval && !order.items.any((i) => i.name == c.name || i.nameZh == c.nameZh)
    ).toList() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 3,
      color: order.isTakeaway ? takeawayBgColor : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUrgent
            ? const BorderSide(color: Colors.red, width: 3)
            : order.isTakeaway
                ? BorderSide(color: takeawayBorderColor, width: 2)
                : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order type + time + modified badge + dismiss button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Icona per tipo ordine
                      Icon(
                        order.isTakeaway
                            ? Icons.takeout_dining
                            : Icons.table_restaurant,
                        size: 28,
                        color: order.isTakeaway ? takeawayIconColor : color,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          order.isTakeaway
                              ? order.takeawayNumber ?? l10n.takeaway
                              : order.tableName ?? order.tableId ?? "?",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: order.isTakeaway ? takeawayTextColor : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Modified badge with dismiss
                      if (order.isModified && order.changes != null && order.changes!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onDismissChanges != null ? () => onDismissChanges!(order.id) : null,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, color: Colors.white, size: 12),
                                SizedBox(width: 2),
                                Icon(Icons.check, color: Colors.white, size: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUrgent ? Colors.red : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTimeAgo(order.createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isUrgent ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            // Separa piatti da bevande - in cucina prima i piatti da preparare
            ..._buildFoodItems(order, changesMap, color, l10n),
            // Bevande in fondo (meno priorità per la cucina) - solo se non nascoste
            if (!hideBeverages)
              ..._buildBeverageItems(order, changesMap, l10n),
            // Removed items (piatti completamente rimossi)
            ...removedChanges.map((change) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Opacity(
                opacity: 0.6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Badge rosso con X
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${change.quantity.abs()}x ${change.nameZh ?? change.name}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
                          decoration: TextDecoration.lineThrough,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
            // Order notes
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final bgColor = isDark 
                      ? const Color(0xFF5D4037) // marrone desaturato per dark
                      : Colors.deepOrange;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_rounded, 
                          color: isDark ? Colors.orange.shade200 : Colors.white, 
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            order.notes!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.orange.shade100 : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            // Action button - big and easy to tap
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  onAction();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Costruisce la lista dei piatti (non bevande) per la cucina
  List<Widget> _buildFoodItems(OrderModel order, Map<String, int> changesMap, Color color, AppLocalizations l10n) {
    final foodItems = order.items.where((item) => !item.isBeverage).toList();
    if (foodItems.isEmpty) return [];
    
    return foodItems.map((item) => _buildKitchenItem(order, item, changesMap, color, l10n)).toList();
  }

  /// Costruisce la lista delle bevande per la cucina (in fondo, compatte)
  List<Widget> _buildBeverageItems(OrderModel order, Map<String, int> changesMap, AppLocalizations l10n) {
    final beverageItems = order.items.where((item) => item.isBeverage).toList();
    if (beverageItems.isEmpty) return [];
    
    return [
      const SizedBox(height: 8),
      Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.blue.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_bar, 
                  size: 16, 
                  color: isDark ? Colors.grey.shade500 : Colors.blue.shade700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: beverageItems.map((item) {
                      final changeQty = changesMap[item.menuItemId];
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${item.quantity}x ${item.name}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey.shade400 : Colors.blue.shade900,
                            ),
                          ),
                          if (changeQty != null && changeQty != 0) ...[
                            const SizedBox(width: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: changeQty > 0 ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                changeQty > 0 ? '+$changeQty' : '$changeQty',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ];
  }

  /// Costruisce un singolo item per la cucina
  Widget _buildKitchenItem(OrderModel order, OrderItem item, Map<String, int> changesMap, Color color, AppLocalizations l10n) {
    final servedQty = order.getServedQuantity(item.menuItemId);
    final isFullyServed = servedQty >= item.quantity;
    final hasPartialServed = servedQty > 0 && servedQty < item.quantity;
    final remaining = item.quantity - servedQty;
    final changeQty = changesMap[item.menuItemId];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Opacity(
        opacity: isFullyServed ? 0.5 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quantity badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isFullyServed 
                    ? Colors.grey 
                    : hasPartialServed 
                        ? Colors.orange 
                        : color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: isFullyServed
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                        hasPartialServed ? '${remaining}x' : '${item.quantity}x',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.nameZh != null) ...[
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.nameZh!,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              decoration: isFullyServed ? TextDecoration.lineThrough : null,
                              decorationThickness: 2,
                            ),
                          ),
                        ),
                        if (changeQty != null && changeQty != 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: changeQty > 0 ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              changeQty > 0 ? '+$changeQty' : '$changeQty',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            decoration: isFullyServed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (hasPartialServed) ...[
                          const SizedBox(width: 6),
                          Text(
                            l10n.servedCountShort(servedQty, item.quantity),
                            style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              decoration: isFullyServed ? TextDecoration.lineThrough : null,
                              decorationThickness: 2,
                            ),
                          ),
                        ),
                        if (changeQty != null && changeQty != 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: changeQty > 0 ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              changeQty > 0 ? '+$changeQty' : '$changeQty',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (hasPartialServed)
                      Text(
                        l10n.servedCountShort(servedQty, item.quantity),
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                      ),
                  ],
                  if (item.notes != null && item.notes!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '⚠️ ${item.notes}',
                        style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }
}
