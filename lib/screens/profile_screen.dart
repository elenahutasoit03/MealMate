import 'package:flutter/material.dart';

import '../data/meal_mate_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'meal_history_screen.dart';
import 'setup_screens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.data, this.embedded = false});
  final MealMateData data;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final body = AnimatedBuilder(
        animation: data,
        builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  const Text('MEALMATE',
                      style: TextStyle(
                          color: AppColors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5)),
                  const SizedBox(height: 7),
                  const Text('Profil',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  const Text('Atur informasi dan preferensi MealMate.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 16),
                  SurfaceCard(
                      color: AppColors.paleGreen,
                      child: Row(children: [
                        const CircleAvatar(
                            backgroundColor: AppColors.green,
                            child: Icon(Icons.person, color: Colors.white)),
                        const SizedBox(width: 11),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(data.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900)),
                              const Text('Nama panggilan',
                                  style: TextStyle(
                                      fontSize: 10, color: AppColors.muted))
                            ])),
                        TextButton(
                            onPressed: () => _editName(context),
                            child: const Text('Ubah'))
                      ])),
                  const SizedBox(height: 18),
                  const SectionTitle('Preferensi makanan'),
                  SurfaceCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      child: Column(children: [
                        _PreferenceRow(
                            label: 'Target menu', value: data.target),
                        const Divider(height: 1),
                        _PreferenceRow(
                            label: 'Jumlah orang',
                            value: '${data.people} orang'),
                        const Divider(height: 1),
                        _PreferenceRow(
                            label: 'Budget mingguan',
                            value: data.hasWeeklyBudget
                                ? formatRupiah(data.weeklyBudget)
                                : 'Belum diatur'),
                      ])),
                  Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => TargetScreen(data: data))),
                          icon: const Icon(Icons.tune, size: 17),
                          label: const Text('Ubah preferensi'))),
                  const SizedBox(height: 18),
                  const SectionTitle('Aplikasi'),
                  SurfaceCard(
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        ListTile(
                            leading: const Icon(Icons.history,
                                color: AppColors.green),
                            title: const Text('Riwayat Meal Plan',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        MealHistoryScreen(data: data)))),
                        const Divider(height: 1),
                        ListTile(
                            leading: const Icon(Icons.info_outline,
                                color: AppColors.green),
                            title: const Text('Tentang MealMate',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showAbout(context)),
                      ])),
                  const SizedBox(height: 14),
                  const Text(
                      'MealMate membantu menyusun menu dan belanja sesuai rencana mingguanmu.',
                      style: TextStyle(
                          fontSize: 11, height: 1.5, color: AppColors.muted)),
                ]));
    if (embedded) return body;
    return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: SafeArea(child: body));
  }

  void _editName(BuildContext context) {
    final controller = TextEditingController(text: data.name);
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Nama panggilan'),
                content: TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Nama kamu')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () {
                        data.setName(controller.text);
                        Navigator.pop(context);
                      },
                      child: const Text('Simpan'))
                ]));
  }

  void _showAbout(BuildContext context) => showAboutDialog(
      context: context,
      applicationName: 'MealMate',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Rencana makan yang lebih mudah.');
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.muted))),
        Text(value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))
      ]));
}
