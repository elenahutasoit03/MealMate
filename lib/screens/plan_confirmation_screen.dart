import 'package:flutter/material.dart';

import '../data/meal_mate_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'home_screen.dart';
import 'meal_history_screen.dart';
import 'meal_plan_screen.dart';

class PlanConfirmationScreen extends StatelessWidget {
  const PlanConfirmationScreen({super.key, required this.data});
  final MealMateData data;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Row(children: [
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back)),
                    const Text('Meal Plan berhasil disimpan',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ]),
                  const SizedBox(height: 17),
                  const Text('Rencana menu mingguan sudah siap digunakan.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                        color: AppColors.paleGreen,
                        borderRadius: BorderRadius.circular(16)),
                    child: const Column(children: [
                      Icon(Icons.check_circle,
                          color: AppColors.green, size: 48),
                      SizedBox(height: 9),
                      Text('Tersimpan di perangkat ini',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      SizedBox(height: 5),
                      Text(
                          'Kamu bisa melihat meal plan kapan saja dari halaman Beranda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: AppColors.muted)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  SurfaceCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('RINGKASAN MEAL PLAN',
                              style: TextStyle(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9)),
                          const SizedBox(height: 9),
                          const Text('Meal Plan Minggu Ini',
                              style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 5),
                          Text('Target: ${data.target} | ${data.people} orang',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.muted)),
                          Text(
                              'Budget: ${formatRupiah(data.weeklyBudget)} | Estimasi: ${formatRupiah(data.estimatedTotal)}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.muted)),
                          const SizedBox(height: 10),
                          ...data.weeklyRecipes
                              .take(3)
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 3),
                                    child: Text(
                                        '${[
                                          'Sen',
                                          'Sel',
                                          'Rab'
                                        ][entry.key]}: ${entry.value.name}',
                                        style: const TextStyle(fontSize: 11)),
                                  )),
                        ]),
                  ),
                  const SizedBox(height: 15),
                  PrimaryButton(
                    label: 'Kembali ke Beranda',
                    icon: Icons.home_outlined,
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => HomeScreen(data: data)),
                      (route) => false,
                    ),
                  ),
                  const SizedBox(height: 9),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MealPlanScreen(data: data),
                      ),
                    ),
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Lihat Meal Plan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => MealHistoryScreen(data: data))),
                    child: const Text('Buka Riwayat Meal Plan',
                        style: TextStyle(color: AppColors.green)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      'Meal plan tersimpan di perangkat ini dan bisa dibuka lagi dari Profil.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      );
}
