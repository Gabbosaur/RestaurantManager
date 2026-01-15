import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/supabase_service.dart';
import '../../data/models/ingredient_model.dart';

final ingredientsProvider =
    AsyncNotifierProvider<IngredientsNotifier, List<IngredientModel>>(
        IngredientsNotifier.new);

class IngredientsNotifier extends AsyncNotifier<List<IngredientModel>> {
  @override
  Future<List<IngredientModel>> build() async {
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
