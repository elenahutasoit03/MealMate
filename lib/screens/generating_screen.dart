import 'dart:async';

import 'package:flutter/material.dart';

import '../data/meal_mate_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'meal_plan_screen.dart';

class GeneratingScreen extends StatefulWidget {
  const GeneratingScreen({super.key, required this.data});
  final MealMateData data;

  @override
  State<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends State<GeneratingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1800), _showPlan);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showPlan() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MealPlanScreen(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MealMate',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 27),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.paleGreen,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            color: AppColors.green,
                            size: 54,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Sedang menyiapkan menu...',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Kami sedang mencocokkan budget, jumlah orang, target, dan bahan yang tersedia.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 17),
                    const _ProgressStep(
                      number: '01',
                      label: 'Menghitung kebutuhan budget',
                    ),
                    const _ProgressStep(
                      number: '02',
                      label: 'Mencocokkan bahan yang tersedia',
                    ),
                    const _ProgressStep(
                      number: '03',
                      label: 'Menyusun rekomendasi 7 hari',
                    ),
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(
                      value: .78,
                      color: AppColors.green,
                      backgroundColor: AppColors.paleGreen,
                      minHeight: 6,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Mohon tunggu sebentar.',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                        label: 'Lihat Menu 7 Hari', onPressed: _showPlan),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({required this.number, required this.label});
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.paleGreen,
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.ink),
              ),
            ],
          ),
        ),
      );
}
