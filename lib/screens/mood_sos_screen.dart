import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/mood_sos_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';

/// "J'ai besoin d'encouragements" : podcast de soutien personnalisé ou demande à un proche.
class MoodSosScreen extends StatefulWidget {
  const MoodSosScreen({super.key});

  @override
  State<MoodSosScreen> createState() => _MoodSosScreenState();
}

class _MoodSosScreenState extends State<MoodSosScreen> {
  final FlutterTts _tts = FlutterTts();
  String? _supportText;
  bool _loading = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('fr-FR');
  }

  Future<void> _playEncouragement() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool('settings_sound_enabled') ?? true;

    final podcast = await MoodSosService.generateSupportPodcast();
    if (!mounted) return;
    setState(() {
      _supportText = podcast.text;
      _loading = false;
    });

    if (!soundEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Active le son dans Paramètres pour écouter. Tu peux lire le message ci-dessous.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _playing = true);
    await _tts.speak(podcast.text);
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _stopPlayback() async {
    await _tts.stop();
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _askContact() async {
    final phone = await StorageService.getAlertContactPhone();
    if (phone == null || phone.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enregistre un proche dans Paramètres → Alerte sécurité pour lui envoyer un message.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\.\-\(\)]'), '');
    final body = Uri.encodeComponent(
      'Je ne me sens pas très bien aujourd\'hui. Un petit mot ferait du bien. 💜',
    );
    final uri = Uri.parse('sms:$cleanPhone?body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ouvre ton app SMS et envoie un message à ton proche.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: '❤️ MoodSOS',
        gradient: AppColors.gradientSos,
      ),
      body: Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            FeelGoodCard(
              gradient: AppColors.gradientSos,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu n\'es pas seul(e)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Choisis comment tu veux recevoir un peu de lumière : un encouragement personnalisé (voix) ou un message à ton proche.',
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
              'Encouragements automatiques',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Un mini-podcast de soutien, adapté à ton mood et à ton thème astral.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading || _playing ? null : _playEncouragement,
              icon: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(_playing ? Icons.stop_rounded : Icons.record_voice_over_rounded, size: 22),
              label: Text(_loading ? 'Génération…' : _playing ? 'Arrêter' : 'Écouter un encouragement'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
              ),
            ),
            if (_playing)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton.icon(
                  onPressed: _stopPlayback,
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: const Text('Arrêter la lecture'),
                ),
              ),
            const SizedBox(height: 28),
            Text(
              'Demander à un proche',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Envoie un SMS à la personne que tu as enregistrée (Alerte proche). Elle pourra te répondre avec un mot doux.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _askContact,
              icon: const Icon(Icons.favorite_rounded, size: 22),
              label: const Text('Demander un boost à mon proche'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: AppColors.primary,
              ),
            ),
            if (_supportText != null) ...[
              const SizedBox(height: 28),
              FeelGoodCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message d\'encouragement',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _supportText!,
                      style: const TextStyle(fontSize: 14, height: 1.55, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
