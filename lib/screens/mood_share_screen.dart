import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/emotions.dart';
import '../services/api_service.dart';
import '../services/horoscope_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';

/// Partager son mood (humeur, message, astro, Post-it) vers ses proches ou en anonyme WorldFlow.
/// 100 % opt-in.
class MoodShareScreen extends StatefulWidget {
  const MoodShareScreen({super.key});

  @override
  State<MoodShareScreen> createState() => _MoodShareScreenState();
}

class _MoodShareScreenState extends State<MoodShareScreen> {
  bool _shareMood = true;
  bool _shareMessage = true;
  bool _shareAstro = true;
  bool _sharePostit = false;
  bool _loading = true;
  String _lastEmotion = 'motivation';
  String _lastMessage = '';
  String _astroSummary = '';
  String _postitText = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final moodCasts = await StorageService.getMoodCasts();
    moodCasts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final birthDate = await StorageService.getBirthDate();

    if (moodCasts.isNotEmpty) {
      final last = moodCasts.first;
      _lastEmotion = last.emotion;
      _lastMessage = last.podcastText.length > 300
          ? '${last.podcastText.substring(0, 297)}...'
          : last.podcastText;
    } else {
      _lastMessage = 'Pas encore de MoodCast enregistré.';
    }

    if (birthDate != null) {
      _astroSummary = HoroscopeService.getPodcastAstroBlock(birthDate);
      _astroSummary += '\n${HoroscopeService.getPodcastTransitBlock(DateTime.now())}';
    } else {
      _astroSummary = HoroscopeService.getPodcastTransitBlock(DateTime.now());
    }

    _postitText = moodCasts.isNotEmpty
        ? 'MoodCast – ${Emotions.label(_lastEmotion)}\n\nTon mood du jour : ${Emotions.label(_lastEmotion)}.\n\n$_lastMessage'
        : 'MoodCast – Rappel bienveillant\n\nPrends un moment pour toi. Respire. 💜';

    if (mounted) setState(() => _loading = false);
  }

  String _buildShareText() {
    final parts = <String>[];
    if (_shareMood) {
      parts.add('💜 Mon humeur du jour : ${Emotions.label(_lastEmotion)}');
    }
    if (_shareMessage) {
      parts.add('\n📝 Mon message :\n$_lastMessage');
    }
    if (_shareAstro) {
      parts.add('\n🔮 Mon résumé astro :\n$_astroSummary');
    }
    if (_sharePostit) {
      parts.add('\n🟨 Mon Post-it Mood :\n$_postitText');
    }
    if (parts.isEmpty) return 'MoodCast – Partagé avec 💜';
    return '${parts.join('\n\n')}\n\n— Envoyé depuis MoodCast 💜';
  }

  Future<void> _share() async {
    await Share.share(
      _buildShareText(),
      subject: 'Mon mood du jour – MoodCast',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Partage lancé : choisis une app (SMS, WhatsApp, etc.).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _contributeAnonymous() async {
    final moodCasts = await StorageService.getMoodCasts();
    moodCasts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (moodCasts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enregistre d\'abord un MoodCast pour contribuer à WorldFlow.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final last = moodCasts.first;
    await ApiService.uploadMoodData(
      emotion: last.emotion,
      intensity: last.intensity,
      energy: last.energy,
      location: last.location,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contribution anonyme envoyée à WorldFlow. Merci 💜'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: '🤝 MoodShare',
        gradient: AppColors.gradientPrimary,
      ),
      body: Container(
        color: AppColors.background,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  Text(
                    'Choisis ce que tu veux partager. Tu décides. 100 % opt-in.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FeelGoodCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Inclure dans le partage',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          value: _shareMood,
                          onChanged: (v) => setState(() => _shareMood = v ?? true),
                          title: const Text('Mon humeur du jour'),
                          subtitle: Text(Emotions.label(_lastEmotion)),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.primary,
                        ),
                        CheckboxListTile(
                          value: _shareMessage,
                          onChanged: (v) => setState(() => _shareMessage = v ?? true),
                          title: const Text('Mon message / résumé podcast'),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.primary,
                        ),
                        CheckboxListTile(
                          value: _shareAstro,
                          onChanged: (v) => setState(() => _shareAstro = v ?? true),
                          title: const Text('Mon résumé astrologique'),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.primary,
                        ),
                        CheckboxListTile(
                          value: _sharePostit,
                          onChanged: (v) => setState(() => _sharePostit = v ?? false),
                          title: const Text('Mon Post-it Mood'),
                          subtitle: const Text('Rappel bienveillant pour l\'agenda'),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.share_rounded, size: 22),
                    label: const Text('Partager vers une app (SMS, WhatsApp…)'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Contribuer à la carte mondiale (anonyme)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _contributeAnonymous,
                    icon: const Icon(Icons.public_rounded, size: 20),
                    label: const Text('Contribuer anonymement à WorldFlow'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }
}
