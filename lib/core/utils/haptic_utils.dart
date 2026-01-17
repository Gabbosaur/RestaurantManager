import 'package:flutter/services.dart';

/// Utility per feedback haptico
class HapticUtils {
  /// Feedback leggero per tap normali
  static void lightTap() {
    HapticFeedback.lightImpact();
  }

  /// Feedback medio per azioni importanti (aggiungi piatto, conferma)
  static void mediumTap() {
    HapticFeedback.mediumImpact();
  }

  /// Feedback forte per azioni critiche (crea ordine, paga, cancella)
  static void heavyTap() {
    HapticFeedback.heavyImpact();
  }

  /// Feedback di selezione (cambio tab, selezione)
  static void selectionTap() {
    HapticFeedback.selectionClick();
  }

  /// Vibrazione per errori o warning
  static void vibrate() {
    HapticFeedback.vibrate();
  }
}
