class Recipe {
  const Recipe({
    this.id,
    required this.name,
    required this.description,
    required this.minutes,
    required this.costPerServing,
    required this.icon,
    this.servings = 1,
    required this.ingredients,
    required this.steps,
    this.imageUrl,
    this.caloriesKcalPerServing,
    this.proteinGramsPerServing,
    this.carbohydratesGramsPerServing,
    this.fatGramsPerServing,
    this.costEstimateConfidence,
    this.costEstimateBasis,
  });

  final String? id;
  final String name;
  final String description;
  final int minutes;
  final int costPerServing;
  final String icon;
  /// Jumlah porsi yang dihasilkan oleh satu resep pada katalog.
  /// Nilai default 1 menjaga kompatibilitas dengan data resep versi lama.
  final int servings;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final String? imageUrl;

  /// Nilai nutrisi per porsi dari katalog terpercaya.
  /// Null berarti informasi tersebut belum tersedia, bukan bernilai nol.
  final double? caloriesKcalPerServing;
  final double? proteinGramsPerServing;
  final double? carbohydratesGramsPerServing;
  final double? fatGramsPerServing;
  final String? costEstimateConfidence;
  final String? costEstimateBasis;

  bool get hasNutritionData =>
      caloriesKcalPerServing != null ||
      proteinGramsPerServing != null ||
      carbohydratesGramsPerServing != null ||
      fatGramsPerServing != null;

  String get formattedCost => 'Rp${_formatNumber(costPerServing)}';

  String? get imageAsset => switch (name) {
        'Nasi Ayam Teriyaki' => 'assets/images/nasi_ayam_teriyaki.png',
        'Sup Sayur Telur' => 'assets/images/sup_sayur_telur.png',
        _ => null,
      };

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'];
    final rawSteps = json['steps'];

    return Recipe(
      id: json['id']?.toString(),
      name: (json['name'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      minutes: _asInt(json['minutes']),
      costPerServing: _asInt(json['cost_per_serving']),
      icon: (json['icon'] as String? ?? 'restaurant').trim(),
      servings: _positiveInt(json['servings'], 1),
      imageUrl: _nullableString(json['image_url']),
      caloriesKcalPerServing:
          _asNullableNonNegativeDouble(json['calories_kcal_per_serving']),
      proteinGramsPerServing:
          _asNullableNonNegativeDouble(json['protein_g_per_serving']),
      carbohydratesGramsPerServing: _asNullableNonNegativeDouble(
        json['carbohydrates_g_per_serving'],
      ),
      fatGramsPerServing:
          _asNullableNonNegativeDouble(json['fat_g_per_serving']),
      costEstimateConfidence: _nullableString(
        json['cost_estimate_confidence'],
      ),
      costEstimateBasis: _nullableString(json['cost_estimate_basis']),
      ingredients: rawIngredients is List
          ? rawIngredients
              .whereType<Map>()
              .map((item) => RecipeIngredient.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const [],
      steps: rawSteps is List
          ? rawSteps.whereType<String>().toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
        'minutes': minutes,
        'cost_per_serving': costPerServing,
        'icon': icon,
        'servings': servings,
        'image_url': imageUrl,
        'calories_kcal_per_serving': caloriesKcalPerServing,
        'protein_g_per_serving': proteinGramsPerServing,
        'carbohydrates_g_per_serving': carbohydratesGramsPerServing,
        'fat_g_per_serving': fatGramsPerServing,
        'cost_estimate_confidence': costEstimateConfidence,
        'cost_estimate_basis': costEstimateBasis,
        'ingredients': ingredients.map((item) => item.toJson()).toList(),
        'steps': steps,
      };
}

class RecipeIngredient {
  const RecipeIngredient(this.name, this.amount, this.price);

  final String name;
  final String amount;
  final int price;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        (json['name'] as String? ?? '').trim(),
        (json['amount'] as String? ?? '').trim(),
        _asInt(json['price']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'price': price,
      };
}

int _positiveInt(dynamic value, int fallback) {
  final parsed = _asInt(value);
  return parsed > 0 ? parsed : fallback;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asNullableNonNegativeDouble(dynamic value) {
  if (value == null) return null;

  final parsed = value is num
      ? value.toDouble()
      : double.tryParse(value.toString().trim());

  if (parsed == null || !parsed.isFinite || parsed < 0) return null;
  return parsed;
}

String? _nullableString(dynamic value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

String _formatNumber(int value) => value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
