import 'package:flutter/material.dart';

import '../data/meal_mate_data.dart';
import '../models/recipe.dart';
import '../theme/app_theme.dart';
import '../utils/ingredient_quantity.dart';
import '../widgets/app_widgets.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({
    super.key,
    required this.data,
    required this.recipe,
  });
  final MealMateData data;
  final Recipe recipe;

  int get _recipeServings => recipe.servings > 0 ? recipe.servings : 1;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Detail Resep')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 25),
            children: [
              Container(
                height: 190,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E0D0),
                  borderRadius: BorderRadius.circular(17),
                ),
                clipBehavior: Clip.antiAlias,
                child: recipe.imageUrl != null
                    ? Image.network(
                        recipe.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          _iconFor(recipe),
                          size: 90,
                          color: AppColors.green,
                        ),
                      )
                    : recipe.imageAsset == null
                        ? Icon(_iconFor(recipe), size: 90, color: AppColors.green)
                        : Image.asset(
                            recipe.imageAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              _iconFor(recipe),
                              size: 90,
                              color: AppColors.green,
                            ),
                          ),
              ),
              const SizedBox(height: 16),
              Text(
                recipe.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                recipe.description,
                style: const TextStyle(
                  color: AppColors.muted,
                  height: 1.4,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              SurfaceCard(
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 14,
                  runSpacing: 10,
                  children: [
                    _InfoItem(
                      icon: Icons.schedule,
                      label: '${recipe.minutes} menit',
                    ),
                    _InfoItem(
                      icon: Icons.restaurant_outlined,
                      label: 'Resep $_recipeServings porsi',
                    ),
                    _InfoItem(
                      icon: Icons.people_outline,
                      label: 'Butuh ${data.people} porsi',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              HintCard(
                title: recipe.costEstimateConfidence == null
                    ? 'Estimasi biaya'
                    : 'Estimasi biaya · ${_confidenceLabel(recipe.costEstimateConfidence!)}',
                message: [
                  '${recipe.formattedCost} / porsi  ·  Total ${formatRupiah(recipe.costPerServing * data.people)} untuk ${data.people} porsi.',
                  if (recipe.costEstimateBasis != null)
                    recipe.costEstimateBasis!,
                ].join(' '),
              ),
              const SizedBox(height: 12),
              _NutritionCard(recipe: recipe),
              const SizedBox(height: 19),
              SectionTitle(
                'Bahan untuk ${data.people} porsi dan estimasi harga',
              ),
              ...recipe.ingredients.map(
                (ingredient) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: AppColors.green),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '${ingredient.name} · ${IngredientQuantityAccumulator.scaleAmount(
                            ingredient.amount,
                            multiplier: data.people / _recipeServings,
                          )}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        formatRupiah(
                          (ingredient.price * data.people / _recipeServings)
                              .round(),
                        ),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 23),
              const SectionTitle('Langkah memasak'),
              ...recipe.steps.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.paleGreen,
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style:
                                  const TextStyle(fontSize: 12, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 9),
              PrimaryButton(
                label: 'Tambahkan Bahan ke Daftar Belanja',
                icon: Icons.add_shopping_cart,
                onPressed: () {
                  data.addRecipeToShoppingList(recipe);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Bahan resep ditambahkan ke daftar belanja.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    if (!recipe.hasNutritionData) {
      return const HintCard(
        title: 'Informasi nutrisi belum tersedia',
        message:
            'Katalog belum menyediakan data nutrisi per porsi untuk resep ini. MealMate tidak menampilkan angka perkiraan yang belum tervalidasi.',
      );
    }

    final items = <(String, String)>[];

    void addValue(String label, double? value, String unit) {
      if (value == null) return;
      final formatted = value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(1);
      items.add((label, '$formatted $unit'));
    }

    addValue('Kalori', recipe.caloriesKcalPerServing, 'kkal');
    addValue('Protein', recipe.proteinGramsPerServing, 'g');
    addValue('Karbohidrat', recipe.carbohydratesGramsPerServing, 'g');
    addValue('Lemak', recipe.fatGramsPerServing, 'g');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Informasi nutrisi per porsi'),
        SurfaceCard(
          child: Wrap(
            spacing: 20,
            runSpacing: 14,
            children: items
                .map(
                  (item) => SizedBox(
                    width: 115,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.green),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      );
}

String _confidenceLabel(String value) {
  switch (value.toLowerCase()) {
    case 'high':
      return 'tinggi';
    case 'medium':
      return 'sedang';
    case 'low':
      return 'rendah';
    default:
      return value;
  }
}

IconData _iconFor(Recipe recipe) => switch (recipe.icon) {
      'soup_kitchen' => Icons.soup_kitchen,
      'rice_bowl' => Icons.rice_bowl,
      'eco' => Icons.eco,
      'egg_alt' => Icons.egg_alt,
      'outdoor_grill' => Icons.outdoor_grill,
      'ramen_dining' => Icons.ramen_dining,
      _ => Icons.restaurant,
    };
