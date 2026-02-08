import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../services/storage_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';
import 'settings_screen.dart';

/// Prévenir discrètement un proche que l'on traverse un moment difficile (SMS).
class MoodPulseScreen extends StatelessWidget {
  const MoodPulseScreen({super.key});

  static const String _defaultMessage =
      'Coucou, je traverse un moment un peu difficile. Tu aurais un moment pour en parler ?';

  static Future<bool> sendPulseToProche() async {
    final phone = await StorageService.getMoodPulsePhone();
    if (phone == null || phone.trim().isEmpty) return false;
    final clean = phone.replaceAll(RegExp(r'[\s\.\-\(\)]'), '');
    final uri = Uri.parse(
      'sms:$clean?body=${Uri.encodeComponent(_defaultMessage)}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: '💜 MoodPulse',
        gradient: AppColors.gradientPrimary,
      ),
      body: Container(
        color: AppColors.background,
        child: FutureBuilder<String?>(
          future: StorageService.getMoodPulsePhone(),
          builder: (context, snap) {
            final hasPhone = snap.data != null && snap.data!.trim().isNotEmpty;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FeelGoodCard(
                    gradient: AppColors.gradientPrimary,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Besoin de soutien ?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textOnPrimary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Envoie un message à ton proche pour lui dire que tu as besoin d\'écoute. '
                          'Le SMS s\'ouvrira avec un texte bienveillant que tu pourras modifier.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: AppColors.textOnPrimary.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (hasPhone) ...[
                    FilledButton.icon(
                      onPressed: () async {
                        final ok = await sendPulseToProche();
                        if (context.mounted) {
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('SMS prêt à envoyer.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Prévenir mon proche'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Message type : « $_defaultMessage »',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ] else ...[
                    FeelGoodCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Aucun contact configuré',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Enregistre le numéro d\'un proche (partenaire, ami) dans les paramètres pour pouvoir lui envoyer un message en un tap.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            },
                            icon: const Icon(Icons.settings_rounded),
                            label: const Text('Configurer dans Paramètres'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
