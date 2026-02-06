import 'package:flutter/material.dart';

/// Controller globale per chiudere bottom sheet da qualsiasi punto dell'app
class BottomSheetController {
  static final BottomSheetController _instance = BottomSheetController._();
  static BottomSheetController get instance => _instance;
  
  BottomSheetController._();
  
  BuildContext? _activeSheetContext;
  
  /// Registra il context del bottom sheet attivo
  void register(BuildContext context) {
    _activeSheetContext = context;
  }
  
  /// Rimuove la registrazione
  void unregister() {
    _activeSheetContext = null;
  }
  
  /// Chiude il bottom sheet attivo se presente
  void close() {
    if (_activeSheetContext != null && _activeSheetContext!.mounted) {
      Navigator.of(_activeSheetContext!).pop();
      _activeSheetContext = null;
    }
  }
  
  /// Verifica se c'è un bottom sheet attivo
  bool get hasActiveSheet => _activeSheetContext != null;
}
