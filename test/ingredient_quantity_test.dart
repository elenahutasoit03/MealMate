import 'package:flutter_test/flutter_test.dart';
import 'package:mealmate/utils/ingredient_quantity.dart';

void main() {
  group('IngredientQuantityAccumulator', () {
    test('combines equivalent metric units', () {
      final quantity = IngredientQuantityAccumulator()
        ..add('1 kg')
        ..add('250 gram');

      expect(quantity.label, '1250 g');
    });

    test('supports fractions and explicit recipe serving multipliers', () {
      final quantity = IngredientQuantityAccumulator()
        ..add('1/2 ons')
        ..add('100 g × 3 porsi', multiplier: 0.5);

      expect(quantity.label, '200 g');
    });

    test('marks quantities shared by multiple ingredient names', () {
      final quantity = IngredientQuantityAccumulator()
        ..add('100 g', multiplier: 1.5, groupedIngredient: true)
        ..add('100 g', multiplier: 1.5, groupedIngredient: true);

      expect(quantity.label, '150 g (takaran gabungan) × 2 resep');
    });

    test('keeps vague and unsupported amounts transparent', () {
      final quantity = IngredientQuantityAccumulator()
        ..add('secukupnya', multiplier: 2)
        ..add('Secukupnya', multiplier: 3)
        ..add('3-4 sdm', multiplier: 2);

      expect(
        quantity.label,
        'Secukupnya × 2 resep • '
        '3-4 sdm (takaran resep asli; skala porsi tidak tersedia)',
      );
    });
  });
}
