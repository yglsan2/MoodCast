import '../models/mood_cast.dart';
import 'storage_service.dart';

/// Série de jours consécutifs avec au moins un MoodCast.
/// Jours en date locale (sans heure).
class StreakService {
  StreakService._();

  static String _dateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Liste des dates (yyyy-MM-dd) ayant au moins un MoodCast, triée du plus récent au plus ancien.
  static List<String> _datesWithMoodCast(List<MoodCast> list) {
    final set = <String>{};
    for (final c in list) {
      set.add(_dateKey(DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day)));
    }
    final list2 = set.toList()..sort((a, b) => b.compareTo(a));
    return list2;
  }

  /// Série actuelle : nombre de jours consécutifs (en partant d'aujourd'hui) avec au moins un MoodCast.
  static int currentStreak(List<MoodCast> list) {
    final datesSet = _datesWithMoodCast(list).toSet();
    if (datesSet.isEmpty) return 0;
    var d = DateTime.now();
    int count = 0;
    while (datesSet.contains(_dateKey(d))) {
      count++;
      d = d.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// Meilleure série sur tout l'historique (plus longue suite de jours consécutifs).
  static int bestStreak(List<MoodCast> list) {
    final dates = _datesWithMoodCast(list);
    if (dates.isEmpty) return 0;
    int max = 1;
    int current = 1;
    for (int i = 1; i < dates.length; i++) {
      final prev = DateTime.parse(dates[i - 1]);
      final curr = DateTime.parse(dates[i]);
      final diff = prev.difference(curr).inDays;
      if (diff == 1) {
        current++;
        if (current > max) max = current;
      } else {
        current = 1;
      }
    }
    return max;
  }

  /// Calcule streaks et débloque les badges si conditions remplies.
  static Future<StreakResult> getResult() async {
    final list = await StorageService.getMoodCasts();
    final current = currentStreak(list);
    final best = bestStreak(list);
    final total = list.length;

    final unlocked = await StorageService.getUnlockedBadges();
    final toUnlock = <String>[];
    if (total >= 1 && !unlocked.contains('first_moodcast')) {
      toUnlock.add('first_moodcast');
    }
    if (current >= 3 && !unlocked.contains('streak_3')) {
      toUnlock.add('streak_3');
    }
    if (current >= 7 && !unlocked.contains('streak_7')) {
      toUnlock.add('streak_7');
    }
    if (best >= 7 && !unlocked.contains('best_7')) {
      toUnlock.add('best_7');
    }
    for (final id in toUnlock) {
      await StorageService.addUnlockedBadge(id);
    }
    final allBadges = [...unlocked, ...toUnlock];

    return StreakResult(
      currentStreak: current,
      bestStreak: best,
      totalMoodCasts: total,
      badges: allBadges,
      newBadges: toUnlock,
    );
  }
}

class StreakResult {
  const StreakResult({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalMoodCasts,
    required this.badges,
    required this.newBadges,
  });

  final int currentStreak;
  final int bestStreak;
  final int totalMoodCasts;
  final List<String> badges;
  final List<String> newBadges;
}
