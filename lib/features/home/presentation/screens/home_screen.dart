import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../services/supabase_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final _routes = ['/', '/tables', '/menu', '/inventory'];

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);

    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.receipt_long_outlined),
        selectedIcon: const Icon(Icons.receipt_long),
        label: l10n.orders,
      ),
      NavigationDestination(
        icon: const Icon(Icons.table_restaurant_outlined),
        selectedIcon: const Icon(Icons.table_restaurant),
        label: l10n.tables,
      ),
      NavigationDestination(
        icon: const Icon(Icons.restaurant_menu_outlined),
        selectedIcon: const Icon(Icons.restaurant_menu),
        label: l10n.menu,
      ),
      NavigationDestination(
        icon: const Icon(Icons.inventory_2_outlined),
        selectedIcon: const Icon(Icons.inventory_2),
        label: l10n.inventory,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xin Xing 新星'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: l10n.languageLabel,
            onPressed: () => _showLanguageDialog(context, ref, l10n),
          ),
          // Exit to role selection
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: l10n.exit,
            onPressed: () => context.go('/role'),
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: destinations,
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.languageLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((lang) {
            final isSelected = ref.read(languageProvider) == lang;
            final label = switch (lang) {
              AppLanguage.italian => '🇮🇹 Italiano',
              AppLanguage.english => '🇬🇧 English',
              AppLanguage.chinese => '🇨🇳 中文',
            };
            return ListTile(
              title: Text(label),
              trailing: isSelected ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(languageProvider.notifier).setLanguage(lang);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
