
import 'package:flutter/material.dart';

import '../data/meal_mate_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.data});

  final MealMateData data;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.data.name,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  border: Border.all(
                    color: AppColors.line,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MealMate brand identity
                    Row(
                      children: [
                        const Icon(
                          Icons.restaurant_menu_rounded,
                          size: 43,
                          color: Color(0xFF59352D),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'MealMate',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 34),

                    const Text(
                      'Makan Enak.\nRencana Lebih Baik.',
                      style: TextStyle(
                        fontSize: 29,
                        height: 1.13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        letterSpacing: -0.7,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Rencanakan menu mingguan sesuai anggaran dan bahan yang tersedia.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),

                    const SizedBox(height: 28),

                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama panggilan',
                        hintText: 'Contoh: Maya',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    const SizedBox(height: 16),

                    PrimaryButton(
                      label: 'Mulai',
                      icon: Icons.arrow_forward,
                      onPressed: _openHome,
                    ),

                    const SizedBox(height: 10),

                    // Decorative MealMate food illustration
                    Align(
                      alignment: Alignment.centerRight,
                      child: Image.asset(
                        'assets/images/mealmate_food_illustration.png',
                        width: 230,
                        height: 114,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openHome() {
    final name = _nameController.text.trim();

    if (name.isNotEmpty) {
      widget.data.setName(name);
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(data: widget.data),
      ),
    );
  }
}
