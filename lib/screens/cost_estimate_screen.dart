import 'package:flutter/material.dart';

import '../data/meal_mate_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'shopping_list_screen.dart';
import 'setup_screens.dart';

class CostEstimateScreen extends StatelessWidget {
  const CostEstimateScreen({super.key, required this.data});
  final MealMateData data;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Estimasi Biaya')),
        body: AnimatedBuilder(
          animation: data,
          builder: (context, _) {
            if (!data.hasWeeklyBudget) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 42,
                        color: AppColors.green,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Anggaran belum diatur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Masukkan batas anggaran mingguan terlebih dahulu untuk melihat estimasi biaya.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BudgetScreen(data: data),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Isi Anggaran'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final ratio =
                (data.estimatedTotal / data.weeklyBudget).clamp(0.0, 1.0);
            return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  const Text('MINGGUAN',
                      style: TextStyle(
                          color: AppColors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5)),
                  const SizedBox(height: 7),
                  const Text('Estimasi Biaya Mingguan',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink)),
                  const SizedBox(height: 5),
                  const Text(
                      'Perbandingan biaya menu dan perkiraan bahan yang perlu dibeli selama 7 hari.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 18),
                  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppColors.paleGreen,
                          borderRadius: BorderRadius.circular(15)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BUDGET YANG KAMU TETAPKAN',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.green)),
                            const SizedBox(height: 6),
                            Text(formatRupiah(data.weeklyBudget),
                                style: const TextStyle(
                                    fontSize: 23, fontWeight: FontWeight.w900)),
                            Text(
                                'Estimasi biaya menu: ${formatRupiah(data.estimatedTotal)}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.muted)),
                            const SizedBox(height: 4),
                            Text(
                                'Estimasi bahan yang perlu dibeli: ${formatRupiah(data.shoppingTotal)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkGreen)),
                            const SizedBox(height: 10),
                            ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 8,
                                    color: AppColors.green,
                                    backgroundColor: Colors.white)),
                            const SizedBox(height: 7),
                            Text(
                                data.remainingBudget >= 0
                                    ? 'Sisa budget ${formatRupiah(data.remainingBudget)}'
                                    : 'Melebihi budget ${formatRupiah(data.remainingBudget.abs())}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: data.remainingBudget >= 0
                                        ? AppColors.darkGreen
                                        : Colors.redAccent)),
                          ])),
                  const SizedBox(height: 19),
                  const SectionTitle('Rincian estimasi belanja per kategori'),
                  ...data.estimateByCategory.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SurfaceCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 12),
                          child: Row(children: [
                            Expanded(
                                child: Text(entry.key,
                                    style: const TextStyle(fontSize: 12))),
                            Text(formatRupiah(entry.value),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 12))
                          ])))),
                  SurfaceCard(
                      child: Row(children: [
                    const Expanded(
                        child: Text('Total estimasi menu',
                            style: TextStyle(fontWeight: FontWeight.w800))),
                    Text(formatRupiah(data.estimatedTotal),
                        style: const TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w900,
                            fontSize: 16))
                  ])),
                  const SizedBox(height: 8),
                  SurfaceCard(
                      child: Row(children: [
                    const Expanded(
                        child: Text('Total estimasi bahan yang dibeli',
                            style: TextStyle(fontWeight: FontWeight.w800))),
                    Text(formatRupiah(data.shoppingTotal),
                        style: const TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w900,
                            fontSize: 16))
                  ])),
                  const SizedBox(height: 15),
                  const HintCard(
                      title: 'Catatan estimasi',
                      message:
                          'Harga pada katalog merupakan estimasi, bukan harga pasar real-time. Takaran bahan disesuaikan dengan jumlah orang dan porsi resep. Bahan yang sudah tersedia di rumah tidak dimasukkan ke total belanja.'),
                  const SizedBox(height: 13),
                  OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ShoppingListScreen(data: data))),
                      icon: const Icon(Icons.shopping_basket_outlined),
                      label: const Text('Lihat Daftar Belanja')),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BudgetScreen(
                          data: data,
                          onContinue: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Ubah Budget Mingguan'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.green,
                    ),
                  ),
                ]);
          },
        ),
      );
}
