import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider per la dimensione del testo (scala da 0.8 a 1.4)
final textScaleProvider = StateNotifierProvider<TextScaleNotifier, double>((ref) {
  return TextScaleNotifier();
});

class TextScaleNotifier extends StateNotifier<double> {
  static const _key = 'text_scale';
  static const double minScale = 0.9;
  static const double maxScale = 1.5;
  static const double defaultScale = 1.0;

  TextScaleNotifier() : super(defaultScale) {
    _loadScale();
  }

  Future<void> _loadScale() async {
    final prefs = await SharedPreferences.getInstance();
    final scale = prefs.getDouble(_key) ?? defaultScale;
    state = scale.clamp(minScale, maxScale);
  }

  Future<void> setScale(double scale) async {
    final clampedScale = scale.clamp(minScale, maxScale);
    state = clampedScale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, clampedScale);
  }

  void increase() {
    setScale(state + 0.1);
  }

  void decrease() {
    setScale(state - 0.1);
  }
}
