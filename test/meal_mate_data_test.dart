import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealmate/data/meal_mate_data.dart';
import 'package:mealmate/models/recipe.dart';
import 'package:mealmate/screens/setup_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixture khusus unit test.
/// Tidak digunakan oleh katalog resep aplikasi.
final List<Recipe> _testRecipes = [
  _recipe(
    'Nasi Ayam Teriyaki',
    12000,
    [
      const RecipeIngredient('Dada ayam', '150 g', 14000),
      const RecipeIngredient('Beras', '150 g', 3000),
      const RecipeIngredient('Wortel dan buncis', '100 g', 2500),
      const RecipeIngredient('Bawang dan bumbu', 'secukupnya', 2000),
      const RecipeIngredient('Saus teriyaki', '2 sdm', 2000),
    ],
    servings: 2,
  ),
  _recipe(
    'Sup Sayur Sederhana',
    9500,
    [
      const RecipeIngredient('Wortel', '1 buah', 2500),
      const RecipeIngredient('Kentang', '1 buah', 3000),
      const RecipeIngredient('Buncis', '50 g', 1500),
      const RecipeIngredient('Bawang putih', '2 siung', 500),
      const RecipeIngredient('Kaldu dan bumbu', 'secukupnya', 2000),
    ],
  ),
  _recipe(
    'Nasi Ayam Kecap',
    10500,
    [
      const RecipeIngredient('Ayam', '150 g', 7000),
      const RecipeIngredient('Beras', '150 g', 3000),
      const RecipeIngredient('Kecap dan bumbu', 'secukupnya', 2500),
    ],
  ),
  _recipe(
    'Tumis Sayur dan Tahu',
    8000,
    [
      const RecipeIngredient('Tahu putih', '2 potong', 3000),
      const RecipeIngredient('Wortel', '1 buah', 2000),
      const RecipeIngredient('Buncis', '50 g', 1500),
      const RecipeIngredient('Bumbu tumis', 'secukupnya', 1500),
    ],
  ),
  _recipe(
    'Sup Sayur Telur',
    7500,
    [
      const RecipeIngredient('Telur', '1 butir', 2500),
      const RecipeIngredient('Wortel', '1 buah', 2000),
      const RecipeIngredient('Sayuran hijau', '50 g', 1500),
      const RecipeIngredient('Bumbu kuah', 'secukupnya', 1500),
    ],
  ),
  _recipe(
    'Nasi Ayam Panggang',
    13500,
    [
      const RecipeIngredient('Ayam', '150 g', 8000),
      const RecipeIngredient('Beras', '150 g', 3000),
      const RecipeIngredient('Bumbu panggang', 'secukupnya', 2500),
    ],
  ),
  _recipe(
    'Mi Sayur Rumahan',
    8500,
    [
      const RecipeIngredient('Mi telur', '1 porsi', 4000),
      const RecipeIngredient('Telur', '1 butir', 2500),
      const RecipeIngredient('Sayuran', 'secukupnya', 1500),
      const RecipeIngredient('Bumbu', 'secukupnya', 500),
    ],
  ),
];

Recipe _recipe(
  String name,
  int cost,
  List<RecipeIngredient> ingredients, {
  int servings = 1,
}) {
  return Recipe(
    name: name,
    description: name,
    minutes: 25,
    costPerServing: cost,
    icon: 'restaurant',
    servings: servings,
    ingredients: ingredients,
    steps: const [],
  );
}

