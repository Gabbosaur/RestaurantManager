import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider per lo stato della connessione
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});

enum ConnectivityState {
  online,
  offline,
  syncing,
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  ConnectivityNotifier() : super(ConnectivityState.online) {
    _init();
  }

  final _connectivity = Connectivity();
  StreamSubscription? _subscription;

  void _init() {
    // Su web, connectivity_plus non funziona - verifica direttamente Supabase
    if (kIsWeb) {
      _verifySupabaseConnection();
      return;
    }
    
    // Check initial state
    _checkConnectivity();
    
    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });
  }

  Future<void> _checkConnectivity() async {
    // Su web, verifica solo Supabase
    if (kIsWeb) {
      await _verifySupabaseConnection();
      return;
    }
    
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      // Fallback: verifica direttamente Supabase
      await _verifySupabaseConnection();
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) => 
      r == ConnectivityResult.wifi || 
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.ethernet
    );
    
    if (hasConnection) {
      // Verifica anche che Supabase sia raggiungibile
      _verifySupabaseConnection();
    } else {
      state = ConnectivityState.offline;
    }
  }

  Future<void> _verifySupabaseConnection() async {
    try {
      // Prova una query leggera per verificare la connessione
      await Supabase.instance.client
          .from('menu_items')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      
      state = ConnectivityState.online;
    } catch (e) {
      state = ConnectivityState.offline;
    }
  }

  void setSyncing() {
    state = ConnectivityState.syncing;
  }

  void setOnline() {
    state = ConnectivityState.online;
  }

  void setOffline() {
    state = ConnectivityState.offline;
  }

  /// Forza un check della connessione
  Future<void> checkNow() async {
    await _checkConnectivity();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
