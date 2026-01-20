import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/supabase_service.dart';
import '../../data/models/ingredient_model.dart';

final ingredientsProvider =
    AsyncNotifierProvider<IngredientsNotifier, List<IngredientModel>>(
        IngredientsNotifier.new);

class IngredientsNotifier extends AsyncNotifier<List<IngredientModel>> {
  RealtimeChannel? _subscription;

  @override
  Future<List<IngredientModel>> build() async {
    // Mantieni il provider sempre attivo per ricevere aggiornamenti realtime
    ref.keepAlive();
    
    // Chiudi subscription precedente se esiste
    _subscription?.unsubscribe();
    
    // Subscribe to real-time updates
    _subscription = SupabaseService.subscribeToIngredients((payload) {
      // Forza il refresh dei dati
      ref.invalidateSelf();
    });

    // Cleanup quando il provider viene distrutto
    ref.onDispose(() {
      _subscription?.unsubscribe();
    });

    return _fetchIngredients();
  }

  Future<List<IngredientModel>> _fetchIngredients() async {
    final response = await SupabaseService.client
        .from('ingredients')
        .select()
        .order('name');

    return (response as List).map((e) => IngredientModel.fromJson(e)).toList();
  }

  Future<void> toggleAvailability(String id, bool isAvailable) async {
    await SupabaseService.client
        .from('ingredients')
        .update({'is_available': isAvailable}).eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> setAllAvailable() async {
    // Supabase richiede un filtro per update, usiamo neq con valore impossibile
    await SupabaseService.client
        .from('ingredients')
        .update({'is_available': true})
        .neq('id', '');
    ref.invalidateSelf();
  }
}
