import 'package:flutter/material.dart';

import 'data/meal_mate_data.dart';
import 'data/supabase_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseService.instance.initialize();
  } catch (error) {
    debugPrint('Supabase tidak dapat dimulai: $error');
  }
  runApp(const MealMateApp());
}

class MealMateApp extends StatefulWidget {
  const MealMateApp({super.key});

  @override
  State<MealMateApp> createState() => _MealMateAppState();
}

class _MealMateAppState extends State<MealMateApp> {
  late final MealMateData data = MealMateData();
  late Future<void> _loadData;

  @override
  void initState() {
    super.initState();
    _loadData = data.load();
  }

  void _retryLoad() {
    setState(() {
      _loadData = data.load();
    });
  }

  @override
  void dispose() {
    data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MealMate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: FutureBuilder<void>(
          future: _loadData,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return _CatalogConnectionScreen(onRetry: _retryLoad);
            }

            return SplashScreen(data: data);
          },
        ),
      );
}

class _CatalogConnectionScreen extends StatelessWidget {
  const _CatalogConnectionScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 52,
                    color: AppColors.green,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Hubungkan internet untuk memuat MealMate',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Katalog resep asli diambil dari Supabase. Setelah berhasil dimuat, MealMate menyimpan cache agar pembukaan berikutnya lebih cepat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba lagi'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
