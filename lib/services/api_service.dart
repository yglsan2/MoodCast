import '../models/analysis_result.dart';
import '../models/mood_cast.dart';
import '../models/world_flow_data.dart';
import 'local_worldflow_service.dart';
import 'podcast_service.dart';

/// Couche « API » **entièrement locale** : pas de serveur MoodCast, tout sur l’appareil.
class ApiService {
  ApiService._();

  /// Podcast : textes embarqués selon l’humeur et le style.
  static Future<PodcastResult> generatePodcast({
    required String emotion,
    required int intensity,
    required int energy,
    required String style,
  }) async {
    return PodcastService.fallbackPodcast(emotion, style);
  }

  /// Toujours OK : rien n’est envoyé sur Internet (les données restent dans [StorageService]).
  static Future<bool> uploadMoodData({
    required String emotion,
    required int intensity,
    required int energy,
    MoodLocation? location,
  }) async {
    return true;
  }

  /// WorldFlow à partir de tes MoodCasts enregistrés sur l’appareil.
  static Future<WorldFlowData> fetchWorldFlowData({String timeFilter = 'today'}) {
    return LocalWorldFlowService.build(timeFilter: timeFilter);
  }
}
