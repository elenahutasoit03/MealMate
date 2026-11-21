import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recipe.dart';
import '../models/meal_plan_record.dart';
import '../utils/ingredient_quantity.dart';
import 'supabase_service.dart';

class MealMateData extends ChangeNotifier {
  int _weeklyBudget = 0;
  bool _hasConfiguredWeeklyBudget = false;
  int people = 2;
  String name = '';
  String target = 'Hemat';

  final List<String> ingredients = [];
  final Set<String> availableIngredients = {};

  /// Semua bahan yang tampil di halaman Daftar Belanja.
  /// Gabungan bahan manual dan bahan dari Meal Plan.
  final Set<String> shoppingItems = {};

  /// Bahan yang ditambahkan pengguna secara manual,
  /// termasuk data lama yang belum memiliki penanda sumber.
  final Set<String> manualShoppingItems = {};

  /// Bahan yang dihasilkan otomatis dari Meal Plan aktif.
  final Set<String> autoShoppingItems = {};

  /// Bahan otomatis yang sengaja dihapus pengguna.
  /// Item tetap disembunyikan selama masih diperlukan
  /// oleh Meal Plan yang sama.
  final Set<String> excludedAutoShoppingItems = {};

  final Set<String> checkedShoppingItems = {};
  final Map<String, int> shoppingPrices = {};
  final Map<String, String> shoppingAmounts = {};
  final List<MealPlanRecord> history = [];

  List<Recipe>? _weeklyMenu;
  List<Recipe> _recipeCatalog = [];

  static const String _recipeCatalogCacheKey = 'recipeCatalogCache';

  bool planSaved = false;
  SharedPreferences? _preferences;
  Future<void> _saveQueue = Future<void>.value();
  bool _disposed = false;

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    final preferences = _preferences!;

    // Cache hanya berisi resep yang sebelumnya berhasil diterima
    // dari Supabase, bukan data contoh yang ditanam di aplikasi.
    final cachedRecipes = _readCachedRecipeCatalog(
      preferences.getString(_recipeCatalogCacheKey),
    );

    if (cachedRecipes.length >= 7) {
      _recipeCatalog = List<Recipe>.unmodifiable(cachedRecipes);
    }

    final storedBudget = preferences.getInt('weeklyBudget');
    _weeklyBudget = storedBudget ?? 0;
    _hasConfiguredWeeklyBudget =
        preferences.getBool('weeklyBudgetConfigured') == true &&
            storedBudget != null &&
            storedBudget >= 50000 &&
            storedBudget <= 5000000;
    people = preferences.getInt('people') ?? people;
    name = preferences.getString('name') ?? name;
    target = preferences.getString('target') ?? target;
    planSaved = preferences.getBool('planSaved') ?? false;

    final storedIngredients = preferences.getStringList('ingredients');
    final storedAvailableIngredients =
        preferences.getStringList('availableIngredients');

    final hasLegacySamplePantry = listEquals(storedIngredients, const [
          'Beras',
          'Telur',
          'Ayam',
          'Bawang putih',
          'Wortel',
          'Bawang bombai',
        ]) &&
        setEquals(
          storedAvailableIngredients?.toSet() ?? <String>{},
          const {'Beras', 'Telur', 'Bawang putih'},
        );

    // Migrasi daftar pantry contoh dari versi awal menjadi kosong.
    // Data yang benar-benar diubah pengguna tidak disentuh.
    final initialPantry = hasLegacySamplePantry
        ? const <String>[]
        : (storedIngredients ?? const <String>[]);

    final initialAvailable = hasLegacySamplePantry
        ? const <String>[]
        : (storedAvailableIngredients ?? const <String>[]);

    ingredients
      ..clear()
      ..addAll(initialPantry);

    availableIngredients
      ..clear()
      ..addAll(initialAvailable);

    if (hasLegacySamplePantry) {
      await preferences.setStringList('ingredients', const []);
      await preferences.setStringList('availableIngredients', const []);
    }

    final storedShoppingItems =
        preferences.getStringList('shoppingItems') ?? const <String>[];

    shoppingItems
      ..clear()
      ..addAll(storedShoppingItems);

    // Migrasi aman untuk state versi lama:
    // semua item yang sudah ada dipertahankan sebagai item manual/legacy.
    manualShoppingItems
      ..clear()
      ..addAll(
        preferences.getStringList('manualShoppingItems') ?? storedShoppingItems,
      );

    autoShoppingItems
      ..clear()
      ..addAll(
        preferences.getStringList('autoShoppingItems') ?? const <String>[],
      );

    excludedAutoShoppingItems
      ..clear()
      ..addAll(
        preferences.getStringList('excludedAutoShoppingItems') ??
            const <String>[],
      );

    checkedShoppingItems
      ..clear()
      ..addAll(
        preferences.getStringList('checkedShoppingItems') ?? const [],
      );

    final prices = preferences.getString('shoppingPrices');

    if (prices != null) {
      try {
        final decoded = jsonDecode(prices) as Map<String, dynamic>;

        shoppingPrices
          ..clear()
          ..addAll(
            decoded.map(
              (key, value) => MapEntry(key, _toInt(value, 0)),
            ),
          );
      } catch (error) {
        debugPrint('Gagal membaca harga lokal MealMate: $error');
        shoppingPrices.clear();
      }
    }

    final amounts = preferences.getString('shoppingAmounts');
    if (amounts != null) {
      try {
        final decoded = jsonDecode(amounts);
        if (decoded is Map) {
          shoppingAmounts
            ..clear()
            ..addAll(
              decoded.map(
                (key, value) => MapEntry(
                  key.toString(),
                  value.toString(),
                ),
              ),
            );
        }
      } catch (error) {
        debugPrint('Gagal membaca jumlah bahan lokal MealMate: $error');
        shoppingAmounts.clear();
      }
    }

    final storedMenu = preferences.getStringList('weeklyMenu');
    final storedHistory = preferences.getString('mealHistory');

    if (storedHistory != null) {
      try {
        final decoded = jsonDecode(storedHistory) as List<dynamic>;

        history
          ..clear()
          ..addAll(
            decoded.map(
              (item) => MealPlanRecord.fromJson(
                item as Map<String, dynamic>,
              ),
            ),
          );
      } catch (error) {
        debugPrint('Gagal membaca riwayat lokal MealMate: $error');
        history.clear();
      }
    }

    // Migrasi state versi lama. Versi sebelumnya otomatis menyimpan
    // Rp350.000 sebagai nilai bawaan, meskipun pengguna belum mengisinya.
    // Nilai berbeda dari default atau yang sudah dipakai pada Meal Plan
    // lama dipertahankan agar pengaturan pengguna tidak hilang.
    if (preferences.getBool('weeklyBudgetConfigured') == null) {
      final legacyBudgetWasUsed = storedBudget != null &&
          storedBudget >= 50000 &&
          storedBudget <= 5000000 &&
          (storedBudget != 350000 || planSaved || history.isNotEmpty);

      _hasConfiguredWeeklyBudget = legacyBudgetWasUsed;
      if (!_hasConfiguredWeeklyBudget) {
        _weeklyBudget = 0;
      }

      await preferences.setBool(
        'weeklyBudgetConfigured',
        _hasConfiguredWeeklyBudget,
      );
      await preferences.setInt('weeklyBudget', _weeklyBudget);
    } else if (!_hasConfiguredWeeklyBudget) {
      _weeklyBudget = 0;
    }

