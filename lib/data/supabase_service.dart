
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/recipe.dart';

/// Menghubungkan MealMate ke Supabase Data API dan Anonymous Auth.
class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  SupabaseClient? _client;

  bool get isConfigured => _client != null;

  Future<void> initialize() async {
    if (_client != null) return;

    await Supabase.initialize(
      url: SupabaseConfig.projectUrl,
      publishableKey: SupabaseConfig.publishableKey,
    );

    _client = Supabase.instance.client;

    debugPrint('Supabase MealMate berhasil diinisialisasi.');
  }

  /// Mengambil resep aktif dari tabel public.recipes.
  Future<List<Recipe>> loadRecipes() async {
    final client = _client;
    if (client == null) return const [];

    final rows = await client
        .from('recipes')
        .select(
          'id,name,description,minutes,cost_per_serving,icon,image_url,'
          'calories_kcal_per_serving,protein_g_per_serving,'
          'carbohydrates_g_per_serving,fat_g_per_serving,'
          'ingredients,steps,sort_order,servings,cost_estimate_confidence,'
          'cost_estimate_basis',
        )
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('name', ascending: true);

    return rows
        .map((row) => Recipe.fromJson(Map<String, dynamic>.from(row)))
        .where((recipe) => recipe.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _ensureSignedIn(SupabaseClient client) async {
    if (client.auth.currentUser != null) return;

    await client.auth.signInAnonymously();

    final user = client.auth.currentUser;

    if (user == null) {
      throw StateError(
        'Supabase Anonymous Auth tidak menghasilkan user.',
      );
    }

    debugPrint('Supabase Anonymous Auth berhasil: ${user.id}');
  }

  /// Membaca state MealMate milik pengguna/perangkat ini.
  Future<Map<String, dynamic>?> loadState() async {
    final client = _client;
    if (client == null) return null;

    await _ensureSignedIn(client);

    final userId = client.auth.currentUser!.id;

    final row = await client
        .from('user_meal_mate_state')
        .select('state')
        .eq('user_id', userId)
        .maybeSingle();

    final state = row?['state'];

    return state is Map
        ? Map<String, dynamic>.from(state)
        : null;
  }

  /// Menyimpan state MealMate milik pengguna/perangkat ini.
  Future<void> saveState(Map<String, dynamic> state) async {
    final client = _client;
    if (client == null) return;

    await _ensureSignedIn(client);

    final userId = client.auth.currentUser!.id;

    await client.from('user_meal_mate_state').upsert({
      'user_id': userId,
      'state': state,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    debugPrint('Data MealMate berhasil disimpan ke Supabase.');
  }
}
