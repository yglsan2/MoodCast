import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';
import 'settings_screen.dart';
import 'mood_sos_screen.dart';

/// MoodSafe : infos + désactivation d'alerte (code / faux code) + check-in « Tout va bien ? ».
class MoodSafeScreen extends StatelessWidget {
  const MoodSafeScreen({super.key});

  static Future<void> _showDeactivateDialog(BuildContext context) async {
    final codeController = TextEditingController();
    final realCode = await StorageService.getMoodSafeCode();
    final fakeCode = await StorageService.getMoodSafeFakeCode();

    if (!context.mounted) return;
    final entered = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Désactiver l\'alerte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez votre code de désactivation (4 chiffres).'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Code',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, codeController.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (entered == null) return;

    final isReal = realCode != null && realCode.isNotEmpty && entered == realCode;
    final isFake = fakeCode != null && fakeCode.isNotEmpty && entered == fakeCode;

    if (!context.mounted) return;
    if (isReal) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Alerte désactivée'),
          content: const Text(
            'L\'alerte a bien été désactivée. Le partage de position est arrêté.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (isFake) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Alerte désactivée'),
          content: const Text(
            'L\'alerte semble désactivée. En cas de besoin, vos proches peuvent toujours être informés.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Code incorrect'),
          content: const Text('Le code saisi ne correspond pas. Réessayez.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: '🛡️ MoodSafe',
        gradient: AppColors.gradientSecondary,
      ),
      body: Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Alerte danger en un geste',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Maintenez le bouton rouge « Alerte proche » pendant 2 secondes pour envoyer un message d\'alerte à vos contacts de confiance, avec votre position en temps réel. '
                    'C\'est discret et rapide.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tout va bien ?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            await StorageService.setMoodSafeCheckinDone(StorageService.todayString());
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Merci, à bientôt !'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.thumb_up_rounded, size: 20),
                          label: const Text('Oui'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MoodSosScreen()),
                            );
                          },
                          icon: const Icon(Icons.chat_rounded, size: 20),
                          label: const Text('J\'ai besoin de parler'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _showDeactivateDialog(context),
                    icon: const Icon(Icons.lock_rounded, size: 20),
                    label: const Text('Désactiver l\'alerte (code secret)'),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings_rounded, size: 20),
                    label: const Text('Configurer MoodSafe dans Paramètres'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
