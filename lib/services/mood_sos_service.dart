import '../models/analysis_result.dart';
import 'horoscope_service.dart';
import 'podcast_service.dart';
import 'storage_service.dart';

/// Génère un podcast de soutien personnalisé (option C : encouragements automatiques).
/// Adapté au mood, au thème astral et à l'énergie.
class MoodSosService {
  MoodSosService._();

  /// Retourne un texte d'encouragement à lire (TTS) : zen + astro si dispo.
  static Future<PodcastResult> generateSupportPodcast() async {
    final moodCasts = await StorageService.getMoodCasts();
    moodCasts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final emotion = moodCasts.isNotEmpty ? moodCasts.first.emotion : 'stress';

    final base = PodcastService.fallbackPodcast(emotion, 'zen');
    final birthDate = await StorageService.getBirthDate();
    var text = base.text;

    if (birthDate != null) {
      final transit = HoroscopeService.getPodcastTransitBlock(DateTime.now());
      text += '\n\n—\n\nPrends soin de toi : la Lune et les transits du jour t\'accompagnent. $transit';
    } else {
      text += '\n\n—\n\nPrends soin de toi. Tu n\'es pas seul(e).';
    }

    return PodcastResult(text: text, style: 'zen');
  }
}
