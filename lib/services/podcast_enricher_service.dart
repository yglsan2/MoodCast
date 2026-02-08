import 'horoscope_service.dart';
import 'storage_service.dart';

/// Enrichit le texte du podcast MoodCast avec les 3 couches :
/// 1. Ton mood du jour (déjà dans [baseText])
/// 2. Ton thème astral (profil permanent, si date de naissance enregistrée)
/// 3. Les transits du jour (phase lunaire)
class PodcastEnricherService {
  PodcastEnricherService._();

  static const String _separator = '\n\n—\n\n';

  /// Retourne le texte du podcast enrichi avec thème astral et transits du jour.
  static Future<String> enrich(String baseText) async {
    final today = DateTime.now();
    final parts = <String>[baseText];

    final birthDate = await StorageService.getBirthDate();
    if (birthDate != null) {
      parts.add(HoroscopeService.getPodcastAstroBlock(birthDate));
    }

    parts.add(HoroscopeService.getPodcastTransitBlock(today));

    return parts.join(_separator);
  }
}
