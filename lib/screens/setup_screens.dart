import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/meal_mate_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'generating_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key, required this.data, this.onContinue});
  final MealMateData data;
  final VoidCallback? onContinue;

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late final TextEditingController _budgetController;
  bool _budgetInputInvalid = false;

  @override
  void initState() {
    super.initState();
    // Anggaran tetap kosong untuk pengguna baru. Anggaran yang pernah
    // ditetapkan pengguna akan dipulihkan dari penyimpanan.
    _budgetController = TextEditingController(
      text: widget.data.hasWeeklyBudget
          ? widget.data.weeklyBudget.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.data,
        builder: (context, _) => ScreenFrame(
          eyebrow: 'Langkah 1 dari 3',
          title: 'Atur Budget & Jumlah Orang',
          description:
              'Tentukan anggaran makan mingguan dan jumlah orang yang akan kamu masak.',
          buttonLabel: 'Lanjutkan: Bahan Tersedia',
          onContinue: () {
            final amount = int.tryParse(_budgetController.text.trim());
            if (amount == null || amount < 50000 || amount > 5000000) {
              setState(() => _budgetInputInvalid = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Masukkan budget Rp50.000 sampai Rp5.000.000 terlebih dahulu.',
                  ),
                ),
              );
              return;
            }

            if (!widget.data.hasWeeklyBudget ||
                widget.data.weeklyBudget != amount) {
              widget.data.weeklyBudget = amount;
            }

            if (widget.onContinue != null) {
              widget.onContinue!();
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IngredientScreen(data: widget.data),
              ),
            );
          },
          children: [
            Text(
              '${widget.data.name}, atur rencana anggaranmu.',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'BUDGET MINGGUAN',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
              decoration: InputDecoration(
                prefixText: 'Rp  ',
                hintText: 'Masukkan anggaran mingguan',
                hintStyle: const TextStyle(color: AppColors.muted),
                helperText: _budgetInputInvalid
                    ? null
                    : 'Isi sendiri, minimal Rp50.000 dan maksimal Rp5.000.000.',
                helperStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
                errorText: _budgetInputInvalid
                    ? 'Masukkan budget Rp50.000 sampai Rp5.000.000.'
                    : null,
              ),
              onChanged: (value) {
                final amount = int.tryParse(value);
                if (amount == null || amount < 50000 || amount > 5000000) {
                  if (!_budgetInputInvalid) {
                    setState(() => _budgetInputInvalid = true);
                  }
                  return;
                }

                if (_budgetInputInvalid) {
                  setState(() => _budgetInputInvalid = false);
                }
                widget.data.weeklyBudget = amount;
              },
            ),
            const SizedBox(height: 23),
            const Text(
              'JUMLAH ORANG',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SurfaceCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: widget.data.people > 1
                        ? () => widget.data.setPeople(widget.data.people - 1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '${widget.data.people} orang',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    onPressed: widget.data.people < 20
                        ? () => widget.data.setPeople(widget.data.people + 1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.data.hasWeeklyBudget
                  ? 'Setara ${formatRupiah(widget.data.dailyPerPerson)} per orang per hari.'
                  : 'Isi anggaran untuk melihat alokasi per orang per hari.',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            if (widget.data.hasWeeklyBudget)
              SurfaceCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PERKIRAAN MENU 7 HARI',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatRupiah(widget.data.estimatedTotal),
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.data.isBudgetSufficient
                          ? 'Sisa anggaran: ${formatRupiah(widget.data.remainingBudget)}'
                          : 'Kurang ${formatRupiah(widget.data.budgetShortfall)}. Budget minimum untuk 7 hari sekitar ${formatRupiah(widget.data.minimumWeeklyBudget)}.',
                      style: TextStyle(
                        color: widget.data.isBudgetSufficient
                            ? AppColors.green
                            : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Setiap hari dihitung dari harga per porsi × jumlah orang. Total menjumlahkan tujuh hari.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              )
            else
              const HintCard(
                title: 'Anggaran belum diisi',
                message:
                    'Perkiraan menu dan sisa anggaran akan ditampilkan setelah kamu memasukkan batas anggaran mingguan.',
              ),
            const SizedBox(height: 20),
            const HintCard(
              title: 'Rencana sesuai kemampuan',
              message:
                  'Anggaran ini menjadi batas pengeluaran untuk seluruh menu selama tujuh hari. Rekomendasi akan menyesuaikan budget dan target menu.',
            ),
          ],
        ),
      );
}

