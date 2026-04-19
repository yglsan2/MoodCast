import 'storage_service.dart';

/// Analyse les jours de la semaine où l'utilisateur a le plus souvent un mood "bas" (stress, tristesse, fatigue, etc.).
class RiskDaysService {
  RiskDaysService._();

  static const List<String> _lowMoodEmotions = [
    'stress',
    'anxiété',
    'fatigue',
    'tristesse',
    'mélancolie',
    'colere',
    'irritation',
    'doute',
    'inquiétude',
  ];

  /// Retourne les indices de semaine (1 = lundi, 7 = dimanche) où la part de "mood bas" est la plus élevée.
  /// [limit] = nombre max de jours à retourner (ex. 2 pour "souvent le lundi et le vendredi").
  static Future<List<int>> getRiskWeekdays({int limit = 2}) async {
    final list = await StorageService.getMoodCasts();
    if (list.length < 5) return [];

    final byWeekday = <int, List<String>>{};
    for (int i = 1; i <= 7; i++) {
      byWeekday[i] = [];
    }
    for (final c in list) {
      byWeekday[c.timestamp.weekday]!.add(c.emotion);
    }

    final ratios = <int, double>{};
    for (int w = 1; w <= 7; w++) {
      final emotions = byWeekday[w]!;
      if (emotions.isEmpty) {
        ratios[w] = 0;
        continue;
      }
      final lowCount = emotions.where((e) => _lowMoodEmotions.contains(e)).length;
      ratios[w] = lowCount / emotions.length;
    }

    final sorted = ratios.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .where((e) => e.value > 0)
        .take(limit)
        .map((e) => e.key)
        .toList();
  }

  static String weekdayName(int weekday) {
    const names = ['', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    return names[weekday];
  }

  static String weekdayNameCap(int weekday) {
    final n = weekdayName(weekday);
    return n.isEmpty ? n : n[0].toUpperCase() + n.substring(1);
  }
}