/// Menyediakan cache khusus untuk unit test.
/// Aplikasi produksi tetap mengambil katalog dari Supabase.
void _setMockPreferences([
  Map<String, Object> overrides = const {},
]) {
  final values = <String, Object>{
    'recipeCatalogCache': jsonEncode(
      _testRecipes.map((recipe) => recipe.toJson()).toList(),
    ),
    // Anggaran ini adalah fixture untuk pengujian fitur Meal Plan,
    // bukan nilai bawaan pada aplikasi produksi.
    'weeklyBudget': 350000,
    'weeklyBudgetConfigured': true,
  };

  values.addAll(overrides);

  SharedPreferences.setMockInitialValues(values);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MealMateData local persistence', () {
    setUp(() {
      _setMockPreferences();
    });

    test(
      'starts without a weekly budget for a new user',
      () async {
        SharedPreferences.setMockInitialValues({
          'recipeCatalogCache': jsonEncode(
            _testRecipes.map((recipe) => recipe.toJson()).toList(),
          ),
        });

        final data = MealMateData();
        await data.load();

        expect(data.weeklyBudget, 0);
        expect(data.hasWeeklyBudget, isFalse);
        expect(data.dailyPerPerson, 0);
        expect(() => data.weeklyRecipes, throwsStateError);

        final preferences = await SharedPreferences.getInstance();
        expect(preferences.getInt('weeklyBudget'), 0);
        expect(preferences.getBool('weeklyBudgetConfigured'), isFalse);

        data.dispose();
      },
    );

    test(
      'migrates an unused legacy default budget to not configured',
      () async {
        SharedPreferences.setMockInitialValues({
          'recipeCatalogCache': jsonEncode(
            _testRecipes.map((recipe) => recipe.toJson()).toList(),
          ),
          'weeklyBudget': 350000,
          'planSaved': false,
          'mealHistory': '[]',
        });

        final data = MealMateData();
        await data.load();

        expect(data.hasWeeklyBudget, isFalse);
        expect(data.weeklyBudget, 0);

        final preferences = await SharedPreferences.getInstance();
        expect(preferences.getInt('weeklyBudget'), 0);
        expect(preferences.getBool('weeklyBudgetConfigured'), isFalse);

        data.dispose();
      },
    );

    test(
      'preserves a legacy budget when an older Meal Plan already used it',
      () async {
        SharedPreferences.setMockInitialValues({
          'recipeCatalogCache': jsonEncode(
            _testRecipes.map((recipe) => recipe.toJson()).toList(),
          ),
          'weeklyBudget': 350000,
          'planSaved': false,
          'mealHistory': jsonEncode([
            {
              'createdAt': '2026-11-18T10:00:00.000',
              'target': 'Hemat',
              'people': 2,
              'budget': 350000,
              'total': 105000,
              'recipeNames': <String>[],
            },
          ]),
        });

        final data = MealMateData();
        await data.load();

        expect(data.hasWeeklyBudget, isTrue);
        expect(data.weeklyBudget, 350000);

        data.dispose();
      },
    );

    testWidgets(
      'shows an empty budget field and requires a valid amount',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'recipeCatalogCache': jsonEncode(
            _testRecipes.map((recipe) => recipe.toJson()).toList(),
          ),
        });

        final data = MealMateData();
        await data.load();

        await tester.pumpWidget(
          MaterialApp(
            home: BudgetScreen(data: data),
          ),
        );
        await tester.pumpAndSettle();

        final budgetField = tester.widget<TextField>(
          find.byType(TextField).first,
        );
        expect(budgetField.controller!.text, isEmpty);

        await tester.tap(find.text('Lanjutkan: Bahan Tersedia'));
        await tester.pump();

        expect(data.hasWeeklyBudget, isFalse);
        expect(find.text('Bahan yang Tersedia'), findsNothing);

        await tester.enterText(find.byType(TextField).first, '150000');
        await tester.pump();

        expect(data.hasWeeklyBudget, isTrue);
        expect(data.weeklyBudget, 150000);

        await tester.tap(find.text('Lanjutkan: Bahan Tersedia'));
        await tester.pumpAndSettle();

        expect(find.text('Bahan yang Tersedia'), findsOneWidget);

        await data.flush();
        data.dispose();
      },
    );

    test(
      'restores saved profile, budget, people, and ingredients',
      () async {
        _setMockPreferences({
          'weeklyBudget': 425000,
          'people': 3,
          'name': 'FerdyMyla',
          'target': 'Seimbang',
          'ingredients': ['Beras', 'Telur', 'Ayam'],
          'availableIngredients': ['Beras', 'Telur'],
          'shoppingItems': ['Wortel'],
          'checkedShoppingItems': <String>[],
          'shoppingPrices': '{"Wortel":5000}',
          'mealHistory': '[]',
        });

        final data = MealMateData();
        await data.load();

        expect(data.weeklyBudget, 425000);
        expect(data.people, 3);
        expect(data.name, 'FerdyMyla');
        expect(data.target, 'Seimbang');

        expect(
          data.ingredients,
          ['Beras', 'Telur', 'Ayam'],
        );

        expect(
          data.availableIngredients,
          {'Beras', 'Telur'},
        );

        expect(data.shoppingItems, {'Wortel'});
        expect(data.shoppingPrices['Wortel'], 5000);

        await data.flush();
        data.dispose();
      },
    );

    test(
      'saves the active seven-day menu as well as its history',
      () async {
        final data = MealMateData();
        await data.load();

        final expectedMenu =
            data.weeklyRecipes.map((recipe) => recipe.name).toList();

        expect(expectedMenu, hasLength(7));

        data.savePlan();
        await data.flush();

        final preferences = await SharedPreferences.getInstance();

        expect(
          preferences.getStringList('weeklyMenu'),
          expectedMenu,
        );

        expect(
          preferences.getBool('planSaved'),
          isTrue,
        );

        final savedHistory = jsonDecode(
          preferences.getString('mealHistory')!,
        ) as List<dynamic>;

        expect(savedHistory, hasLength(1));
        expect(
          savedHistory.first['recipeNames'],
          expectedMenu,
        );

        // Daftar Belanja juga harus terisi otomatis.
        expect(data.autoShoppingItems, isNotEmpty);

        expect(
          data.shoppingItems,
          containsAll(data.autoShoppingItems),
        );

        expect(
          preferences.getStringList('autoShoppingItems'),
          isNotEmpty,
        );

        await data.flush();
        data.dispose();
      },
    );

    test(
      'recovers legacy saved menu from the latest meal history',
      () async {
        const legacyMenu = [
          'Tumis Sayur dan Tahu',
          'Sup Sayur Telur',
          'Sup Sayur Sederhana',
          'Mi Sayur Rumahan',
          'Nasi Ayam Teriyaki',
          'Tumis Sayur dan Tahu',
          'Sup Sayur Sederhana',
        ];

        _setMockPreferences({
          'planSaved': true,
          'target': 'Hemat',
          'mealHistory': jsonEncode([
            {
              'createdAt': '2026-11-17T16:57:58.299',
              'target': 'Hemat',
              'people': 2,
              'budget': 300000,
              'total': 126000,
              'recipeNames': legacyMenu,
            },
          ]),
        });

        final data = MealMateData();
        await data.load();
        await data.flush();

        expect(
          data.weeklyRecipes.map((recipe) => recipe.name).toList(),
          legacyMenu,
        );

        final preferences = await SharedPreferences.getInstance();

        expect(
          preferences.getStringList('weeklyMenu'),
          legacyMenu,
        );

        expect(data.history, hasLength(1));
        expect(data.planSaved, isTrue);

        // Menu lama juga disinkronkan ke Daftar Belanja.
        expect(data.autoShoppingItems, isNotEmpty);

        data.dispose();
      },
    );

    test(
      'adapts the seven-day menu to a lower but feasible budget',
      () async {
        final data = MealMateData();
        await data.load();

        data.setPeople(2);
        data.weeklyBudget = 110000;

        expect(data.weeklyRecipes, hasLength(7));

        expect(
          data.estimatedTotal,
          lessThanOrEqualTo(110000),
        );

        expect(data.isBudgetSufficient, isTrue);

        expect(
          data.remainingBudget,
          greaterThanOrEqualTo(0),
        );

        data.dispose();
      },
    );

    test(
      'reports the shortfall when even the cheapest weekly menu is over budget',
      () async {
        final data = MealMateData();
        await data.load();

        data.setPeople(2);
        data.weeklyBudget = 100000;

        expect(data.weeklyRecipes, hasLength(7));
        expect(data.minimumWeeklyBudget, 105000);
        expect(data.estimatedTotal, 105000);

        expect(data.isBudgetSufficient, isFalse);
        expect(data.budgetShortfall, 5000);

        data.dispose();
      },
    );

    test(
      'changing the number of people recalculates the menu total',
      () async {
        final data = MealMateData();
        await data.load();

        data.weeklyBudget = 300000;
        data.setPeople(2);

        final twoPeopleTotal = data.estimatedTotal;

        data.setPeople(3);

        final threePeopleTotal = data.estimatedTotal;

        expect(twoPeopleTotal, 139000);
        expect(threePeopleTotal, 208500);

        expect(
          threePeopleTotal,
          twoPeopleTotal * 3 ~/ 2,
        );

        data.dispose();
      },
    );

    test(
      'uses the cheapest menu honestly when the budget is below minimum',
      () async {
        final data = MealMateData();
        await data.load();

        data.selectTarget('Seimbang');
        data.setPeople(2);
        data.weeklyBudget = 100000;

        expect(data.weeklyRecipes, hasLength(7));

        expect(
          data.weeklyRecipes.every(
            (recipe) => recipe.name == 'Sup Sayur Telur',
          ),
          isTrue,
        );

        expect(data.minimumWeeklyBudget, 105000);
        expect(data.estimatedTotal, 105000);

        expect(data.isBudgetSufficient, isFalse);
        expect(data.budgetShortfall, 5000);

        data.dispose();
      },
    );

    test(
      'prioritizes recipes that use ingredients already available in the pantry',
      () async {
        final data = MealMateData();
        await data.load();

        data.selectTarget('Seimbang');
        data.addIngredient('Ayam');
        data.addIngredient('Beras');
        data.addIngredient('Kecap');
        data.addIngredient('Bumbu');

        expect(
          data.weeklyRecipes.first.name,
          'Nasi Ayam Kecap',
        );

        data.dispose();
      },
    );

    test(
      'prioritizes recipes with identifiable protein sources for high-protein target',
      () async {
        final data = MealMateData();
        await data.load();

        data.selectTarget('Tinggi Protein');

        final firstRecipe = data.weeklyRecipes.first;
        final firstRecipeIngredients = firstRecipe.ingredients
            .map((ingredient) => ingredient.name.toLowerCase())
            .join(' ');

        expect(
          RegExp(
            r'ayam|bebek|telur|ikan|lele|nila|tuna|salmon|udang|cumi|kerang|sapi|daging|kambing|tahu|tempe|kacang|edamame|kedelai|susu|yogurt|yoghurt|keju',
          ).hasMatch(firstRecipeIngredients),
          isTrue,
        );

        data.dispose();
      },
    );

    test(
      'uses measured protein per serving when all recipes have nutrition data',
      () async {
        const proteinValues = <double>[18, 5, 22, 16, 11, 28, 9];
        final recipesWithNutrition = _testRecipes.asMap().entries.map((entry) {
          final recipe = entry.value;
          return Recipe(
            id: recipe.id,
            name: recipe.name,
            description: recipe.description,
            minutes: recipe.minutes,
            costPerServing: recipe.costPerServing,
            icon: recipe.icon,
            imageUrl: recipe.imageUrl,
            ingredients: recipe.ingredients,
            steps: recipe.steps,
            proteinGramsPerServing: proteinValues[entry.key],
          );
        }).toList(growable: false);

        _setMockPreferences({
          'recipeCatalogCache': jsonEncode(
            recipesWithNutrition.map((recipe) => recipe.toJson()).toList(),
          ),
        });

        final data = MealMateData();
        await data.load();
        data.selectTarget('Tinggi Protein');

        expect(data.weeklyRecipes.first.name, 'Nasi Ayam Panggang');
        expect(
          data.weeklyRecipes.first.proteinGramsPerServing,
          28,
        );

        data.dispose();
      },
    );

    test(
      'does not depend on the order of recipes returned by Supabase',
      () async {
        _setMockPreferences({
          'recipeCatalogCache': jsonEncode(
            _testRecipes.reversed.map((recipe) => recipe.toJson()).toList(),
          ),
        });

        final data = MealMateData();
        await data.load();

        final menu = data.weeklyRecipes;
        final menuNames = menu.map((recipe) => recipe.name).toSet();

        expect(menu, hasLength(7));
        expect(menuNames, hasLength(7));
        expect(menu.first.name, 'Sup Sayur Telur');

        data.dispose();
      },
    );

    test(
      'writes changes to local preferences',
      () async {
        final data = MealMateData();
        await data.load();

        data.setName('FerdyMyla');
        data.weeklyBudget = 425000;
        data.setPeople(3);

        await data.flush();

        final preferences = await SharedPreferences.getInstance();

        expect(preferences.getString('name'), 'FerdyMyla');
        expect(preferences.getInt('weeklyBudget'), 425000);
        expect(preferences.getBool('weeklyBudgetConfigured'), isTrue);
        expect(preferences.getInt('people'), 3);

        data.dispose();
      },
    );

    test(
      'scales and aggregates shopping amounts and prices by people and recipe servings',
      () async {
        final data = MealMateData();
        await data.load();

        data.setPeople(3);
        for (var day = 0; day < 7; day++) {
          data.changeRecipe(day, _testRecipes[0]);
        }

        data.savePlan();
        await data.flush();

        // Resep dasar menghasilkan 2 porsi: 150 g ayam dan Rp14.000.
        // Untuk 3 orang, kebutuhan menjadi 225 g dan Rp21.000 per hari.
        // Menu yang sama selama tujuh hari harus dijumlahkan.
        expect(data.shoppingAmounts['Ayam'], '1575 g');
        expect(data.shoppingPrices['Ayam'], 147000);

        data.dispose();
      },
    );

    test(
      'scales manually added recipe ingredients for the selected number of people',
      () async {
        final data = MealMateData();
        await data.load();

        data.setPeople(3);
        data.addRecipeToShoppingList(_testRecipes[0]);
        await data.flush();

        expect(data.shoppingAmounts['Ayam'], '225 g');
        expect(data.shoppingPrices['Ayam'], 21000);

        data.dispose();
      },
    );

    test(
      'persists shopping quantities alongside shopping prices',
      () async {
        final data = MealMateData();
        await data.load();

        data.setPeople(3);
        data.addRecipeToShoppingList(_testRecipes[0]);
        await data.flush();

        final preferences = await SharedPreferences.getInstance();
        final savedAmounts = jsonDecode(
          preferences.getString('shoppingAmounts')!,
        ) as Map<String, dynamic>;

        expect(savedAmounts['Ayam'], '225 g');
        expect(preferences.getString('shoppingPrices'), contains('Ayam'));

        data.dispose();
      },
    );

    test(
      'shopping category estimates add up exactly to the shopping total',
      () async {
        final data = MealMateData();
        await data.load();

        data.savePlan();
        await data.flush();

        final categoryTotal = data.estimateByCategory.values.fold<int>(
          0,
          (total, value) => total + value,
        );

        expect(categoryTotal, data.shoppingTotal);

        data.dispose();
      },
    );

    test(
      'automatically updates shopping list when a recipe is changed',
      () async {
        final data = MealMateData();
        await data.load();

        data.savePlan();
        await data.flush();

        // Menu rekomendasi hemat tetap memasukkan resep berbahan tahu.
        expect(data.autoShoppingItems, contains('Tahu putih'));

        // Cari hari yang benar-benar memakai tahu, lalu ganti resepnya.
        final tofuDayIndex = data.weeklyRecipes.indexWhere(
          (recipe) => recipe.name == 'Tumis Sayur dan Tahu',
        );
        expect(tofuDayIndex, isNot(-1));

        data.changeRecipe(tofuDayIndex, _testRecipes[5]);

        await data.flush();

        // Bahan lama yang tidak lagi dibutuhkan harus hilang.
        expect(
          data.autoShoppingItems,
          isNot(contains('Tahu putih')),
        );

        // Bahan resep baru harus masuk otomatis.
        expect(
          data.autoShoppingItems,
          contains('Bumbu panggang'),
        );

        expect(
          data.shoppingItems,
          contains('Bumbu panggang'),
        );

        data.dispose();
      },
    );

    test(
      'preserves manually added shopping items when menu changes',
      () async {
        final data = MealMateData();
        await data.load();

        // Tambahkan bahan dari halaman Detail Resep.
        data.addRecipeToShoppingList(_testRecipes[3]);

        data.savePlan();
        await data.flush();

        expect(
          data.manualShoppingItems,
          contains('Tahu putih'),
        );

        // Ganti resep yang sebelumnya menggunakan tahu.
        data.changeRecipe(0, _testRecipes[5]);
        data.changeRecipe(5, _testRecipes[5]);

        await data.flush();

        // Bahan manual tidak boleh ikut terhapus.
        expect(
          data.shoppingItems,
          contains('Tahu putih'),
        );

        expect(
          data.manualShoppingItems,
          contains('Tahu putih'),
        );

        data.dispose();
      },
    );

    test(
      'does not add ingredients already available in pantry',
      () async {
        final data = MealMateData();
        await data.load();

        data.availableIngredients.add('Tahu putih');

        data.savePlan();
        await data.flush();

        expect(
          data.shoppingItems,
          isNot(contains('Tahu putih')),
        );

        expect(
          data.autoShoppingItems,
          isNot(contains('Tahu putih')),
        );

        data.dispose();
      },
    );

    test(
      'keeps manually excluded automatic items out of shopping list',
      () async {
        final data = MealMateData();
        await data.load();

        data.savePlan();
        await data.flush();

        expect(
          data.shoppingItems,
          contains('Tahu putih'),
        );

        // Pengguna menghapus bahan yang masih diperlukan menu.
        data.removeShoppingItem('Tahu putih');
        await data.flush();

        expect(
          data.shoppingItems,
          isNot(contains('Tahu putih')),
        );

        // Sinkronisasi ulang tidak boleh memasukkannya kembali.
        data.addWeeklyMenuToShoppingList();
        await data.flush();

        expect(
          data.shoppingItems,
          isNot(contains('Tahu putih')),
        );

        data.dispose();
      },
    );
  });
}
