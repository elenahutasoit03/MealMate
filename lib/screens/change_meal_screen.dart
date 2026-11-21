
import 'package:flutter/material.dart';

import '../data/meal_mate_data.dart';
import '../models/recipe.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class ChangeMealScreen extends StatefulWidget {
  const ChangeMealScreen({
    super.key,
    required this.data,
    required this.dayIndex,
  });

  final MealMateData data;
  final int dayIndex;

  @override
  State<ChangeMealScreen> createState() => _ChangeMealScreenState();
}

class _ChangeMealScreenState extends State<ChangeMealScreen> {
  late Recipe selected;

  static const List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  @override
  void initState() {
    super.initState();
    selected = widget.data.weeklyRecipes[widget.dayIndex];
  }

  @override
  Widget build(BuildContext context) {
    final dayIndex = widget.dayIndex.clamp(0, _days.length - 1).toInt();
    final day = _days[dayIndex];
    final recipes = widget.data.recipeCatalog;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganti Menu'),
      ),
      body: RadioGroup<Recipe>(
        groupValue: selected,
        onChanged: (value) {
          if (value != null) {
            setState(() => selected = value);
          }
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          itemCount: recipes.length + 8,
          itemBuilder: (context, index) {
            // Header
            if (index == 0) {
              return const Text(
                'MEALMATE',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              );
            }

            if (index == 1) {
              return const SizedBox(height: 7);
            }

            // Title
            if (index == 2) {
              return Text(
                'Ganti menu $day',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              );
            }

            if (index == 3) {
              return const SizedBox(height: 5);
            }

            // Description
            if (index == 4) {
              return const Text(
                'Pilih menu lain yang sesuai selera dan budget.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              );
            }

            if (index == 5) {
              return const SizedBox(height: 16);
            }

            // Recipe list: build only visible items
            final recipeIndex = index - 6;

            if (recipeIndex >= 0 && recipeIndex < recipes.length) {
              final recipe = recipes[recipeIndex];

              return Padding(
                key: ValueKey(
                  'change-meal-${recipe.id ?? recipe.name}',
                ),
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() => selected = recipe);
                  },
                  borderRadius: BorderRadius.circular(13),
                  child: SurfaceCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _RecipeThumbnail(recipe: recipe),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${recipe.minutes} menit | '
                                '${recipe.formattedCost} / porsi',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Radio<Recipe>(
                          value: recipe,
                          activeColor: AppColors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Bottom spacing
            if (recipeIndex == recipes.length) {
              return const SizedBox(height: 10);
            }

            // Apply selected menu
            return PrimaryButton(
              label: 'Gunakan Menu Ini',
              icon: Icons.check,
              onPressed: () {
                widget.data.changeRecipe(widget.dayIndex, selected);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }
}

class _RecipeThumbnail extends StatelessWidget {
  const _RecipeThumbnail({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final imageUrl = recipe.imageUrl;
    final imageAsset = recipe.imageAsset;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.paleGreen,
        borderRadius: BorderRadius.circular(11),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _placeholder(isLoading: true);
              },
              errorBuilder: (context, error, stackTrace) {
                return _placeholder();
              },
            )
          : imageAsset != null
              ? Image.asset(
                  imageAsset,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _placeholder();
                  },
                )
              : _placeholder(),
    );
  }

  Widget _placeholder({bool isLoading = false}) {
    if (isLoading) {
      return const Center(
        child: SizedBox(
          width: 19,
          height: 19,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.green,
          ),
        ),
      );
    }

    return Center(
      child: Icon(
        _iconForRecipe(recipe),
        color: AppColors.green,
        size: 27,
      ),
    );
  }
}

IconData _iconForRecipe(Recipe recipe) => switch (recipe.icon) {
      'soup_kitchen' => Icons.soup_kitchen,
      'rice_bowl' => Icons.rice_bowl,
      'eco' => Icons.eco,
      'egg_alt' => Icons.egg_alt,
      'outdoor_grill' => Icons.outdoor_grill,
      'ramen_dining' => Icons.ramen_dining,
      _ => Icons.restaurant,
    };
