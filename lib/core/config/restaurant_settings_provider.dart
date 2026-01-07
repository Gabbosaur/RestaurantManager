import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/supabase_service.dart';

/// Provider for restaurant settings like cover charge
final restaurantSettingsProvider =
    AsyncNotifierProvider<RestaurantSettingsNotifier, RestaurantSettings>(
        RestaurantSettingsNotifier.new);

class RestaurantSettings {
  final double coverCharge;

  const RestaurantSettings({this.coverCharge = 1.50});

  factory RestaurantSettings.fromJson(Map<String, dynamic> json) {
    return RestaurantSettings(
      coverCharge: (json['cover_charge'] as num?)?.toDouble() ?? 1.50,
    );
  }

  Map<String, dynamic> toJson() => {'cover_charge': coverCharge};

  RestaurantSettings copyWith({double? coverCharge}) {
    return RestaurantSettings(coverCharge: coverCharge ?? this.coverCharge);
  }
}

class RestaurantSettingsNotifier extends AsyncNotifier<RestaurantSettings> {
  @override
  Future<RestaurantSettings> build() async {
    return _fetchSettings();
  }

  Future<RestaurantSettings> _fetchSettings() async {
    try {
      final response = await SupabaseService.client
          .from('restaurant_settings')
          .select()
          .single();
      return RestaurantSettings.fromJson(response);
    } catch (e) {
      // Return default if table doesn't exist or no data
      return const RestaurantSettings();
    }
  }

  Future<void> updateCoverCharge(double price) async {
    try {
      await SupabaseService.client.from('restaurant_settings').upsert({
        'id': 1,
        'cover_charge': price,
      });
      ref.invalidateSelf();
    } catch (e) {
      // If table doesn't exist, just update local state
      state = AsyncData(RestaurantSettings(coverCharge: price));
    }
  }
}
