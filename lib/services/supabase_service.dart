import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;

  // Auth
  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Real-time subscriptions
  static RealtimeChannel subscribeToOrders(void Function(dynamic) callback) {
    return client
        .channel('orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) => callback(payload),
        )
        .subscribe();
  }

  static RealtimeChannel subscribeToInventory(void Function(dynamic) callback) {
    return client
        .channel('inventory')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'inventory_items',
          callback: (payload) => callback(payload),
        )
        .subscribe();
  }

  static RealtimeChannel subscribeToIngredients(void Function(dynamic) callback) {
    return client
        .channel('ingredients')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ingredients',
          callback: (payload) => callback(payload),
        )
        .subscribe();
  }
}
