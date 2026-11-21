import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
          label:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            if (action != null)
              TextButton(
                onPressed: onAction,
                child: Text(
                  action!,
                  style: const TextStyle(color: AppColors.green, fontSize: 12),
                ),
              ),
          ],
        ),
      );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: child,
      );
}

class HintCard extends StatelessWidget {
  const HintCard({
    super.key,
    required this.title,
    required this.message,
    this.color = AppColors.paleGreen,
  });
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      );
}

class ScreenFrame extends StatelessWidget {
  const ScreenFrame({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.children,
    required this.buttonLabel,
    required this.onContinue,
    this.onBack,
  });
  final String eyebrow;
  final String title;
  final String description;
  final List<Widget> children;
  final String buttonLabel;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Center(
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 22, 4),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed:
                                onBack ?? () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const Text(
                            'MealMate',
                            style: TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 15, 24, 20),
                        children: [
                          Text(
                            eyebrow.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: .5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 25,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            description,
                            style: const TextStyle(
                              color: AppColors.muted,
                              height: 1.45,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 23),
                          ...children,
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                      child: PrimaryButton(
                          label: buttonLabel, onPressed: onContinue),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

String formatRupiah(int amount) =>
    'Rp${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
