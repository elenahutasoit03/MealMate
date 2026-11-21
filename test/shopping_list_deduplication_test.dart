
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mealmate/data/meal_mate_data.dart';
import 'package:mealmate/models/recipe.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shopping List ingredient deduplication', () {
    test('merges equivalent ingredients from seven recipes', () async {
      final recipes = _buildRecipes();
      _seedPreferences(recipes);

      final data = MealMateData();
      await data.load();
      await data.flush();

      expect(data.shoppingItems, {
        'Air',
        'Minyak goreng',
        'Garam',
        'Air asam jawa',
        'Minyak wijen',
      });

      expect(data.shoppingItems, hasLength(5));

      data.dispose();
    });

    test('recognizes equivalent ingredients already available in pantry',
        () async {
      final recipes = _buildRecipes();

      _seedPreferences(
        recipes,
        availableIngredients: [
          'air matang',
          'minyak sayur',
        ],
      );

      final data = MealMateData();
      await data.load();
      await data.flush();

      expect(data.shoppingItems, {
        'Garam',
        'Air asam jawa',
        'Minyak wijen',
      });

      data.dispose();
    });

    test('preserves checked status after ingredient normalization', () async {
      final recipes = _buildRecipes();

      _seedPreferences(
        recipes,
        checkedShoppingItems: [
          'secukupnya Air',
          'Minyak untuk menumis',
        ],
      );

      final data = MealMateData();
      await data.load();
      await data.flush();

      expect(data.checkedShoppingItems, {
        'Air',
        'Minyak goreng',
      });

      data.dispose();
    });

    test('manual recipe ingredients do not create duplicates', () async {
      final recipes = _buildRecipes();
      _seedPreferences(recipes);

      final data = MealMateData();
      await data.load();

      data.addRecipeToShoppingList(recipes[1]);
      await data.flush();

      expect(data.shoppingItems, hasLength(5));
      expect(data.shoppingItems, contains('Air'));
      expect(data.shoppingItems, contains('Minyak goreng'));
      expect(data.shoppingItems, contains('Garam'));

      data.dispose();
    });
  });
}

List<Recipe> _buildRecipes() {
  final ingredientSets = <List<RecipeIngredient>>[
    const [
      RecipeIngredient('Air', 'secukupnya', 100),
      RecipeIngredient('Minyak goreng', '1 sdm', 2000),
      RecipeIngredient('Garam secukupnya', 'secukupnya', 500),
      RecipeIngredient('Air asam jawa', '1 sdm', 1000),
      RecipeIngredient('Minyak wijen', '1 sdt', 1000),
    ],
    const [
      RecipeIngredient('secukupnya Air', 'secukupnya', 100),
      RecipeIngredient('Minyak untuk menumis', '1 sdm', 2000),
      RecipeIngredient('Garam', 'secukupnya', 500),
    ],
    const [
      RecipeIngredient('Air untuk merebus mie', '1 liter', 100),
      RecipeIngredient('Minyak goreng secukupnya', '1 sdm', 2000),
    ],
  ];

  return List.generate(7, (index) {
    return Recipe(
      id: 'dedup-${index + 1}',
      name: 'Menu Uji ${index + 1}',
      description: 'Resep untuk pengujian daftar belanja.',
      minutes: 20,
      costPerServing: 10000,
      icon: 'restaurant',
      ingredients: index < ingredientSets.length
          ? ingredientSets[index]
          : const <RecipeIngredient>[],
      steps: const [],
    );
  });
}

void _seedPreferences(
  List<Recipe> recipes, {
  List<String> availableIngredients = const [],
  List<String> checkedShoppingItems = const [],
}) {
  SharedPreferences.setMockInitialValues({
    'recipeCatalogCache': jsonEncode(
      recipes.map((recipe) => recipe.toJson()).toList(),
    ),
    'weeklyMenu': recipes.map((recipe) => recipe.name).toList(),
    'planSaved': true,
    'ingredients': availableIngredients,
    'availableIngredients': availableIngredients,
    'shoppingItems': <String>[],
    'manualShoppingItems': <String>[],
    'autoShoppingItems': <String>[],
    'excludedAutoShoppingItems': <String>[],
    'checkedShoppingItems': checkedShoppingItems,
    'shoppingPrices': '{}',
    'mealHistory': '[]',
  });
}