    // Jika cache resep tersedia, aplikasi dapat dibuka dari cache
    // sambil memperbarui katalog dari Supabase di latar belakang.
    if (_recipeCatalog.length >= 7) {
      // Cache asli tetap bisa digunakan saat offline.
      // Refresh hanya dilakukan jika Supabase sudah siap.
      if (SupabaseService.instance.isConfigured) {
        unawaited(_refreshRecipeCatalog());
      }
    } else {
      // Tanpa cache dan tanpa Supabase, aplikasi tetap gagal
      // memuat katalog. Jangan gunakan resep dummy.
      await _refreshRecipeCatalog();
    }

    // Pulihkan pilihan menu lokal setelah katalog tersedia.
    if (storedMenu != null) {
      final restored = _recipesFromNames(storedMenu);

      if (restored.length == 7) {
        _weeklyMenu = restored;
      } else {
        _weeklyMenu = null;
        planSaved = false;

        await preferences.remove('weeklyMenu');
        await preferences.setBool('planSaved', false);
      }
    }

    if (_restoreWeeklyMenuFromLatestHistory()) {
      await _writeLocalState(_stateJson());
    } else if (planSaved && _weeklyMenu == null) {
      planSaved = false;
    }

    // Sinkronisasi state pengguna dari Supabase.
    try {
      final remoteState = await SupabaseService.instance
          .loadState()
          .timeout(const Duration(seconds: 10));

      if (remoteState != null) {
        final recoveredLegacyMenu = _applyState(remoteState);

        final normalizedState = _stateJson();

        await _writeLocalState(normalizedState);

        final remoteMenuIsValid = _isRestorableMenu(remoteState['weeklyMenu']);

        final normalizedMenuIsValid =
            _isRestorableMenu(normalizedState['weeklyMenu']);

        final hadInvalidUnsavedMenu = remoteState['weeklyMenu'] is List &&
            !remoteMenuIsValid &&
            remoteState['planSaved'] != true;

        final needsLegacyMenuBackfill = remoteState['planSaved'] == true &&
            !remoteMenuIsValid &&
            normalizedMenuIsValid;

        final needsInvalidSavedMenuReset = remoteState['planSaved'] == true &&
            normalizedState['planSaved'] != true;
        final needsBudgetMarkerMigration =
            remoteState['weeklyBudgetConfigured'] is! bool;

        if (recoveredLegacyMenu ||
            needsLegacyMenuBackfill ||
            hadInvalidUnsavedMenu ||
            needsInvalidSavedMenuReset ||
            needsBudgetMarkerMigration) {
          await SupabaseService.instance
              .saveState(normalizedState)
              .timeout(const Duration(seconds: 12));
        }
      } else if (SupabaseService.instance.isConfigured) {
        await SupabaseService.instance
            .saveState(_stateJson())
            .timeout(const Duration(seconds: 12));
      }
    } catch (error) {
      debugPrint('Gagal memuat data state Supabase: $error');
    }

    // Sinkronisasi Daftar Belanja dengan Meal Plan yang dipulihkan.
    final activeMenu = _weeklyMenu;