class IngredientScreen extends StatefulWidget {
  const IngredientScreen({super.key, required this.data, this.onContinue});
  final MealMateData data;
  final VoidCallback? onContinue;

  @override
  State<IngredientScreen> createState() => _IngredientScreenState();
}

class _IngredientScreenState extends State<IngredientScreen> {
  final _ingredientController = TextEditingController();

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    widget.data.addIngredient(_ingredientController.text);
    _ingredientController.clear();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.data,
        builder: (context, _) => ScreenFrame(
          eyebrow: 'MealMate',
          title: 'Bahan yang Tersedia',
          description:
              'Pilih bahan yang sudah ada di rumah. Menu akan memprioritaskan bahan ini untuk membantu menghemat belanja.',
          buttonLabel: 'Simpan dan Lanjutkan',
          onContinue: widget.onContinue ??
              () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => TargetScreen(data: widget.data)),
                  ),
          children: [
            const Text(
              'TAMBAH BAHAN',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ingredientController,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _addIngredient(),
              decoration: InputDecoration(
                hintText: 'Mis. tahu, bayam, kentang',
                suffixIcon: IconButton(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add, color: AppColors.green),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'BAHAN DI RUMAH',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            const SizedBox(height: 5),
            const Text(
              'Centang bahan yang tersedia. Ketuk hapus untuk mengeluarkan bahan dari daftar.',
              style:
                  TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 10),
            ...widget.data.ingredients.map(
              (ingredient) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: SurfaceCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: Row(
                    children: [
                      Checkbox(
                        value: widget.data.availableIngredients.contains(
                          ingredient,
                        ),
                        onChanged: (_) =>
                            widget.data.toggleAvailable(ingredient),
                        activeColor: AppColors.green,
                      ),
                      Expanded(child: Text(ingredient)),
                      IconButton(
                        tooltip: 'Hapus bahan',
                        onPressed: () =>
                            widget.data.removeIngredient(ingredient),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const HintCard(
              title: 'Tips hemat',
              message:
                  'Gunakan bahan yang tersedia lebih dulu untuk mengurangi belanja dan food waste.',
            ),
          ],
        ),
      );
}

class TargetScreen extends StatelessWidget {
  const TargetScreen({super.key, required this.data, this.onContinue});
  final MealMateData data;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: data,
        builder: (context, _) => ScreenFrame(
          eyebrow: 'Langkah 3 dari 3',
          title: 'Pilih Target Menu',
          description:
              'Pilih prioritas utama untuk menu mingguanmu. Kamu bisa mengubahnya kapan saja.',
          buttonLabel: 'Lihat Rekomendasi Menu',
          onContinue: onContinue ??
              () {
                if (!data.hasWeeklyBudget) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BudgetScreen(
                        data: data,
                        onContinue: () => Navigator.pop(context),
                      ),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GeneratingScreen(data: data),
                  ),
                );
              },
          children: [
            SurfaceCard(
              child: Row(
                children: [
                  const Icon(Icons.savings_outlined, color: AppColors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Budget mingguan',
                          style:
                              TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                        Text(
                          data.hasWeeklyBudget
                              ? formatRupiah(data.weeklyBudget)
                              : 'Belum diatur',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${data.people} orang',
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'BAHAN TERSEDIA',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              data.availableIngredients.isEmpty
                  ? 'Belum ada bahan yang dipilih'
                  : data.availableIngredients.join('  ·  '),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 23),
            const Text(
              'PILIH PRIORITAS',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            const SizedBox(height: 9),
            _TargetTile(
              data: data,
              title: 'Hemat',
              subtitle:
                  'Harga terjangkau, bahan sederhana, dan minim food waste.',
              color: const Color(0xFFE4EEDB),
            ),
            _TargetTile(
              data: data,
              title: 'Seimbang',
              subtitle: 'Variasi karbohidrat, protein, sayuran, dan rasa.',
              color: const Color(0xFFE8EDDF),
            ),
            _TargetTile(
              data: data,
              title: 'Tinggi Protein',
              subtitle:
                  'Prioritaskan sumber protein; gram protein digunakan jika data nutrisi tersedia.',
              color: const Color(0xFFF8E5CF),
            ),
          ],
        ),
      );
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({
    required this.data,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  final MealMateData data;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final selected = data.target == title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        onTap: () => data.selectTarget(title),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? AppColors.green : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.green),
            ],
          ),
        ),
      ),
    );
  }
}
