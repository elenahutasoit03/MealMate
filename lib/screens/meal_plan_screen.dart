import 'package:flutter/material.dart';

import '../data/meal_mate_data.dart';
import '../models/recipe.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'recipe_detail_screen.dart';
import 'cost_estimate_screen.dart';
import 'change_meal_screen.dart';
import 'plan_confirmation_screen.dart';
import 'shopping_list_screen.dart';

class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({
    super.key,
    required this.data,
    this.embedded = false,
    this.onBudgetRequired,
  });

  final MealMateData data;
  final bool embedded;
  final VoidCallback? onBudgetRequired;

  @override
  Widget build(BuildContext context) {
    final body = AnimatedBuilder(
      animation: data,
      builder: (context, _) {
        if (!data.hasWeeklyBudget) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const Text(
                'MINGGUAN',
                style: TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Rencana Menu 7 Hari',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 18),
              SurfaceCard(
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 42,
                      color: AppColors.green,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Atur anggaran terlebih dahulu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Masukkan batas anggaran mingguan agar MealMate bisa menyusun rekomendasi menu sesuai kemampuanmu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Isi Batas Anggaran',
                      icon: Icons.edit_outlined,
                      onPressed: onBudgetRequired,
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              embedded ? 'MINGGUAN' : 'MEAL PLAN',
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: .5,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Rencana Menu 7 Hari',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Menu ${data.target.toLowerCase()} untuk ${data.people} orang, disusun sesuai budget dan bahanmu.',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 17),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CostEstimateScreen(data: data))),
              child: SurfaceCard(
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        color: AppColors.green, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimasi biaya menu',
                            style:
                                TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                          Text(
                            formatRupiah(data.estimatedTotal),
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Sisa budget',
                          style:
                              TextStyle(fontSize: 10, color: AppColors.muted),
                        ),
                        Text(
                          formatRupiah(data.remainingBudget),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: data.remainingBudget >= 0
                                ? AppColors.green
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 7),
                    const Icon(Icons.chevron_right, color: AppColors.green),
                  ],
                ),
              ),
            ),
            if (!data.isBudgetSufficient) ...[
              const SizedBox(height: 12),
              HintCard(
                title: 'Budget belum mencukupi',
                message:
                    'Estimasi menu melebihi anggaran sebesar ${formatRupiah(data.budgetShortfall)}. Naikkan budget atau ganti beberapa resep dengan pilihan yang lebih hemat.',
              ),
            ],
            const SizedBox(height: 19),
            const SectionTitle('Menu minggu ini'),
            ...List.generate(
              data.weeklyRecipes.length,
              (index) => _DayRecipeCard(
                index: index,
                recipe: data.weeklyRecipes[index],
                onTap: () => _openRecipe(context, data.weeklyRecipes[index]),
                onChange: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ChangeMealScreen(data: data, dayIndex: index))),
              ),
            ),
            const SizedBox(height: 7),
            HintCard(
              title: 'Bahan tersedia',
              message: data.availableIngredients.isEmpty
                  ? 'Tambahkan bahan di rumah agar rencana menu semakin sesuai.'
                  : 'Menu ini akan memanfaatkan ${data.availableIngredients.take(4).join(', ')} yang sudah tersedia.',
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: () => _sharePlan(context, data),
              icon: const Icon(Icons.ios_share),
              label: const Text('Bagikan rencana menu'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.green),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                data.addWeeklyMenuToShoppingList();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ShoppingListScreen(data: data)));
              },
              icon: const Icon(Icons.shopping_basket_outlined),
              label: const Text('Tambahkan Bahan Menu ke Daftar Belanja'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.green),
            ),
            const SizedBox(height: 9),
            PrimaryButton(
              label: 'Simpan & Selesaikan Meal Plan',
              icon: Icons.check,
              onPressed: () {
                data.savePlan();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PlanConfirmationScreen(data: data)));
              },
            ),
          ],
        );
      },
    );
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Plan')),
      body: SafeArea(child: body),
    );
  }

  void _openRecipe(BuildContext context, Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(data: data, recipe: recipe),
      ),
    );
  }

  void _sharePlan(BuildContext context, MealMateData data) {
    final text = data.weeklyRecipes
        .asMap()
        .entries
        .map((entry) => '${_days[entry.key]}: ${entry.value.name}')
        .join('\n');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rencana menu siap dibagikan'),
        content: SelectableText(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

class _DayRecipeCard extends StatelessWidget {
  const _DayRecipeCard({
    required this.index,
    required this.recipe,
    required this.onTap,
    required this.onChange,
  });
  final int index;
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: SurfaceCard(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: AppColors.paleGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      _days[index].substring(0, 3).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: recipe.imageUrl != null
                      ? Image.network(
                          recipe.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            _iconFor(recipe),
                            color: AppColors.green,
                          ),
                        )
                      : recipe.imageAsset == null
                          ? Icon(_iconFor(recipe), color: AppColors.green)
                          : Image.asset(
                              recipe.imageAsset!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                _iconFor(recipe),
                                color: AppColors.green,
                              ),
                            ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${recipe.minutes} menit  ·  ${recipe.formattedCost} / porsi',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                    tooltip: 'Ganti menu',
                    onPressed: onChange,
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.green, size: 19)),
              ],
            ),
          ),
        ),
      );
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
