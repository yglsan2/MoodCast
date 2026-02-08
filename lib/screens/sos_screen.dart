import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/alert_proche_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';
import 'settings_screen.dart';

/// Urgence SOS : numéros d'urgence et d'écoute, boutons pour appeler.
class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  static Future<void> _onAlerteProche(BuildContext context) async {
    final ok = await AlertProcheService.trigger();
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('SMS prêt à envoyer — il ne reste qu\'à appuyer sur Envoyer.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Alerte proche'),
          content: const Text(
            'Enregistrez le numéro d\'un proche de confiance dans Paramètres → Alerte sécurité. '
            'Le bouton rouge « Alerte proche » ouvrira alors un SMS avec votre position en un geste.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Fermer'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Paramètres'),
            ),
          ],
        ),
      );
      if (go == true && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      }
    }
  }

  Future<void> _launchTel(BuildContext context, String number) async {
    final clean = number.replaceAll(' ', '');
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: clean));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Numéro copié : $clean (appelez depuis votre téléphone)'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: clean));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Numéro copié : $clean'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: '🆘 Urgence SOS',
        gradient: AppColors.gradientSos,
      ),
      body: Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onAlerteProche(context),
                borderRadius: BorderRadius.circular(20),
                child: FeelGoodCard(
                  margin: EdgeInsets.zero,
                  gradient: AppColors.gradientSos,
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.emergency_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alerter mon proche',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Envoie ta position par SMS en un geste',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white.withValues(alpha: 0.9)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FeelGoodCard(
              gradient: AppColors.gradientPrimary,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aide immédiate',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnPrimary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'En cas d\'urgence, composez le numéro adapté. Ces numéros sont gratuits et accessibles 24h/24.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Urgences',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            _SosTile(
              label: 'Samu (urgence médicale)',
              number: '15',
              onTap: () => _launchTel(context, '15'),
              color: AppColors.error,
            ),
            _SosTile(
              label: 'Pompiers',
              number: '18',
              onTap: () => _launchTel(context, '18'),
              color: AppColors.accent,
            ),
            _SosTile(
              label: 'Police / Gendarmerie',
              number: '17',
              onTap: () => _launchTel(context, '17'),
              color: AppColors.info,
            ),
            _SosTile(
              label: 'Numéro d\'urgence européen',
              number: '112',
              onTap: () => _launchTel(context, '112'),
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Écoute et soutien',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            _SosTile(
              label: 'Prévention du suicide (3114)',
              number: '3114',
              onTap: () => _launchTel(context, '3114'),
              color: AppColors.primary,
            ),
            _SosTile(
              label: 'SOS Amitié (écoute 24h/24)',
              number: '09 72 39 40 50',
              onTap: () => _launchTel(context, '09 72 39 40 50'),
              color: AppColors.teal,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SosTile extends StatelessWidget {
  const _SosTile({
    required this.label,
    required this.number,
    required this.onTap,
    required this.color,
  });

  final String label;
  final String number;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: FeelGoodCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(Icons.phone_rounded, color: color, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        number,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
