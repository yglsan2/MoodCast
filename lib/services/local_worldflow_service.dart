import '../models/mood_cast.dart';
import '../models/world_flow_data.dart';
import 'storage_service.dart';

/// WorldFlow **100 % local** : agrège tes MoodCasts (stockage sur l’appareil), sans serveur.
class LocalWorldFlowService {
  LocalWorldFlowService._();

  static DateTime _cutoff(String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return now.subtract(const Duration(days: 30));
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  static String _topEmotion(List<MoodCast> list) {
    final counts = <String, int>{};
    for (final c in list) {
      counts[c.emotion] = (counts[c.emotion] ?? 0) + 1;
    }
    if (counts.isEmpty) return '—';
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static Future<WorldFlowData> build({String timeFilter = 'today'}) async {
    final all = await StorageService.getMoodCasts();
    final cutoff = _cutoff(timeFilter);
    final filtered = all.where((c) => !c.timestamp.isBefore(cutoff)).toList();
    final withLoc = filtered.where((c) => c.location != null).toList();

    if (withLoc.isEmpty) {
      return WorldFlowData(
        totalMoodCasts: filtered.length,
        uniqueRegions: 0,
        globalTrend: filtered.isEmpty ? '—' : 'Humeurs enregistrées',
        trends: [
          if (filtered.isEmpty)
            'Aucun MoodCast sur cette période.'
          else
            'Active la position lors d’un MoodCast pour voir tes points sur la carte (données uniquement sur cet appareil).',
        ],
        regions: [],
      );
    }

    final buckets = <String, List<MoodCast>>{};
    for (final c in withLoc) {
      final lat = (c.location!.latitude * 2).round() / 2.0;
      final lng = (c.location!.longitude * 2).round() / 2.0;
      final key = '${lat.toStringAsFixed(1)}_${lng.toStringAsFixed(1)}';
      buckets.putIfAbsent(key, () => []).add(c);
    }

    final regions = buckets.entries.map((e) {
      final list = e.value;
      final emotionCounts = <String, int>{};
      for (final c in list) {
        emotionCounts[c.emotion] = (emotionCounts[c.emotion] ?? 0) + 1;
      }
      var dom = 'motivation';
      var best = 0;
      emotionCounts.forEach((k, v) {
        if (v > best) {
          best = v;
          dom = k;
        }
      });
      final avgI = list.map((c) => c.intensity).reduce((a, b) => a + b) / list.length;
      final avgE = list.map((c) => c.energy).reduce((a, b) => a + b) / list.length;
      final loc = list.first.location!;
      return WorldFlowRegion(
        name: list.length > 1 ? 'Zone (${list.length} MoodCasts)' : 'Ton MoodCast',
        latitude: loc.latitude,
        longitude: loc.longitude,
        dominantEmotion: dom,
        averageIntensity: avgI,
        averageEnergy: avgE,
        description: '${list.length} enregistrement(s) — données locales',
      );
    }).toList();

    const positive = {
      'joie', 'heureux', 'sérénité', 'calme', 'enthousiasme', 'gratitude', 'motivation', 'espoir', 'amour',
      'confiance', 'détente', 'inspiration', 'fierté', 'tendresse', 'curiosité', 'optimisme', 'légèreté',
      'bienveillance', 'créativité',
    };
    const negative = {'stress', 'anxiété', 'fatigue', 'tristesse', 'mélancolie', 'colere', 'irritation', 'inquiétude'};
    var pos = 0, neg = 0;
    for (final c in filtered) {
      if (positive.contains(c.emotion)) pos++;
      if (negative.contains(c.emotion)) neg++;
    }
    var trend = 'Stable';
    if (pos > neg * 1.2) trend = 'Plutôt positif';
    if (neg > pos * 1.2) trend = 'Plus difficile';

    final trends = <String>[
      'Carte calculée sur ton téléphone à partir de tes MoodCasts.',
      'Émotion la plus fréquente : ${_topEmotion(filtered)}',
    ];

    return WorldFlowData(
      totalMoodCasts: filtered.length,
      uniqueRegions: regions.length,
      globalTrend: trend,
      trends: trends,
      regions: regions,
    );
  }
}
