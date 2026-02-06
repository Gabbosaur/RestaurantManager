import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider per nascondere i piatti già serviti nella lista ordini
final hideServedItemsProvider = StateNotifierProvider<HideServedItemsNotifier, bool>((ref) {
  return HideServedItemsNotifier();
});

class HideServedItemsNotifier extends StateNotifier<bool> {
  static const _key = 'hide_served_items';

  HideServedItemsNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

/// Provider per nascondere le bevande in cucina (default: true = nascoste)
final hideKitchenBeveragesProvider = StateNotifierProvider<HideKitchenBeveragesNotifier, bool>((ref) {
  return HideKitchenBeveragesNotifier();
});

class HideKitchenBeveragesNotifier extends StateNotifier<bool> {
  static const _key = 'hide_kitchen_beverages';

  HideKitchenBeveragesNotifier() : super(true) { // Default: nascoste
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true; // Default: nascoste
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
