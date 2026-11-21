
import 'package:flutter/material.dart';

import '../data/meal_mate_data.dart';
import '../models/meal_plan_record.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class MealHistoryScreen extends StatelessWidget {
  const MealHistoryScreen({
    super.key,
    required this.data,
    this.embedded = false,
  });

  final MealMateData data;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final body = AnimatedBuilder(
      animation: data,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text(
            'MEALMATE',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Riwayat Meal Plan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Menu mingguan yang pernah kamu simpan.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          if (data.history.isEmpty)
            const HintCard(
              title: 'Belum ada riwayat',
              message:
                  'Simpan rencana menu mingguan untuk melihatnya lagi di sini.',
            ),
          ...data.history.map(
            (record) => _HistoryCard(record: record),
          ),
        ],
      ),
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Meal Plan'),
      ),
      body: SafeArea(child: body),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  const _HistoryCard({required this.record});

  final MealPlanRecord record;

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _isExpanded = false;

  static const List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final date = record.createdAt;

    final dateText =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    final visibleRecipes = _isExpanded
        ? record.recipeNames
        : record.recipeNames.take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  color: AppColors.green,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Meal Plan Minggu Ini',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  formatRupiah(record.total),
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '$dateText · ${record.target} · ${record.people} orang',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.muted,
              ),
            ),
            const Divider(height: 18),

            // Daftar menu yang ditampilkan
            ...visibleRecipes.asMap().entries.map((entry) {
              final dayIndex = entry.key;

              final dayName = dayIndex < _dayNames.length
                  ? _dayNames[dayIndex]
                  : 'Hari ${dayIndex + 1}';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '$dayName  ${entry.value}',
                  style: const TextStyle(fontSize: 11),
                ),
              );
            }),

            // Tombol untuk membuka atau menyembunyikan menu lainnya
            if (record.recipeNames.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded
                                ? 'Tampilkan lebih sedikit'
                                : '+ ${record.recipeNames.length - 3} menu lainnya',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppColors.green,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
