import 'package:flutter_test/flutter_test.dart';
import 'package:mealmate/models/recipe.dart';

void main() {
  group('Recipe.fromJson', () {
    test('maps a Supabase recipe row and nested JSON fields', () {
      final recipe = Recipe.fromJson({
        'id': '6b731304-831b-4ad3-b82d-69caa0b7f825',
        'name': 'Sup Sayur Telur',
        'description': 'Sup sederhana.',
        'minutes': 25,
        'cost_per_serving': 7500,
        'icon': 'egg_alt',
        'image_url': 'https://example.invalid/sup.png',
        'ingredients': [
          {'name': 'Telur', 'amount': '1 butir', 'price': 2500},
        ],
        'steps': ['Didihkan air.', 'Masukkan telur.'],
      });

      expect(recipe.name, 'Sup Sayur Telur');
      expect(recipe.servings, 1);
      expect(recipe.costPerServing, 7500);
      expect(recipe.imageUrl, 'https://example.invalid/sup.png');
      expect(recipe.ingredients, hasLength(1));
      expect(recipe.ingredients.single.name, 'Telur');
      expect(recipe.steps, hasLength(2));
    });

    test('parses and serializes per-serving nutrition values', () {
      final recipe = Recipe.fromJson({
        'name': 'Menu Bernutrisi',
        'description': 'Data nutrisi per porsi.',
        'minutes': 30,
        'cost_per_serving': 15000,
        'icon': 'restaurant',
        'ingredients': const [],
        'steps': const [],
        'calories_kcal_per_serving': 420,
        'protein_g_per_serving': 28.5,
        'carbohydrates_g_per_serving': '52.0',
        'fat_g_per_serving': 12,
      });

      expect(recipe.hasNutritionData, isTrue);
      expect(recipe.caloriesKcalPerServing, 420.0);
      expect(recipe.proteinGramsPerServing, 28.5);
      expect(recipe.carbohydratesGramsPerServing, 52.0);
      expect(recipe.fatGramsPerServing, 12.0);

      final json = recipe.toJson();
      expect(json['protein_g_per_serving'], 28.5);
      expect(json['calories_kcal_per_serving'], 420.0);
    });

    test('keeps missing or invalid nutrition as unavailable', () {
      final recipe = Recipe.fromJson({
        'name': 'Resep Lama',
        'description': 'Belum memiliki data nutrisi.',
        'minutes': 20,
        'cost_per_serving': 8500,
        'icon': 'restaurant',
        'ingredients': const [],
        'steps': const [],
        'protein_g_per_serving': -5,
        'fat_g_per_serving': 'bukan angka',
      });

      expect(recipe.hasNutritionData, isFalse);
      expect(recipe.proteinGramsPerServing, isNull);
      expect(recipe.fatGramsPerServing, isNull);
    });

    test('parses the recipe batch yield and cost estimate metadata', () {
      final recipe = Recipe.fromJson({
        'name': 'Ayam untuk Keluarga',
        'description': 'Resep dengan hasil beberapa porsi.',
        'minutes': 35,
        'cost_per_serving': 12000,
        'icon': 'restaurant',
        'servings': 4,
        'cost_estimate_confidence': 'medium',
        'cost_estimate_basis': 'Estimasi internal, bukan harga pasar real-time.',
        'ingredients': const [],
        'steps': const [],
      });

      expect(recipe.servings, 4);
      expect(recipe.costEstimateConfidence, 'medium');
      expect(
        recipe.costEstimateBasis,
        'Estimasi internal, bukan harga pasar real-time.',
      );
      expect(recipe.toJson()['servings'], 4);
    });

    test('handles nullable image and numeric values from JSON', () {
      final recipe = Recipe.fromJson({
        'name': 'Resep Tes',
        'description': 'Tes parsing.',
        'minutes': 20.0,
        'cost_per_serving': '8500',
        'icon': 'restaurant',
        'image_url': null,
        'ingredients': const [],
        'steps': const [],
      });

      expect(recipe.minutes, 20);
      expect(recipe.costPerServing, 8500);
      expect(recipe.imageUrl, isNull);
      expect(recipe.ingredients, isEmpty);
      expect(recipe.steps, isEmpty);
    });
  });
}
