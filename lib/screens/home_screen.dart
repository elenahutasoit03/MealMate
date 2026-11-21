import 'package:flutter/material.dart';

import '../data/meal_mate_data.dart';
import '../models/recipe.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'meal_plan_screen.dart';
import 'generating_screen.dart';
import 'recipe_detail_screen.dart';
import 'shopping_list_screen.dart';
import 'profile_screen.dart';
import 'setup_screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.data});
  final MealMateData data;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homeBody(),
      MealPlanScreen(
        data: widget.data,
        embedded: true,
        onBudgetRequired: _openBudget,
      ),
      ShoppingListScreen(data: widget.data, embedded: true),
      ProfileScreen(data: widget.data, embedded: true),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Meal Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_basket_outlined),
            label: 'Belanja',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _homeBody() => AnimatedBuilder(
        animation: widget.data,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.data.name.trim().isEmpty
                        ? 'Halo!'
                        : 'Halo, ${widget.data.name}!',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
                const CircleAvatar(
                  backgroundColor: AppColors.paleGreen,
                  child: Icon(Icons.person, color: AppColors.green),
                ),
              ],
            ),
            const SizedBox(height: 13),
            const Text(
              'Atur menu mingguan\ndengan lebih mudah.',
              style: TextStyle(
                fontSize: 25,
                height: 1.15,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 17),
            _weeklyBanner(),
            const SizedBox(height: 19),
            SectionTitle(
              widget.data.name.trim().isEmpty
                  ? 'Anggaran minggu ini'
                  : '${widget.data.name}, anggaran minggu ini',
              action:
                  widget.data.hasWeeklyBudget ? 'Ubah budget' : 'Atur budget',
              onAction: _openBudget,
            ),
            SurfaceCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Batas anggaran',
                          style:
                              TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                        Text(
                          widget.data.hasWeeklyBudget
                              ? formatRupiah(widget.data.weeklyBudget)
                              : 'Belum diatur',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _openBudget,
                    icon:
                        const Icon(Icons.edit_outlined, color: AppColors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 19),
            const SectionTitle('Rekomendasi Resep'),
            Row(
              children: [
                Expanded(child: _recipeCard(widget.data.recipeCatalog[0])),
                const SizedBox(width: 10),
                Expanded(child: _recipeCard(widget.data.recipeCatalog[4])),
              ],
            ),
            const SizedBox(height: 19),
            SectionTitle(
              'Meal Plan Mingguan',
              action: 'Lihat semua',
              onAction: () => setState(() => _tab = 1),
            ),
            SurfaceCard(
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: AppColors.green),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Susun menu untuk 7 hari\nAtur budget, pilih bahan, dan lihat rekomendasi.',
                      style: TextStyle(height: 1.45),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _tab = 1),
                    icon:
                        const Icon(Icons.arrow_forward, color: AppColors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const HintCard(
              title: 'Belanja lebih terencana',
              message:
                  'Manfaatkan bahan yang tersedia dan kurangi makanan terbuang.',
              color: AppColors.peach,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tentang MealMate',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'Perencana menu mingguan berdasarkan budget dan bahan yang tersedia.',
              style:
                  TextStyle(color: AppColors.muted, height: 1.4, fontSize: 12),
            ),
          ],
        ),
      );

  Widget _weeklyBanner() => InkWell(
        onTap: _openBudget,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MENU MINGGUAN',
                      style: TextStyle(
                        color: AppColors.paleGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Rencanakan Menu.\nLebih Hemat.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Menu sesuai budget dan bahan yang tersedia.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Buat rencana menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFFFE4C7),
                child: Icon(Icons.restaurant, color: AppColors.green, size: 28),
              ),
            ],
          ),
        ),
      );

  Widget _recipeCard(Recipe recipe) => InkWell(
        onTap: () => _openRecipe(recipe),
        borderRadius: BorderRadius.circular(14),
        child: SurfaceCard(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 76,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.paleGreen,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: recipe.imageUrl != null
                      ? Image.network(
                          recipe.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            _recipeIcon(recipe),
                            color: AppColors.green,
                            size: 38,
                          ),
                        )
                      : recipe.imageAsset == null
                          ? Icon(_recipeIcon(recipe),
                              color: AppColors.green, size: 38)
                          : Image.asset(
                              recipe.imageAsset!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                _recipeIcon(recipe),
                                color: AppColors.green,
                                size: 38,
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                recipe.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              Text(
                '${recipe.minutes} mnt | ${recipe.formattedCost}/porsi',
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ],
          ),
        ),
      );

  void _openBudget() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetScreen(data: widget.data, onContinue: _openSetup),
      ),
    );
  }

  void _openSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            IngredientScreen(data: widget.data, onContinue: _openTarget),
      ),
    );
  }

  void _openTarget() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TargetScreen(data: widget.data, onContinue: _openPlan),
      ),
    );
  }

  void _openPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GeneratingScreen(data: widget.data)),
    );
  }

  void _openRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(data: widget.data, recipe: recipe),
      ),
    );
  }
}

IconData _recipeIcon(Recipe recipe) => switch (recipe.icon) {
      'soup_kitchen' => Icons.soup_kitchen,
      'rice_bowl' => Icons.rice_bowl,
      'eco' => Icons.eco,
      'egg_alt' => Icons.egg_alt,
      'outdoor_grill' => Icons.outdoor_grill,
      'ramen_dining' => Icons.ramen_dining,
      _ => Icons.restaurant,
    };