    if (activeMenu != null && activeMenu.length == 7) {
      if (_syncShoppingListWithMenu(activeMenu)) {
        _save();
      }
    }
  }

  List<Recipe> _readCachedRecipeCatalog(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => Recipe.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((recipe) => recipe.name.isNotEmpty)
          .toList(growable: false);
    } catch (error) {
      debugPrint('Cache katalog resep MealMate tidak dapat dibaca: $error');
      return const [];
    }
  }

  Future<void> _refreshRecipeCatalog() async {
    try {
      if (!SupabaseService.instance.isConfigured) {
        throw StateError('Supabase belum berhasil diinisialisasi.');
      }

      final cloudRecipes = await SupabaseService.instance
          .loadRecipes()
          .timeout(const Duration(seconds: 15));

      if (cloudRecipes.length < 7) {
        throw StateError(
          'Katalog Supabase tidak memuat jumlah resep minimum yang valid.',
        );
      }

      _recipeCatalog = List<Recipe>.unmodifiable(cloudRecipes);

      await _preferences?.setString(
        _recipeCatalogCacheKey,
        jsonEncode(
          cloudRecipes.map((recipe) => recipe.toJson()).toList(),
        ),
      );

      if (!_disposed) {
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Gagal memperbarui katalog resep dari Supabase: $error');

      if (_recipeCatalog.length < 7) {
        rethrow;
      }
    }
  }

  /// Menjadwalkan penyimpanan snapshot secara berurutan.
  void _save() {
    if (_preferences == null || _disposed) return;

    final snapshot =
        jsonDecode(jsonEncode(_stateJson())) as Map<String, dynamic>;

    _saveQueue = _saveQueue
        .catchError((Object error) {
          debugPrint('Antrean simpan sebelumnya gagal: $error');
        })
        .then((_) => _persist(snapshot))
        .catchError((Object error) {
          debugPrint('Gagal menyimpan data lokal MealMate: $error');
        });

    unawaited(_saveQueue);
  }

  Future<void> flush() async {
    await _saveQueue;
  }

  Future<void> _persist(Map<String, dynamic> snapshot) async {
    // Penyimpanan lokal selalu didahulukan.
    await _writeLocalState(snapshot);

    if (!SupabaseService.instance.isConfigured) return;

    try {
      await SupabaseService.instance
          .saveState(snapshot)
          .timeout(const Duration(seconds: 12));
    } catch (error) {
      debugPrint('Gagal menyimpan data Supabase: $error');
    }
  }

  Future<void> _writeLocalState(Map<String, dynamic> state) async {
    final preferences = _preferences;

    if (preferences == null) return;

    await preferences.setInt(
      'weeklyBudget',
      _toInt(state['weeklyBudget'], 0),
    );
    await preferences.setBool(
      'weeklyBudgetConfigured',
      state['weeklyBudgetConfigured'] == true,
    );

    await preferences.setInt(
      'people',
      _toInt(state['people'], 2),
    );

    await preferences.setString(
      'name',
      state['name']?.toString() ?? '',
    );

    await preferences.setString(
      'target',
      state['target']?.toString() ?? 'Hemat',
    );

    await preferences.setBool(
      'planSaved',
      state['planSaved'] == true,
    );

    await preferences.setStringList(
      'ingredients',
      _toStringList(state['ingredients'], const []),
    );

    await preferences.setStringList(
      'availableIngredients',
      _toStringList(state['availableIngredients'], const []),
    );

    await preferences.setStringList(
      'shoppingItems',
      _toStringList(state['shoppingItems'], const []),
    );

    await preferences.setStringList(
      'manualShoppingItems',
      _toStringList(
        state['manualShoppingItems'],
        _toStringList(state['shoppingItems'], const []),
      ),
    );

    await preferences.setStringList(
      'autoShoppingItems',
      _toStringList(state['autoShoppingItems'], const []),
    );

    await preferences.setStringList(
      'excludedAutoShoppingItems',
      _toStringList(state['excludedAutoShoppingItems'], const []),
    );

    await preferences.setStringList(
      'checkedShoppingItems',
      _toStringList(state['checkedShoppingItems'], const []),
    );

    final prices = state['shoppingPrices'];

    await preferences.setString(
      'shoppingPrices',
      jsonEncode(
        prices is Map ? prices : <String, int>{},
      ),
    );

    final amounts = state['shoppingAmounts'];
    await preferences.setString(
      'shoppingAmounts',
      jsonEncode(
        amounts is Map ? amounts : <String, String>{},
      ),
    );

    final weeklyMenu = state['weeklyMenu'];

    if (weeklyMenu is List && weeklyMenu.whereType<String>().isNotEmpty) {
      await preferences.setStringList(
        'weeklyMenu',
        weeklyMenu.whereType<String>().toList(),
      );
    } else {
      await preferences.remove('weeklyMenu');
    }

    final mealHistory = state['mealHistory'];

    await preferences.setString(
      'mealHistory',
      jsonEncode(mealHistory is List ? mealHistory : const []),
    );
  }

  Map<String, dynamic> _stateJson() => {
        'weeklyBudget': weeklyBudget,
        'weeklyBudgetConfigured': hasWeeklyBudget,
        'people': people,
        'name': name,
        'target': target,
        'planSaved': planSaved,
        'ingredients': ingredients,
        'availableIngredients': availableIngredients.toList(),
        'shoppingItems': shoppingItems.toList(),
        'manualShoppingItems': manualShoppingItems.toList(),
        'autoShoppingItems': autoShoppingItems.toList(),
        'excludedAutoShoppingItems': excludedAutoShoppingItems.toList(),
        'checkedShoppingItems': checkedShoppingItems.toList(),
        'shoppingPrices': shoppingPrices,
        'shoppingAmounts': shoppingAmounts,
        'weeklyMenu': _weeklyMenu?.map((recipe) => recipe.name).toList(),
        'mealHistory': history.map((record) => record.toJson()).toList(),
      };

  bool _applyState(Map<String, dynamic> state) {
    final remoteBudget = _toInt(
      state['weeklyBudget'],
      _weeklyBudget,
    );
    final remoteBudgetConfigured = state['weeklyBudgetConfigured'];

    if (remoteBudgetConfigured is bool) {
      _hasConfiguredWeeklyBudget = remoteBudgetConfigured &&
          remoteBudget >= 50000 &&
          remoteBudget <= 5000000;
    } else {
      // Kompatibilitas untuk state Supabase dari versi lama yang belum
      // memiliki penanda budget. Rp350.000 tanpa Meal Plan dianggap nilai
      // bawaan lama, bukan input yang benar-benar ditetapkan pengguna.
      final remoteHistory = state['mealHistory'];
      final hasRemoteHistory =
          remoteHistory is List && remoteHistory.isNotEmpty;
      final hasRemoteSavedPlan = state['planSaved'] == true;

      _hasConfiguredWeeklyBudget = remoteBudget >= 50000 &&
          remoteBudget <= 5000000 &&
          (remoteBudget != 350000 || hasRemoteSavedPlan || hasRemoteHistory);
    }

    _weeklyBudget = _hasConfiguredWeeklyBudget
        ? remoteBudget.clamp(50000, 5000000).toInt()
        : 0;

    people = _toInt(
      state['people'],
      people,
    ).clamp(1, 20).toInt();

    name =
        (state['name'] is String && (state['name'] as String).trim().isNotEmpty)
            ? (state['name'] as String).trim()
            : name;

    target = state['target'] is String ? state['target'] as String : target;

    planSaved =
        state['planSaved'] is bool ? state['planSaved'] as bool : planSaved;

    final currentIngredients = List<String>.of(ingredients);
    final currentAvailableIngredients = Set<String>.of(availableIngredients);
    final currentShoppingItems = Set<String>.of(shoppingItems);
    final currentManualShoppingItems = Set<String>.of(manualShoppingItems);
    final currentAutoShoppingItems = Set<String>.of(autoShoppingItems);
    final currentExcludedAutoShoppingItems =
        Set<String>.of(excludedAutoShoppingItems);
    final currentCheckedShoppingItems = Set<String>.of(checkedShoppingItems);
    final currentShoppingAmounts = Map<String, String>.of(shoppingAmounts);

    ingredients
      ..clear()
      ..addAll(
        _toStringList(
          state['ingredients'],
          currentIngredients,
        ),
      );

    availableIngredients
      ..clear()
      ..addAll(
        _toStringList(
          state['availableIngredients'],
          currentAvailableIngredients,
        ),
      );

    final hasShoppingItemsInState = state['shoppingItems'] is List;

    final restoredShoppingItems = _toStringList(
      state['shoppingItems'],
      currentShoppingItems,
    );

    shoppingItems
      ..clear()
      ..addAll(restoredShoppingItems);

    // State lama belum memiliki penanda sumber.
    // Semua item yang ada dipertahankan sebagai manual.
    manualShoppingItems
      ..clear()
      ..addAll(
        _toStringList(
          state['manualShoppingItems'],
          hasShoppingItemsInState
              ? restoredShoppingItems
              : currentManualShoppingItems,
        ),
      );

    autoShoppingItems
      ..clear()
      ..addAll(
        _toStringList(
          state['autoShoppingItems'],
          currentAutoShoppingItems,
        ),
      );

    excludedAutoShoppingItems
      ..clear()
      ..addAll(
        _toStringList(
          state['excludedAutoShoppingItems'],
          currentExcludedAutoShoppingItems,
        ),
      );

    checkedShoppingItems
      ..clear()
      ..addAll(
        _toStringList(
          state['checkedShoppingItems'],
          currentCheckedShoppingItems,
        ),
      );

    final prices = state['shoppingPrices'];

    if (prices is Map) {
      shoppingPrices
        ..clear()
        ..addAll(
          prices.map(
            (key, value) => MapEntry(
              key.toString(),
              _toInt(value, 0),
            ),
          ),
        );
    }

    final amounts = state['shoppingAmounts'];
    shoppingAmounts
      ..clear()
      ..addAll(
        amounts is Map
            ? amounts.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              )
            : currentShoppingAmounts,
      );

    final records = state['mealHistory'];

    if (records is List) {
      history
        ..clear()
        ..addAll(
          records.whereType<Map>().map(
                (item) => MealPlanRecord.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              ),
        );
    }

    final storedMenu = state['weeklyMenu'];

    if (storedMenu is List) {
      final restored = _recipesFromNames(
        storedMenu.whereType<String>(),
      );

      if (restored.length == 7) {
        _weeklyMenu = restored;
      }
    }

    // Pulihkan Meal Plan lama dari riwayat jika diperlukan.
    final recoveredLegacyMenu = (storedMenu == null || _weeklyMenu == null) &&
        planSaved &&
        _restoreWeeklyMenuFromLatestHistory();

    if (planSaved && _weeklyMenu == null) {
      planSaved = false;
    }

    return recoveredLegacyMenu;
  }

  List<Recipe> _recipesFromNames(Iterable<String> names) {
    final byName = {
      for (final recipe in _recipeCatalog) recipe.name: recipe,
    };

    return names
        .map((recipeName) => byName[recipeName])
        .whereType<Recipe>()
        .toList(growable: false);
  }

  bool _isRestorableMenu(dynamic value) {
    if (value is! List) return false;

    final names = value.whereType<String>().toList();

    return names.length == 7 && _recipesFromNames(names).length == 7;
  }

  bool _restoreWeeklyMenuFromLatestHistory() {
    if (_weeklyMenu != null && _weeklyMenu!.length == 7) {
      return false;
    }

    if (!planSaved || history.isEmpty) {
      return false;
    }

    final restored = _recipesFromNames(
      history.first.recipeNames,
    );

    if (restored.length != 7) return false;

    _weeklyMenu = restored;

    return true;
  }

  // ============================================================
  // AUTOMATIC SHOPPING LIST SYNCHRONIZATION
  // ============================================================

  /// Menyesuaikan bahan otomatis tanpa menghapus item manual pengguna.
  /// Semua bahan disimpan sebagai nama satuan yang sudah dinormalisasi.
  bool _syncShoppingListWithMenu(List<Recipe> menu) {
    if (menu.length != 7) return false;

    final previousShoppingItems = Set<String>.of(shoppingItems);
    final previousManualItems = Set<String>.of(manualShoppingItems);
    final previousAutoItems = Set<String>.of(autoShoppingItems);
    final previousExcludedItems = Set<String>.of(excludedAutoShoppingItems);
    final previousCheckedItems = Set<String>.of(checkedShoppingItems);
    final previousPrices = Map<String, int>.of(shoppingPrices);
    final previousAmounts = Map<String, String>.of(shoppingAmounts);

    // Item lama tanpa metadata sumber tetap dipertahankan sebagai item manual.
    for (final item in shoppingItems) {
      final isManual = _containsShoppingName(manualShoppingItems, item);
      final isAutomatic = _containsShoppingName(autoShoppingItems, item);

      if (!isManual && !isAutomatic) {
        _addShoppingName(manualShoppingItems, item);
      }
    }

    // Pecah dan normalisasi bahan manual tanpa mengubah item yang sudah ada.
    final normalizedManualItems = <String, String>{};
    for (final item in manualShoppingItems) {
      for (final name in _canonicalShoppingNames(item)) {
        normalizedManualItems.putIfAbsent(
          _shoppingNameKey(name),
          () => name,
        );
      }
    }

    manualShoppingItems
      ..clear()
      ..addAll(normalizedManualItems.values);

    manualShoppingItems.removeWhere(
      (item) => _containsShoppingName(availableIngredients, item),
    );

    // Agregasikan kebutuhan seluruh tujuh resep setelah diskalakan ke jumlah
    // orang. Harga bahan pada katalog adalah estimasi untuk satu batch resep,
    // sehingga dikalikan people / servings sebelum digabungkan.
    final requiredItems = <String, String>{};
    final requiredPrices = <String, double>{};
    final requiredQuantities = <String, IngredientQuantityAccumulator>{};

    for (final recipe in menu) {
      final servingMultiplier = _servingMultiplier(recipe);

      for (final ingredient in recipe.ingredients) {
        final names = _canonicalShoppingNames(ingredient.name);
        if (names.isEmpty) continue;

        final splitPrices = _splitShoppingPrice(
          ingredient.price,
          names.length,
        );

        for (var index = 0; index < names.length; index++) {
          final name = names[index];

          if (_containsShoppingName(availableIngredients, name)) {
            continue;
          }

          final key = _shoppingNameKey(name);
          requiredItems.putIfAbsent(key, () => name);
          requiredPrices.update(
            key,
            (current) => current + (splitPrices[index] * servingMultiplier),
            ifAbsent: () => splitPrices[index] * servingMultiplier,
          );

          requiredQuantities
              .putIfAbsent(key, () => IngredientQuantityAccumulator())
              .add(
                ingredient.amount,
                multiplier: servingMultiplier,
                groupedIngredient: names.length > 1,
              );
        }
      }
    }

    // Pengecualian berlaku selama bahan masih dibutuhkan menu aktif.
    final normalizedExcludedItems = <String, String>{};
    for (final item in excludedAutoShoppingItems) {
      for (final name in _canonicalShoppingNames(item)) {
        normalizedExcludedItems.putIfAbsent(
          _shoppingNameKey(name),
          () => name,
        );
      }
    }

    excludedAutoShoppingItems
      ..clear()
      ..addAll(normalizedExcludedItems.values);

    excludedAutoShoppingItems.removeWhere(
      (item) => !requiredItems.containsKey(_shoppingNameKey(item)),
    );

    for (final excluded in excludedAutoShoppingItems) {
      final key = _shoppingNameKey(excluded);
      requiredItems.remove(key);
      requiredPrices.remove(key);
      requiredQuantities.remove(key);
    }

    // Gabungkan bahan manual dan otomatis tanpa duplikasi nama.
    final combinedItems = <String, String>{};
    for (final item in manualShoppingItems) {
      combinedItems.putIfAbsent(_shoppingNameKey(item), () => item);
    }
    for (final entry in requiredItems.entries) {
      combinedItems.putIfAbsent(entry.key, () => entry.value);
    }

    final nextShoppingItems = combinedItems.values.toSet();
    final nextAutoItems = requiredItems.values.toSet();

    // Harga/jumlah lama dinormalisasi untuk mempertahankan item manual dari
    // versi sebelumnya yang belum menyimpan metadata kuantitas.
    final existingPricesByKey = <String, int>{};
    for (final entry in shoppingPrices.entries) {
      final names = _canonicalShoppingNames(entry.key);
      if (names.isEmpty) continue;

      final splitPrices = _splitShoppingPrice(entry.value, names.length);
      for (var index = 0; index < names.length; index++) {
        existingPricesByKey.putIfAbsent(
          _shoppingNameKey(names[index]),
          () => splitPrices[index],
        );
      }
    }

    final existingAmountsByKey = <String, String>{};
    for (final entry in shoppingAmounts.entries) {
      final names = _canonicalShoppingNames(entry.key);
      for (final name in names) {
        existingAmountsByKey.putIfAbsent(
          _shoppingNameKey(name),
          () => entry.value,
        );
      }
    }

    final nextPrices = <String, int>{};
    final nextAmounts = <String, String>{};

    for (final item in nextShoppingItems) {
      final key = _shoppingNameKey(item);

      if (requiredItems.containsKey(key)) {
        nextPrices[item] = (requiredPrices[key] ?? 0).round();
        final amountLabel = requiredQuantities[key]?.label;
        if (amountLabel != null && amountLabel.isNotEmpty) {
          nextAmounts[item] = amountLabel;
        }
      } else {
        nextPrices[item] = existingPricesByKey[key] ?? 0;
        final amountLabel = existingAmountsByKey[key];
        if (amountLabel != null && amountLabel.isNotEmpty) {
          nextAmounts[item] = amountLabel;
        }
      }
    }

    // Centang lama pada item gabungan diterapkan ke semua bahan turunannya.
    final checkedKeys = <String>{};
    for (final checkedItem in checkedShoppingItems) {
      checkedKeys.addAll(_shoppingNameKeys(checkedItem));
    }

    final normalizedCheckedItems = <String>{};
    for (final item in nextShoppingItems) {
      if (checkedKeys.contains(_shoppingNameKey(item))) {
        normalizedCheckedItems.add(item);
      }
    }

    checkedShoppingItems
      ..clear()
      ..addAll(normalizedCheckedItems);

    shoppingItems
      ..clear()
      ..addAll(nextShoppingItems);

    autoShoppingItems
      ..clear()
      ..addAll(nextAutoItems);

    shoppingPrices
      ..clear()
      ..addAll(nextPrices);

    shoppingAmounts
      ..clear()
      ..addAll(nextAmounts);

    return !setEquals(previousShoppingItems, shoppingItems) ||
        !setEquals(previousManualItems, manualShoppingItems) ||
        !setEquals(previousAutoItems, autoShoppingItems) ||
        !setEquals(previousExcludedItems, excludedAutoShoppingItems) ||
        !setEquals(previousCheckedItems, checkedShoppingItems) ||
        !mapEquals(previousPrices, shoppingPrices) ||
        !mapEquals(previousAmounts, shoppingAmounts);
  }

  double _servingMultiplier(Recipe recipe) {
    final recipeServings = recipe.servings > 0 ? recipe.servings : 1;
    return people / recipeServings;
  }

  bool _syncActiveShoppingList() {
    final menu = _weeklyMenu;

    if (menu == null || menu.length != 7) {
      return false;
    }

    return _syncShoppingListWithMenu(menu);
  }

  /// Memecah satu nama bahan yang berisi beberapa bahan eksplisit.
  /// Contoh: "Wortel dan buncis" menjadi ["Wortel", "Buncis"].
  /// Nama seperti "air jeruk nipis" tidak dipecah.
  static List<String> _canonicalShoppingNames(String value) {
    var cleaned = value.trim();
    if (cleaned.isEmpty) return const [];

    // Hapus keterangan tambahan dari dataset, bukan bagian nama bahan.
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\([^)]*\)'),
      (match) {
        final note = match.group(0)!.toLowerCase();
        if (note.contains('estimasi') || note.contains('pelengkap')) {
          return ' ';
        }
        return match.group(0)!;
      },
    );

    cleaned = cleaned
        .replaceAll(
          RegExp(
            r'\b(?:secukupnya|secukupnyaa|sesuai\s+selera)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) return const [];

    // Pisahkan daftar bahan yang ditulis memakai koma, "dan", atau "/".
    final parts = cleaned.split(
      RegExp(r'\s+(?:dan|&|\+)\s+|[,;/]'),
    );

    final result = <String>[];
    final seen = <String>{};

    for (final part in parts) {
      final name = _canonicalSingleShoppingName(part);
      if (name.isEmpty) continue;

      final key = name.toLowerCase();
      if (seen.add(key)) {
        result.add(name);
      }
    }

    return result;
  }

  /// Mengubah variasi penulisan menjadi satu nama bahan baku.
  static String _canonicalSingleShoppingName(String value) {
    var name = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\s.,;:]+|[\s.,;:]+$'), '')
        .trim();

    if (name.isEmpty) return '';

    // Hapus awalan jumlah yang kadang masuk ke kolom nama bahan.
    name = name.replaceFirst(
      RegExp(
        r'^(?:(?:\d+(?:[.,]\d+)?\s*)(?:buah|butir|siung|lembar|batang|ruas|sdt|sdm|gram|gr|kg|ml|liter)\s+|bh\s+)',
        caseSensitive: false,
      ),
      '',
    );

    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (name.isEmpty) return '';

    var key = name.toLowerCase();

    // Samakan beberapa variasi istilah dan ejaan yang umum.
    key = key.replaceAll(RegExp(r'\bcabe\b'), 'cabai');
    key = key.replaceAll(RegExp(r'\btelor\b'), 'telur');

    // "Perasaan air jeruk nipis" merupakan variasi/typo dari "perasan".
    key = key.replaceFirst(
      RegExp(r'^(?:perasan|perasaan)\s+'),
      '',
    );

    // Air jeruk nipis dan air asam jawa adalah bahan khusus,
    // jadi harus diperiksa sebelum alias air biasa.
    if (key == 'air jeruk nipis') return 'Air jeruk nipis';
    if (key == 'air asam jawa') return 'Air asam jawa';

    // Potongan ayam yang dicatat dengan nama berbeda digabung.
    if (key == 'ayam' ||
        key == 'dada ayam' ||
        key == 'ayam fillet' ||
        key == 'ayam filet' ||
        key == 'fillet ayam' ||
        key == 'filet ayam') {
      return 'Ayam';
    }

    if (key == 'telur' || key == 'telur ayam') return 'Telur';

    if (key == 'tomat merah') return 'Tomat';
    if (key == 'beras putih') return 'Beras';
    if (key == 'gula') return 'Gula pasir';

    if (key == 'cabai rawit' || key == 'cabai rawit merah') {
      return 'Cabai rawit';
    }

    if (key == 'tepung bumbu serbaguna') return 'Tepung bumbu';

    // Minyak khusus tidak boleh digabung dengan minyak goreng.
    if (key.startsWith('minyak wijen')) return 'Minyak wijen';
    if (key.startsWith('minyak zaitun')) return 'Minyak zaitun';

    if (key == 'minyak' ||
        key == 'minyak goreng' ||
        key == 'minyak sayur' ||
        key.startsWith('minyak untuk ') ||
        key.startsWith('minyak buat ') ||
        key.startsWith('minyak goreng untuk ')) {
      return 'Minyak goreng';
    }

    if (key == 'air' ||
        key == 'air putih' ||
        key == 'air matang' ||
        key.startsWith('air untuk ')) {
      return 'Air';
    }

    // Tampilkan nama bahan dengan huruf awal kapital.
    return '${key[0].toUpperCase()}${key.substring(1)}';
  }

  static Set<String> _shoppingNameKeys(String value) {
    return _canonicalShoppingNames(value)
        .map((name) => name.toLowerCase())
        .toSet();
  }

  /// Key ini dipakai untuk satu bahan pada Shopping List.
  static String _shoppingNameKey(String value) {
    return _canonicalSingleShoppingName(value).toLowerCase();
  }

  /// Nama gabungan dianggap tersedia hanya jika semua komponennya
  /// sudah ditemukan pada daftar yang diperiksa.
  static bool _containsShoppingName(
    Iterable<String> values,
    String name,
  ) {
    final wantedKeys = _shoppingNameKeys(name);
    if (wantedKeys.isEmpty) return false;

    final availableKeys = <String>{};
    for (final value in values) {
      availableKeys.addAll(_shoppingNameKeys(value));
    }

    return wantedKeys.every(availableKeys.contains);
  }

  /// Menambahkan semua komponen nama bahan gabungan secara terpisah.
  static void _addShoppingName(
    Set<String> values,
    String name,
  ) {
    for (final cleaned in _canonicalShoppingNames(name)) {
      if (!_containsShoppingName(values, cleaned)) {
        values.add(cleaned);
      }
    }
  }

  /// Menghapus satu atau beberapa komponen dari nama bahan gabungan.
  static void _removeShoppingName(
    Set<String> values,
    String name,
  ) {
    final keys = _shoppingNameKeys(name);
    if (keys.isEmpty) return;

    values.removeWhere(
      (value) => _shoppingNameKeys(value).any(keys.contains),
    );
  }

  /// Membagi estimasi harga bahan gabungan dengan tetap menjaga totalnya.
  static List<int> _splitShoppingPrice(int totalPrice, int count) {
    if (count <= 0) return const [];
    if (count == 1) return [totalPrice];

    final basePrice = totalPrice ~/ count;
    final remainder = totalPrice - (basePrice * count);

    return List<int>.generate(
      count,
      (index) => basePrice + (index == 0 ? remainder : 0),
      growable: false,
    );
  }

  // ============================================================
  // BUDGET AND MEAL PLAN
  // ============================================================

  int get weeklyBudget => _weeklyBudget;

  bool get hasWeeklyBudget =>
      _hasConfiguredWeeklyBudget &&
      _weeklyBudget >= 50000 &&
      _weeklyBudget <= 5000000;

  set weeklyBudget(int value) {
    final normalized = value.clamp(50000, 5000000).toInt();

    if (_weeklyBudget == normalized && hasWeeklyBudget) return;

    _weeklyBudget = normalized;
    _hasConfiguredWeeklyBudget = true;

    _weeklyMenu = null;
    planSaved = false;

    _save();
    notifyListeners();
  }

  /// Anggaran harian per orang.
  int get dailyPerPerson {
    if (!hasWeeklyBudget) return 0;
    return (weeklyBudget / people / 7).round();
  }

  /// Total estimasi tujuh menu untuk semua orang.
  int get estimatedTotal {
    return weeklyRecipes.fold(
      0,
      (sum, recipe) => sum + recipe.costPerServing * people,
    );
  }

  int get minimumWeeklyBudget {
    final catalog = _recipeCatalog;

    if (catalog.isEmpty) return 0;

    final cheapest = catalog.map((recipe) => recipe.costPerServing).reduce(
          (a, b) => a < b ? a : b,
        );

    return cheapest * people * 7;
  }

  bool get isBudgetSufficient {
    if (!hasWeeklyBudget) return false;
    return estimatedTotal <= weeklyBudget;
  }

  int get budgetShortfall {
    if (!hasWeeklyBudget) return 0;
    return estimatedTotal > weeklyBudget ? estimatedTotal - weeklyBudget : 0;
  }

  List<Recipe> get recipeCatalog {
    return List.unmodifiable(_recipeCatalog);
  }

  int get remainingBudget {
    if (!hasWeeklyBudget) return 0;
    return weeklyBudget - estimatedTotal;
  }

  int get shoppingTotal {
    return shoppingItems.fold(
      0,
      (sum, item) => sum + (shoppingPrices[item] ?? 0),
    );
  }

  void setPeople(int value) {
    final normalized = value.clamp(1, 20).toInt();

    if (people == normalized) return;

    people = normalized;

    _weeklyMenu = null;
    planSaved = false;

    _save();
    notifyListeners();
  }

  void setName(String value) {
    final cleaned = value.trim();

    if (cleaned.isEmpty) return;

    name = cleaned;

    _save();
    notifyListeners();
  }

  List<Recipe> get weeklyRecipes {
    if (!hasWeeklyBudget) {
      throw StateError(
        'Atur batas anggaran mingguan terlebih dahulu.',
      );
    }

    if (_weeklyMenu != null) {
      return List.unmodifiable(_weeklyMenu!);
    }

    return _generatedMenu;
  }

  /// Membentuk menu tujuh hari dari katalog Supabase/cache yang valid.
  ///
  /// Pemilihan resep tidak bergantung pada urutan baris di Supabase.
  /// Bahan pantry, prioritas menu, variasi, dan batas budget menjadi
  /// faktor penilaian setiap resep.
  List<Recipe> get _generatedMenu {
    final catalog = _recipeCatalog
        .where((recipe) =>
            recipe.name.trim().isNotEmpty && recipe.costPerServing >= 0)
        .toList(growable: false);

    if (catalog.length < 7) {
      throw StateError(
        'Katalog resep asli belum berhasil dimuat.',
      );
    }

    return _buildRecommendedMenu(catalog);
  }

  List<Recipe> _buildRecommendedMenu(List<Recipe> catalog) {
    final cheapestRecipe = catalog.reduce((a, b) {
      if (a.costPerServing < b.costPerServing) return a;
      if (b.costPerServing < a.costPerServing) return b;
      return a.name.compareTo(b.name) <= 0 ? a : b;
    });

    final cheapestCost = cheapestRecipe.costPerServing;
    final budgetPerPerson = weeklyBudget ~/ people;
    final minimumPerPerson = cheapestCost * 7;

    // Jika budget tidak mencukupi biaya minimum, gunakan resep termurah
    // secara transparan. Status kekurangan budget tetap dihitung terpisah.
    if (budgetPerPerson < minimumPerPerson) {
      return List<Recipe>.filled(
        7,
        cheapestRecipe,
        growable: false,
      );
    }

    final minimumCost = catalog
        .map((recipe) => recipe.costPerServing)
        .reduce((a, b) => a < b ? a : b);
    final maximumCost = catalog
        .map((recipe) => recipe.costPerServing)
        .reduce((a, b) => a > b ? a : b);

    // Gunakan gram protein hanya bila seluruh kandidat memiliki data.
    // Jika ada data yang belum tersedia, jangan menganggap null sebagai nol.
    final hasCompleteProteinData = catalog.every(
      (recipe) => recipe.proteinGramsPerServing != null,
    );
    final proteinValues = hasCompleteProteinData
        ? catalog
            .map((recipe) => recipe.proteinGramsPerServing!)
            .toList(growable: false)
        : const <double>[];
    final minimumProtein = proteinValues.isEmpty
        ? 0.0
        : proteinValues.reduce((a, b) => a < b ? a : b);
    final maximumProtein = proteinValues.isEmpty
        ? 0.0
        : proteinValues.reduce((a, b) => a > b ? a : b);

    var remainingBudget = budgetPerPerson;
    final result = <Recipe>[];
    final usedRecipeNames = <String>{};
    final usedProteinGroups = <String>{};
    final usedBalancedGroups = <String>{};
    final usageCounts = <String, int>{};

    for (var day = 0; day < 7; day++) {
      final daysAfterToday = 6 - day;
      final reserveForRemainingDays = cheapestCost * daysAfterToday;
      final maximumToday = remainingBudget - reserveForRemainingDays;

      final affordable = catalog
          .where((recipe) => recipe.costPerServing <= maximumToday)
          .toList();

      if (affordable.isEmpty) {
        // Perlindungan tambahan jika data harga katalog tidak konsisten.
        affordable.add(cheapestRecipe);
      }

      // Hindari pengulangan selama masih ada resep berbeda yang terjangkau.
      // Pengulangan baru boleh terjadi jika semua kandidat yang terjangkau
      // sudah pernah dipilih untuk hari sebelumnya.
      final unusedAffordable = affordable
          .where((recipe) => !usedRecipeNames.contains(recipe.name))
          .toList();
      final candidates =
          unusedAffordable.isNotEmpty ? unusedAffordable : affordable;

      candidates.sort((a, b) {
        final scoreA = _recipePriorityScore(
          a,
          usedProteinGroups: usedProteinGroups,
          usedBalancedGroups: usedBalancedGroups,
          minimumCost: minimumCost,
          maximumCost: maximumCost,
          hasCompleteProteinData: hasCompleteProteinData,
          minimumProtein: minimumProtein,
          maximumProtein: maximumProtein,
        );
        final scoreB = _recipePriorityScore(
          b,
          usedProteinGroups: usedProteinGroups,
          usedBalancedGroups: usedBalancedGroups,
          minimumCost: minimumCost,
          maximumCost: maximumCost,
          hasCompleteProteinData: hasCompleteProteinData,
          minimumProtein: minimumProtein,
          maximumProtein: maximumProtein,
        );

        final scoreCompare = scoreB.compareTo(scoreA);
        if (scoreCompare != 0) return scoreCompare;

        final usageCompare = (usageCounts[a.name] ?? 0).compareTo(
          usageCounts[b.name] ?? 0,
        );
        if (usageCompare != 0) return usageCompare;

        final costCompare = a.costPerServing.compareTo(b.costPerServing);
        if (costCompare != 0) return costCompare;

        return a.name.compareTo(b.name);
      });

      final selected = candidates.first;
      result.add(selected);
      usedRecipeNames.add(selected.name);
      usageCounts[selected.name] = (usageCounts[selected.name] ?? 0) + 1;
      usedProteinGroups.addAll(_proteinSourceGroups(selected));
      usedBalancedGroups.addAll(_balancedFoodGroups(selected));
      remainingBudget -= selected.costPerServing;
    }

    return List<Recipe>.unmodifiable(result);
  }

  int _recipePriorityScore(
    Recipe recipe, {
    required Set<String> usedProteinGroups,
    required Set<String> usedBalancedGroups,
    required int minimumCost,
    required int maximumCost,
    required bool hasCompleteProteinData,
    required double minimumProtein,
    required double maximumProtein,
  }) {
    final pantryCoverage = _pantryCoverageScore(recipe);
    final costRange = maximumCost - minimumCost;
    final costAdvantage = costRange <= 0
        ? 50
        : ((maximumCost - recipe.costPerServing) * 100 ~/ costRange);

    final proteinGroups = _proteinSourceGroups(recipe);
    final newProteinGroups = proteinGroups.difference(usedProteinGroups);
    final balancedGroups = _balancedFoodGroups(recipe);
    final newBalancedGroups = balancedGroups.difference(usedBalancedGroups);

    switch (target) {
      case 'Hemat':
        // Harga tetap menjadi faktor utama, sementara bahan pantry
        // membantu memilih resep yang mengurangi kebutuhan belanja.
        return (costAdvantage * 4) + (pantryCoverage * 2);

      case 'Tinggi Protein':
        if (hasCompleteProteinData) {
          final proteinRange = maximumProtein - minimumProtein;
          final proteinScore = proteinRange <= 0
              ? 100
              : (((recipe.proteinGramsPerServing! - minimumProtein) * 100) /
                      proteinRange)
                  .round();

          // Gram protein menjadi faktor utama; variasi, pantry, dan biaya
          // menjadi faktor pendukung ketika nilai nutrisi tersedia lengkap.
          return (proteinScore * 10) +
              (newProteinGroups.length * 25) +
              (pantryCoverage * 2) +
              costAdvantage;
        }

        // Fallback kualitatif saat data protein per porsi belum lengkap.
        // Tidak ada angka gram protein yang ditebak atau disimpulkan.
        return (proteinGroups.length * 180) +
            (newProteinGroups.length * 100) +
            (pantryCoverage * 2) +
            costAdvantage;

      case 'Seimbang':
      default:
        // Variasi kelompok karbohidrat, protein, dan sayuran diprioritaskan.
        return (balancedGroups.length * 50) +
            (newBalancedGroups.length * 80) +
            (pantryCoverage * 3) +
            costAdvantage;
    }
  }

  /// Persentase bahan resep yang sudah tercatat tersedia di pantry.
  /// Nama bahan mengikuti normalisasi yang sama dengan Shopping List.
  int _pantryCoverageScore(Recipe recipe) {
    if (availableIngredients.isEmpty) return 0;

    final recipeKeys = _recipeIngredientKeys(recipe);
    if (recipeKeys.isEmpty) return 0;

    final pantryKeys = <String>{};
    for (final item in availableIngredients) {
      pantryKeys.addAll(_shoppingNameKeys(item));
    }

    final matchedCount = recipeKeys.where(pantryKeys.contains).length;
    return (matchedCount * 100 ~/ recipeKeys.length).clamp(0, 100).toInt();
  }

  Set<String> _recipeIngredientKeys(Recipe recipe) {
    final keys = <String>{};

    for (final ingredient in recipe.ingredients) {
      keys.addAll(_shoppingNameKeys(ingredient.name));
    }

    return keys;
  }

  /// Kelompok sumber protein berdasarkan nama bahan yang benar-benar ada.
  /// Tidak menilai atau mengarang kandungan protein dalam gram.
  Set<String> _proteinSourceGroups(Recipe recipe) {
    final ingredientText = recipe.ingredients
        .map((ingredient) => ingredient.name.toLowerCase())
        .join(' ');

    bool containsAny(List<String> keywords) {
      return keywords.any(
        (keyword) => RegExp(
          '(^|[^a-z0-9])${RegExp.escape(keyword)}([^a-z0-9]|\$)',
        ).hasMatch(ingredientText),
      );
    }

    final groups = <String>{};

    if (containsAny(['ayam', 'bebek', 'unggas'])) {
      groups.add('unggas');
    }
    if (containsAny(['telur'])) {
      groups.add('telur');
    }
    if (containsAny([
      'ikan',
      'lele',
      'nila',
      'tuna',
      'salmon',
      'udang',
      'cumi',
      'kerang',
    ])) {
      groups.add('ikan_dan_makanan_laut');
    }
    if (containsAny(['sapi', 'daging', 'kambing'])) {
      groups.add('daging');
    }
    if (containsAny([
      'tahu',
      'tempe',
      'kacang',
      'edamame',
      'kedelai',
    ])) {
      groups.add('protein_nabati');
    }
    if (containsAny(['susu', 'yogurt', 'yoghurt', 'keju'])) {
      groups.add('produk_susu');
    }

    return groups;
  }

  /// Kelompok bahan untuk mendorong variasi menu seimbang.
  Set<String> _balancedFoodGroups(Recipe recipe) {
    final ingredientText = recipe.ingredients
        .map((ingredient) => ingredient.name.toLowerCase())
        .join(' ');

    bool containsAny(List<String> keywords) {
      return keywords.any(
        (keyword) => RegExp(
          '(^|[^a-z0-9])${RegExp.escape(keyword)}([^a-z0-9]|\$)',
        ).hasMatch(ingredientText),
      );
    }

    final groups = <String>{};

    if (containsAny([
      'beras',
      'nasi',
      'mi',
      'mie',
      'bihun',
      'soun',
      'kentang',
      'ubi',
      'jagung',
      'roti',
      'pasta',
    ])) {
      groups.add('karbohidrat');
    }

    if (_proteinSourceGroups(recipe).isNotEmpty) {
      groups.add('protein');
    }

    if (containsAny([
      'sayur',
      'sayuran',
      'wortel',
      'buncis',
      'bayam',
      'kangkung',
      'brokoli',
      'kol',
      'kubis',
      'tomat',
      'selada',
      'sawi',
      'timun',
      'terong',
    ])) {
      groups.add('sayuran');
    }

    return groups;
  }

  // ============================================================
  // PANTRY / STOK DAPUR
  // ============================================================

  void addIngredient(String value) {
    final item = value.trim();

    if (item.isEmpty ||
        ingredients.any(
          (existing) => existing.toLowerCase() == item.toLowerCase(),
        )) {
      return;
    }

    ingredients.add(item);
    availableIngredients.add(item);

    _syncActiveShoppingList();

    _save();
    notifyListeners();
  }

  void removeIngredient(String item) {
    ingredients.remove(item);
    availableIngredients.remove(item);

    _syncActiveShoppingList();

    _save();
    notifyListeners();
  }

  void toggleAvailable(String item) {
    if (!availableIngredients.add(item)) {
      availableIngredients.remove(item);
    }

    _syncActiveShoppingList();

    _save();
    notifyListeners();
  }

  void selectTarget(String value) {
    target = value;

    _weeklyMenu = null;
    planSaved = false;

    _save();
    notifyListeners();
  }

  // ============================================================
  // MEAL PLAN
  // ============================================================

  void changeRecipe(int dayIndex, Recipe recipe) {
    final menu = weeklyRecipes.toList();

    menu[dayIndex] = recipe;

    _weeklyMenu = menu;
    planSaved = false;

    // Sinkronisasi langsung ketika resep diganti.
    _syncShoppingListWithMenu(menu);

    _save();
    notifyListeners();
  }

  Map<String, int> get estimateByCategory {
    final totals = <String, int>{};

    for (final item in shoppingItems) {
      final category = categoryFor(item);
      totals[category] = (totals[category] ?? 0) + (shoppingPrices[item] ?? 0);
    }

    return totals;
  }

  void savePlan() {
    final selectedMenu = List<Recipe>.of(weeklyRecipes);

    if (selectedMenu.length != 7) {
      debugPrint(
        'Meal Plan tidak disimpan: jumlah resep harus 7, '
        'ditemukan ${selectedMenu.length}.',
      );
      return;
    }

    // Jika sudah tersimpan, jangan membuat riwayat duplikat.
    if (planSaved) {
      var changed = false;

      if (_weeklyMenu == null || _weeklyMenu!.length != 7) {
        _weeklyMenu = selectedMenu;
        changed = true;
      }

      changed = _syncShoppingListWithMenu(selectedMenu) || changed;

      if (changed) {
        _save();
        notifyListeners();
      }

      return;
    }

    _weeklyMenu = selectedMenu;

    history.insert(
      0,
      MealPlanRecord(
        createdAt: DateTime.now(),
        target: target,
        people: people,
        budget: weeklyBudget,
        total: estimatedTotal,
        recipeNames: selectedMenu.map((recipe) => recipe.name).toList(),
      ),
    );

    if (history.length > 40) {
      history.removeLast();
    }

    planSaved = true;

    // Sinkronisasi otomatis ketika Meal Plan disimpan.
    _syncShoppingListWithMenu(selectedMenu);

    _save();
    notifyListeners();
  }

  // ============================================================
  // SHOPPING LIST
  // ============================================================

  /// Menambahkan bahan dari Detail Resep sebagai item manual.
  /// Item ini tetap dipertahankan meskipun Meal Plan berubah.
  void addRecipeToShoppingList(Recipe recipe) {
    final servingMultiplier = _servingMultiplier(recipe);

    for (final ingredient in recipe.ingredients) {
      final names = _canonicalShoppingNames(ingredient.name);
      if (names.isEmpty) continue;

      final splitPrices = _splitShoppingPrice(
        ingredient.price,
        names.length,
      );

      for (var index = 0; index < names.length; index++) {
        final name = names[index];

        if (_containsShoppingName(availableIngredients, name) ||
            _containsShoppingName(shoppingItems, name)) {
          continue;
        }

        _addShoppingName(manualShoppingItems, name);
        _removeShoppingName(excludedAutoShoppingItems, name);
        _addShoppingName(shoppingItems, name);

        final amountAccumulator = IngredientQuantityAccumulator()
          ..add(
            ingredient.amount,
            multiplier: servingMultiplier,
            groupedIngredient: names.length > 1,
          );
        final amountLabel = amountAccumulator.label;
        if (amountLabel != null) shoppingAmounts[name] = amountLabel;

        shoppingPrices[name] = (splitPrices[index] * servingMultiplier).round();
      }
    }

    _syncActiveShoppingList();

    _save();
    notifyListeners();
  }

  /// Tombol manual pada halaman Daftar Belanja tetap tersedia.
  /// Fungsi ini sekarang menjalankan sinkronisasi idempoten.
  void addWeeklyMenuToShoppingList() {
    final selectedMenu = List<Recipe>.of(weeklyRecipes);

    _syncShoppingListWithMenu(selectedMenu);

    _save();
    notifyListeners();
  }

  void toggleShoppingItem(String item) {
    if (!checkedShoppingItems.add(item)) {
      checkedShoppingItems.remove(item);
    }

    _save();
    notifyListeners();
  }

  void removeShoppingItem(String item) {
    // Periksa apakah item masih dibutuhkan Meal Plan aktif.
    final isRequiredByActiveMenu = autoShoppingItems.any(
          (value) => _shoppingNameKeys(value).contains(_shoppingNameKey(item)),
        ) ||
        (_weeklyMenu?.any(
              (recipe) => recipe.ingredients.any(
                (ingredient) => _shoppingNameKeys(ingredient.name)
                    .contains(_shoppingNameKey(item)),
              ),
            ) ??
            false);

    // Jika pengguna menghapus bahan yang masih dibutuhkan,
    // jangan langsung menambahkannya lagi saat sinkronisasi berikutnya.
    if (isRequiredByActiveMenu &&
        !_containsShoppingName(availableIngredients, item)) {
      _addShoppingName(
        excludedAutoShoppingItems,
        item,
      );
    }

    _removeShoppingName(manualShoppingItems, item);
    _removeShoppingName(autoShoppingItems, item);
    _removeShoppingName(shoppingItems, item);
    _removeShoppingName(checkedShoppingItems, item);

    final removedKeys = _shoppingNameKeys(item);
    shoppingPrices.removeWhere(
      (key, _) => _shoppingNameKeys(key).any(removedKeys.contains),
    );

    shoppingAmounts.removeWhere(
      (key, _) => _shoppingNameKeys(key).any(removedKeys.contains),
    );

    _save();
    notifyListeners();
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  static String categoryFor(String item) {
    final value = item.toLowerCase();

    if ([
      'wortel',
      'sayur',
      'buncis',
      'bayam',
      'kentang',
      'bawang',
      'tomat',
    ].any(value.contains)) {
      return 'Sayur & Bumbu';
    }

    if ([
      'ayam',
      'telur',
      'tahu',
      'tempe',
      'ikan',
      'daging',
    ].any(value.contains)) {
      return 'Protein';
    }

    return 'Bahan Pokok';
  }

  Map<String, List<String>> get shoppingByCategory {
    final groups = <String, List<String>>{};

    for (final item in shoppingItems) {
      groups
          .putIfAbsent(
            categoryFor(item),
            () => [],
          )
          .add(item);
    }

    return groups;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(flush());
    super.dispose();
  }
}

int _toInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.round();

  return int.tryParse(
        value?.toString() ?? '',
      ) ??
      fallback;
}

List<String> _toStringList(
  dynamic value,
  Iterable<String> fallback,
) {
  if (value is List) {
    return value.whereType<String>().toList();
  }

  return fallback.toList();
}
