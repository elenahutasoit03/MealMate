
import 'package:flutter/material.dart';

import '../data/meal_mate_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({
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
      builder: (context, _) {
        final groups = data.shoppingByCategory;
        final done = data.checkedShoppingItems.length;
        final total = data.shoppingItems.length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            const Text(
              'MEALMATE',
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: .5,
              ),
            ),
            const SizedBox(height: 7),

            const Text(
              'Daftar Belanja',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 5),

            const Text(
              'Bahan yang perlu dibeli untuk menu pilihanmu.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 17),

            if (total == 0) ...[
              const HintCard(
                title: 'Daftarmu masih kosong',
                message:
                    'Bahan dari Meal Plan akan muncul otomatis setelah rencana menu disimpan. Bahan yang sudah tersedia di rumah akan dikecualikan.',
              ),
            ] else ...[
              SurfaceCard(
                color: AppColors.paleGreen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shopping_basket_outlined,
                          color: AppColors.green,
                        ),
                        const SizedBox(width: 9),

                        const Expanded(
                          child: Text(
                            'Progress belanja',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        Text(
                          '$done dari $total',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : done / total,
                        minHeight: 7,
                        color: AppColors.green,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 9),

                    Text(
                      'Estimasi biaya bahan: '
                      '${formatRupiah(data.shoppingTotal)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 17),

              ...groups.entries.map(
                (group) => _ShoppingGroup(
                  title: group.key,
                  items: group.value,
                  data: data,
                ),
              ),

              const SizedBox(height: 8),

              // Tombol Hapus yang dibeli tetap dipertahankan.
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: data.checkedShoppingItems.isEmpty
                      ? null
                      : () {
                          for (final item
                              in data.checkedShoppingItems.toList()) {
                            data.removeShoppingItem(item);
                          }
                        },
                  child: const Text('Hapus yang dibeli'),
                ),
              ),

              const SizedBox(height: 9),

              SurfaceCard(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total estimasi belanja',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    Text(
                      formatRupiah(data.shoppingTotal),
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            const HintCard(
              title: 'Belanja sesuai kebutuhan',
              message:
                  'Harga perkiraan dapat berbeda sesuai lokasi dan toko. Cek bahan di rumah sebelum berbelanja.',
              color: AppColors.peach,
            ),
          ],
        );
      },
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Belanja'),
      ),
      body: SafeArea(
        child: body,
      ),
    );
  }
}

class _ShoppingGroup extends StatelessWidget {
  const _ShoppingGroup({
    required this.title,
    required this.items,
    required this.data,
  });

  final String title;
  final List<String> items;
  final MealMateData data;

  @override
  Widget build(BuildContext context) {
    final subtotal = items.fold<int>(
      0,
      (sum, item) => sum + (data.shoppingPrices[item] ?? 0),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),

              Text(
                formatRupiah(subtotal),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          SurfaceCard(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 3,
            ),
            child: Column(
              children: items.map((item) {
                final checked =
                    data.checkedShoppingItems.contains(item);

                return Row(
                  children: [
                    Checkbox(
                      value: checked,
                      onChanged: (_) =>
                          data.toggleShoppingItem(item),
                      activeColor: AppColors.green,
                      visualDensity: VisualDensity.compact,
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                decoration: checked
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: checked
                                    ? AppColors.muted
                                    : AppColors.ink,
                              ),
                            ),
                            if (data.shoppingAmounts[item] != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Kebutuhan: ${data.shoppingAmounts[item]}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    Text(
                      formatRupiah(
                        data.shoppingPrices[item] ?? 0,
                      ),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),

                    IconButton(
                      tooltip: 'Hapus bahan',
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          data.removeShoppingItem(item),
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
