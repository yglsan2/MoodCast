import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/emotions.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';

/// Ambiances sonores suggérées selon le mood (stress → pluie, fatigue → nature, etc.).
class MoodSoundScreen extends StatefulWidget {
  const MoodSoundScreen({super.key});

  @override
  State<MoodSoundScreen> createState() => _MoodSoundScreenState();
}

class _MoodSoundScreenState extends State<MoodSoundScreen> {
  String? _suggestedEmotion;
  bool _loading = true;

  /// Suggestion (label, description, URL type) selon l'émotion.
  static ({String label, String desc, String url}) _suggestionFor(String emotion) {
    switch (emotion) {
      case 'stress':
      case 'anxiété':
        return (
          label: 'Pluie & méditation',
          desc: 'Des sons de pluie et des ambiances apaisantes pour déposer le stress.',
          url: 'https://www.youtube.com/results?search_query=rain+sounds+relaxation',
        );
      case 'fatigue':
        return (
          label: 'Nature & forêt',
          desc: 'Bruits de nature pour te ressourcer en douceur.',
          url: 'https://www.youtube.com/results?search_query=nature+sounds+forest',
        );
      case 'tristesse':
      case 'mélancolie':
        return (
          label: 'Piano doux',
          desc: 'Une ambiance musicale douce pour accompagner l\'émotion.',
          url: 'https://www.youtube.com/results?search_query=calm+piano+music',
        );
      case 'colere':
      case 'irritation':
        return (
          label: 'Souffle & respiration',
          desc: 'Des exercices de respiration pour retrouver le calme.',
          url: 'https://www.youtube.com/results?search_query=breathing+exercise+calm',
        );
      case 'joie':
      case 'enthousiasme':
        return (
          label: 'Energie positive',
          desc: 'Une playlist légère pour garder la bonne vibe.',
          url: 'https://www.youtube.com/results?search_query=uplifting+acoustic+music',
        );
      case 'sérénité':
      case 'gratitude':
        return (
          label: 'Méditation guidée',
          desc: 'Pour ancrer ce moment de calme.',
          url: 'https://www.youtube.com/results?search_query=meditation+guidée+courte',
        );
      case 'doute':
        return (
          label: 'Bruit blanc',
          desc: 'Un fond neutre pour recentrer ton attention.',
          url: 'https://www.youtube.com/results?search_query=white+noise+relax',
        );
      default:
        return (
          label: 'Ambiance calme',
          desc: 'Une pause sonore pour te recentrer.',
          url: 'https://www.youtube.com/results?search_query=relaxing+music+ambient',
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final moodCasts = await StorageService.getMoodCasts();
    moodCasts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final emotion = moodCasts.isNotEmpty ? moodCasts.first.emotion : 'sérénité';
    if (mounted) {
      setState(() {
        _suggestedEmotion = emotion;
        _loading = false;
      });
    }
  }

  Future<void> _openAmbiance(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: const GradientAppBar(
          title: '🎵 MoodSound',
          gradient: AppColors.gradientSecondary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final emotion = _suggestedEmotion ?? 'sérénité';
    final suggestion = _suggestionFor(emotion);

    return Scaffold(
      appBar: const GradientAppBar(
        title: '🎵 MoodSound',
        gradient: AppColors.gradientSecondary,
      ),
      body: Container(
        color: AppColors.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FeelGoodCard(
                gradient: AppColors.gradientSecondary,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selon ton dernier mood',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          Emotions.label(emotion),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textOnPrimary,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '→',
                          style: TextStyle(
                            color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            suggestion.label,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textOnPrimary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FeelGoodCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      suggestion.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      suggestion.desc,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _openAmbiance(suggestion.url),
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      label: const Text('Ouvrir une ambiance (YouTube)'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Changer de mood pour une autre suggestion : ouvre MoodCast ou MoodRoutine, puis reviens ici.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
