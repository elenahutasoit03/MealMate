class MealPlanRecord {
  const MealPlanRecord({
    required this.createdAt,
    required this.target,
    required this.people,
    required this.budget,
    required this.total,
    required this.recipeNames,
  });

  final DateTime createdAt;
  final String target;
  final int people;
  final int budget;
  final int total;
  final List<String> recipeNames;

  Map<String, Object?> toJson() => {
        'createdAt': createdAt.toIso8601String(),
        'target': target,
        'people': people,
        'budget': budget,
        'total': total,
        'recipeNames': recipeNames,
      };

  factory MealPlanRecord.fromJson(Map<String, dynamic> json) => MealPlanRecord(
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        target: json['target'] as String? ?? 'Hemat',
        people: json['people'] as int? ?? 2,
        budget: json['budget'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        recipeNames:
            (json['recipeNames'] as List<dynamic>? ?? const []).cast<String>(),
      );
}
