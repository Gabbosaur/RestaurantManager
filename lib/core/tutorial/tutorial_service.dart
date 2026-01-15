import 'package:shared_preferences/shared_preferences.dart';

/// Servizio per gestire lo stato dei tutorial
class TutorialService {
  static const String _keyPrefix = 'tutorial_seen_';
  
  static Future<bool> hasSeenTutorial(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyPrefix$tutorialId') ?? false;
  }
  
  static Future<void> markTutorialAsSeen(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix$tutorialId', true);
  }
  
  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
  
  // Tutorial IDs
  static const String salaOrders = 'sala_orders';
  static const String salaTables = 'sala_tables';
  static const String salaMenu = 'sala_menu';
  static const String kitchen = 'kitchen';
}
