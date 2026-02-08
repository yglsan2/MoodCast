import 'package:flutter/material.dart';

import '../models/emotions.dart';
import '../models/mood_cast.dart';
import '../services/storage_service.dart';
import '../services/streak_service.dart';
import '../services/risk_days_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<MoodCast> _list = [];
  StreakResult? _streak;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await StorageService.getMoodCasts();
    final streak = await StreakService.getResult();
    if (mounted) {
      setState(() {
        _list = list;
        _streak = streak;
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

  static (String, String) _badgeInfo(String id) {
    switch (id) {
      case 'first_moodcast':
        return ('🎤', 'Premier MoodCast');
      case 'streak_3':
        return ('🔥', '3 jours d\'affilée');
      case 'streak_7':
        return ('⭐', '7 jours d\'affilée');
      case 'best_7':
        return ('🏆', 'Record 7 jours');
      default:
        return ('✨', id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: const GradientAppBar(title: '📊 Statistiques', gradient: AppColors.gradientPrimary),
        body: Container(
          color: AppColors.background,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    int total = _list.length;
    int last7 = _list.where((c) => c.timestamp.isAfter(weekAgo)).length;
    int last30 = _list.where((c) => c.timestamp.isAfter(monthAgo)).length;

    final emotionCounts = <String, int>{};
    double sumIntensity = 0, sumEnergy = 0;
    for (final c in _list) {
      emotionCounts[c.emotion] = (emotionCounts[c.emotion] ?? 0) + 1;
      sumIntensity += c.intensity;
      sumEnergy += c.energy;
    }
    final dominant = emotionCounts.isEmpty ? '—' : emotionCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final avgIntensity = total > 0 ? (sumIntensity / total).toStringAsFixed(1) : '—';
    final avgEnergy = total > 0 ? (sumEnergy / total).toStringAsFixed(1) : '—';

    return Scaffold(
      appBar: GradientAppBar(
        title: '📊 Statistiques',
        gradient: AppColors.gradientPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Container(
        color: AppColors.background,
        child: total == 0
            ? _buildEmptyState(context)
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_streak != null) ...[
                      FeelGoodCard(
                        gradient: AppColors.gradientAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '🔥 Série',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textOnPrimary,
                                      ),
                                ),
                                const Spacer(),
                                if (_streak!.newBadges.isNotEmpty)
                                  Text(
                                    'Nouveau(x) badge(s) !',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatChip(
                                  label: 'Aujourd\'hui',
                                  value: '${_streak!.currentStreak} jour${_streak!.currentStreak > 1 ? 's' : ''}',
                                  light: true,
                                ),
                                _StatChip(
                                  label: 'Record',
                                  value: '${_streak!.bestStreak} jour${_streak!.bestStreak > 1 ? 's' : ''}',
                                  light: true,
                                ),
                              ],
                            ),
                            if (_streak!.badges.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _streak!.badges.map((id) {
                                  final (emoji, label) = _badgeInfo(id);
                                  return Chip(
                                    backgroundColor: AppColors.textOnPrimary.withValues(alpha: 0.2),
                                    label: Text('$emoji $label', style: const TextStyle(fontSize: 12)),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FeelGoodCard(
                      gradient: AppColors.gradientPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vue d\'ensemble',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textOnPrimary,
                                ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatChip(label: 'Total', value: '$total', light: true),
                              _StatChip(label: '7 jours', value: '$last7', light: true),
                              _StatChip(label: '30 jours', value: '$last30', light: true),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _WeeklyGoalRow(current: last7, goal: 3),
                        ],
                      ),
                    ),
                    FeelGoodCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Émotion dominante',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(_emotionEmoji(dominant), style: const TextStyle(fontSize: 32)),
                              const SizedBox(width: 12),
                              Text(
                                Emotions.label(dominant),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emotionColor(dominant),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Moy. intensité: $avgIntensity  ·  Moy. énergie: $avgEnergy',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (total >= 10)
                      FutureBuilder<List<int>>(
                        future: RiskDaysService.getRiskWeekdays(limit: 2),
                        builder: (context, snap) {
                          if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
                          final days = snap.data!;
                          final names = days.map((d) => RiskDaysService.weekdayNameCap(d)).join(' et ');
                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: FeelGoodCard(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('📅', style: TextStyle(fontSize: 22)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tes jours à risque',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'En général tu es plus souvent en baisse le $names. Pense à ton rituel MoodCast ce jour-là.',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    if (emotionCounts.isNotEmpty) ...[
                      FeelGoodCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Répartition des émotions',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            ...emotionCounts.entries.map((e) {
                              final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(0) : '0';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Text(_emotionEmoji(e.key), style: const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: total > 0 ? e.value / total : 0,
                                          backgroundColor: AppColors.surface,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.emotionColor(e.key)),
                                          minHeight: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('$pct%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: FeelGoodCard(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        gradient: AppColors.gradientAccent,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_rounded, size: 56, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée pour l\'instant',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Enregistrez des MoodCasts pour voir vos statistiques et votre évolution.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyGoalRow extends StatelessWidget {
  const _WeeklyGoalRow({required this.current, this.goal = 3});

  final int current;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final progress = (current / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Objectif semaine',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textOnPrimary.withValues(alpha: 0.9),
              ),
            ),
            Text(
              '$current / $goal MoodCasts',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.textOnPrimary.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, this.light = false});

  final String label;
  final String value;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: light ? AppColors.textOnPrimary : AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: light ? AppColors.textOnPrimary.withValues(alpha: 0.9) : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
