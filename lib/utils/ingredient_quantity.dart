/// Utility untuk menormalkan dan menggabungkan takaran bahan resep.
///
/// Hanya satuan yang dikenal yang dihitung secara numerik. Takaran yang tidak
/// dapat dipastikan tetap ditampilkan sebagai catatan, bukan ditebak.
class IngredientQuantityAccumulator {
  final Map<String, double> _totals = <String, double>{};
  final Map<String, int> _notes = <String, int>{};

  /// Menambahkan takaran resep yang dikalikan [multiplier].
  ///
  /// [groupedIngredient] digunakan ketika satu takaran pada sumber berlaku
  /// untuk beberapa nama bahan sekaligus, misalnya "Wortel dan buncis: 100 g".
  /// Jumlah tersebut tidak dibagi rata karena proporsinya tidak diketahui.
  void add(
    String amount, {
    double multiplier = 1,
    bool groupedIngredient = false,
  }) {
    final cleaned = amount.trim();
    if (cleaned.isEmpty) return;

    final parsed = _parseAmount(cleaned);
    if (parsed == null) {
      final note = _normalizeNote(cleaned, multiplier);
      _notes.update(note, (count) => count + 1, ifAbsent: () => 1);
      return;
    }

    final scaledValue = parsed.value * multiplier;
    if (!scaledValue.isFinite || scaledValue < 0) return;

    if (groupedIngredient) {
      final note = '${_formatValue(scaledValue)} ${parsed.canonicalUnit} '
          '(takaran gabungan)';
      _notes.update(note, (count) => count + 1, ifAbsent: () => 1);
      return;
    }

    _totals.update(
      parsed.canonicalUnit,
      (current) => current + scaledValue,
      ifAbsent: () => scaledValue,
    );
  }

  /// Label ringkas yang aman ditampilkan di Daftar Belanja.
  String? get label {
    final parts = <String>[];

    for (final entry in _totals.entries) {
      if (entry.value <= 0) continue;
      parts.add(
        '${_formatValue(entry.value)} ${entry.key}',
      );
    }

    for (final entry in _notes.entries) {
      final suffix = entry.value > 1 ? ' × ${entry.value} resep' : '';
      parts.add('${entry.key}$suffix');
    }

    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }

  /// Menghasilkan takaran satu bahan untuk tampilan Detail Resep.
  static String scaleAmount(String amount, {double multiplier = 1}) {
    final accumulator = IngredientQuantityAccumulator()
      ..add(amount, multiplier: multiplier);
    return accumulator.label ?? amount.trim();
  }

  static _ParsedIngredientAmount? _parseAmount(String value) {
    final match = RegExp(
      r'^\s*(\d+(?:[.,]\d+)?|\d+\s*/\s*\d+)\s*'
      r'(kg|kilogram|ons|g|gr|gram|ml|mililiter|l|ltr|liter|'
      r'sdm|sdt|sendok makan|sendok teh|'
      r'buah|bh|butir|btr|siung|lembar|batang|ruas|'
      r'bungkus kecil|bungkus|bgks|bks|papan|porsi|potong|ikat|ekor|lonjor|cm)'
      r'(?:\s*[x×]\s*(\d+(?:[.,]\d+)?|\d+\s*/\s*\d+)\s*'
      r'(?:porsi|orang)?)?\s*$',
      caseSensitive: false,
    ).firstMatch(value);

    if (match == null) return null;

    var quantity = _parseNumber(match.group(1)!);
    final rawUnit = match.group(2)!.toLowerCase();
    final multiplierText = match.group(3);
    if (multiplierText != null) {
      quantity *= _parseNumber(multiplierText);
    }

    var canonicalUnit = rawUnit;

    if (['kg', 'kilogram'].contains(rawUnit)) {
      canonicalUnit = 'g';
      quantity *= 1000;
    } else if (rawUnit == 'ons') {
      canonicalUnit = 'g';
      quantity *= 100;
    } else if (['g', 'gr', 'gram'].contains(rawUnit)) {
      canonicalUnit = 'g';
    } else if (['l', 'ltr', 'liter'].contains(rawUnit)) {
      canonicalUnit = 'ml';
      quantity *= 1000;
    } else if (['ml', 'mililiter'].contains(rawUnit)) {
      canonicalUnit = 'ml';
    } else if (['bh'].contains(rawUnit)) {
      canonicalUnit = 'buah';
    } else if (['btr'].contains(rawUnit)) {
      canonicalUnit = 'butir';
    } else if (['bgks', 'bks', 'bungkus kecil'].contains(rawUnit)) {
      canonicalUnit = 'bungkus';
    } else if (rawUnit == 'sendok makan') {
      canonicalUnit = 'sdm';
    } else if (rawUnit == 'sendok teh') {
      canonicalUnit = 'sdt';
    }

    if (quantity <= 0 || !quantity.isFinite) return null;

    return _ParsedIngredientAmount(
      value: quantity,
      canonicalUnit: canonicalUnit,
    );
  }

  static double _parseNumber(String value) {
    final cleaned = value.replaceAll(' ', '').replaceAll(',', '.');
    if (cleaned.contains('/')) {
      final parts = cleaned.split('/');
      if (parts.length == 2) {
        final numerator = double.tryParse(parts[0]);
        final denominator = double.tryParse(parts[1]);
        if (numerator != null && denominator != null && denominator != 0) {
          return numerator / denominator;
        }
      }
    }
    return double.tryParse(cleaned) ?? 0;
  }

  static String _normalizeNote(String value, double multiplier) {
    final lower = value.toLowerCase();
    if (lower.contains('secukupnya') || lower.contains('sesuai selera')) {
      return 'Secukupnya';
    }
    if (lower.contains('sesuai sumber')) return 'Sesuai sumber';

    final trimmed = value.trim();
    if (multiplier == 1) return trimmed;
    return '$trimmed (takaran resep asli; skala porsi tidak tersedia)';
  }

  static String _formatValue(double value) {
    final normalized = value.abs() < 0.000001 ? 0.0 : value;
    if ((normalized - normalized.roundToDouble()).abs() < 0.000001) {
      return normalized.round().toString();
    }

    return normalized
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '')
        .replaceAll('.', ',');
  }
}

class _ParsedIngredientAmount {
  const _ParsedIngredientAmount({
    required this.value,
    required this.canonicalUnit,
  });

  final double value;
  final String canonicalUnit;
}
