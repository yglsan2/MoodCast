import 'package:flutter/material.dart';

import '../models/emotions.dart';
import '../models/mood_cast.dart';
import '../services/storage_service.dart';
import '../services/streak_service.dart';
import '../services/premium_service.dart';
import 'mood_cast_plus_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';

/// Résumé de la semaine : courbe des humeurs, émotion dominante, conseil.
class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  List<MoodCast> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    StorageService.setWeeklySummaryShown(StorageService.todayString());
  }

  Future<void> _load() async {
    final list = await StorageService.getMoodCasts();
    if (mounted) {
      setState(() {
        _list = list;
        _loading = false;
      });
    }
  }

  static String _emotionEmoji(String e) {
    const m = {
      'joie': '😊', 'sérénité': '😌', 'enthousiasme': '🤩', 'gratitude': '🙏',
      'stress': '😰', 'anxiété': '😟', 'fatigue': '😴', 'motivation': '💪',
      'tristesse': '😢', 'mélancolie': '🌧️', 'colere': '😠', 'irritation': '😤',
      'doute': '🤔', 'espoir': '🌟', 'amour': '❤️',
    };
    return m[e] ?? '😐';
  }

  /// Conseil court selon l'émotion dominante.
  static String _adviceForEmotion(String emotion) {
    switch (emotion) {
      case 'joie':
      case 'enthousiasme':
        return 'Continue sur cette lancée. Partage ta bonne énergie autour de toi.';
      case 'sérénité':
      case 'gratitude':
        return 'Un bon moment pour prendre soin de toi et des autres.';
      case 'stress':
      case 'anxiété':
        return 'Pense à des pauses et à la respiration. Un pas à la fois.';
      case 'fatigue':
        return 'Repos et bienveillance envers toi-même. Tu peux faire moins pour faire mieux.';
      case 'motivation':
        return 'Ton élan est précieux. Choisis une priorité et avance dessus.';
      case 'tristesse':
      case 'mélancolie':
        return 'Les moments difficiles passent. N\'hésite pas à en parler à quelqu\'un.';
      case 'colere':
      case 'irritation':
        return 'Exprimer ce que tu ressens peut aider. Trouve un canal sain (sport, écriture).';
      case 'doute':
        return 'Le doute fait partie du chemin. Fais confiance à ton intuition.';
      case 'espoir':
      case 'amour':
        return 'Garde cette lumière. Elle t\'accompagne.';
      default:
        return 'Chaque semaine est une nouvelle page. Continue d\'écouter ton ressenti.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: const GradientAppBar(
          title: '📅 Ta semaine',
          gradient: AppColors.gradientPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final last7 = _list.where((c) => c.timestamp.isAfter(weekAgo)).toList();
    last7.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final emotionCounts = <String, int>{};
    for (final c in last7) {
      emotionCounts[c.emotion] = (emotionCounts[c.emotion] ?? 0) + 1;
    }
    final dominant = emotionCounts.isEmpty
        ? 'motivation'
        : emotionCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    final streak = StreakService.getResult();
    String advice = _adviceForEmotion(dominant);

    return Scaffold(
      appBar: const GradientAppBar(
        title: '📅 Ta semaine',
        gradient: AppColors.gradientPrimary,
      ),
      body: Container(
        color: AppColors.background,
        child: last7.isEmpty
            ? _buildEmpty(context)
            : RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                              'Résumé des 7 derniers jours',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textOnPrimary,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            FutureBuilder<StreakResult>(
                              future: streak,
                              builder: (context, snap) {
                                final s = snap.data;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _Chip(
                                      label: 'MoodCasts',
                                      value: '${last7.length}',
                                    ),
                                    _Chip(
                                      label: 'Émotion dominante',
                                      value: _emotionEmoji(dominant),
                                    ),
                                    if (s != null)
                                      _Chip(
                                        label: 'Série',
                                        value: '${s.currentStreak} j',
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FeelGoodCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _emotionEmoji(dominant),
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  Emotions.label(dominant),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.emotionColor(dominant),
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              advice,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (last7.length >= 2) ...[
                        const SizedBox(height: 20),
                        FeelGoodCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Humeurs de la semaine',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 80,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: _buildWeekBars(last7, weekAgo),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FutureBuilder<bool>(
                        future: PremiumService.isPremium(),
                        builder: (context, snap) {
                          final premium = snap.data ?? false;
                          final plan = PremiumService.weeklyDeepPlan(dominant, last7.length);
                          if (premium) {
                            return FeelGoodCard(
                              gradient: AppColors.gradientAccent,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Plan MoodCast+',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    plan,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.45,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return FeelGoodCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.lock_outline_rounded, color: AppColors.primary.withValues(alpha: 0.8)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Plan d’action personnalisé (MoodCast+)',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Une suggestion concrète chaque semaine selon ton humeur dominante et ton rythme — pour passer du « je me sens bizarre » au « je sais quoi essoyer ».',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const MoodCastPlusScreen()),
                                    );
                                  },
                                  child: const Text('Découvrir MoodCast+'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  List<Widget> _buildWeekBars(List<MoodCast> last7, DateTime weekAgo) {
    final days = <Widget>[];
    for (int i = 0; i < 7; i++) {
      final d = weekAgo.add(Duration(days: i));
      final dayCasts = last7.where((c) {
        final t = c.timestamp;
        return t.year == d.year && t.month == d.month && t.day == d.day;
      }).toList();
      final emotion = dayCasts.isNotEmpty
          ? dayCasts.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b).emotion
          : null;
      final intensity = dayCasts.isNotEmpty
          ? dayCasts.map((c) => c.intensity).reduce((a, b) => a + b) / dayCasts.length
          : 0.0;
      days.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: emotion != null ? (20 + intensity * 8) : 4,
                  decoration: BoxDecoration(
                    color: emotion != null
                        ? AppColors.emotionColor(emotion).withValues(alpha: 0.7)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ['L', 'M', 'M', 'J', 'V', 'S', 'D'][d.weekday - 1],
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return days;
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: FeelGoodCard(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        gradient: AppColors.gradientAccent,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_view_week_rounded, size: 56, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              'Pas encore de données cette semaine',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Enregistre des MoodCasts pour voir ton résumé hebdo ici.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textOnPrimary.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
