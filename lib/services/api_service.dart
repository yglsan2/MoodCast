import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/analysis_result.dart';
import '../models/emotions.dart';
import '../models/mood_cast.dart';
import '../models/world_flow_data.dart';
import 'podcast_service.dart';

class ApiService {
  ApiService._();

  static final baseUrl = AppConfig.apiBaseUrl;

  /// Envoie les données d'humeur anonymisées à WorldFlow.
  static Future<bool> uploadMoodData({
    required String emotion,
    required int intensity,
    required int energy,
    MoodLocation? location,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/mood-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emotion': emotion,
          'intensity': intensity,
          'energy': energy,
          'location': location?.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Récupère les données WorldFlow pour la carte.
  static Future<WorldFlowData> fetchWorldFlowData({String timeFilter = 'today'}) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/worldflow').replace(queryParameters: {'filter': timeFilter}),
      );
      if (res.statusCode == 200) {
        return WorldFlowData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return _demoWorldFlowData();
  }

  /// Analyse d'humeur. Retourne null si pas d'audio ou si l'API échoue (on ne simule jamais).
  static Future<MoodAnalysisResult?> analyzeMood({String? audioUri}) async {
    if (audioUri == null || audioUri.isEmpty) return null;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/analyze-mood'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'audio': null, 'audioUri': audioUri}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rawEmotion = data['emotion'] as String?;
        final intensity = data['intensity'] as num?;
        final energy = data['energy'] as num?;
        if (rawEmotion != null && rawEmotion.toString().trim().isNotEmpty) {
          return MoodAnalysisResult(
            emotion: Emotions.normalize(rawEmotion.toString().trim()),
            intensity: (intensity ?? 5).toInt().clamp(1, 10),
            energy: (energy ?? 5).toInt().clamp(1, 10),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Génère le texte du podcast (backend ou fallback une fois l'analyse réelle obtenue).
  static Future<PodcastResult> generatePodcast({
    required String emotion,
    required int intensity,
    required int energy,
    required String style,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/generate-podcast'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emotion': emotion,
          'intensity': intensity,
          'energy': energy,
          'style': style,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return PodcastResult(
          text: data['text'] as String? ?? '',
          style: data['style'] as String? ?? style,
        );
      }
    } catch (_) {}
    return PodcastService.fallbackPodcast(emotion, style);
  }

  static WorldFlowData _demoWorldFlowData() {
    return const WorldFlowData(
      totalMoodCasts: 1234,
      uniqueRegions: 5,
      globalTrend: 'Positif',
      trends: [
        'Paris est joyeux ce matin',
        'Tokyo montre une énergie élevée',
        'New York est motivé',
      ],
      regions: [
        WorldFlowRegion(name: 'Paris, France', latitude: 48.8566, longitude: 2.3522, dominantEmotion: 'joie', averageIntensity: 7.5, averageEnergy: 8.0),
        WorldFlowRegion(name: 'Tokyo, Japon', latitude: 35.6762, longitude: 139.6503, dominantEmotion: 'motivation', averageIntensity: 8.2, averageEnergy: 8.5),
        WorldFlowRegion(name: 'New York, USA', latitude: 40.7128, longitude: -74.006, dominantEmotion: 'motivation', averageIntensity: 7.8, averageEnergy: 7.9),
        WorldFlowRegion(name: 'Londres, UK', latitude: 51.5074, longitude: -0.1278, dominantEmotion: 'fatigue', averageIntensity: 6.0, averageEnergy: 5.5),
        WorldFlowRegion(name: 'Sydney, Australie', latitude: -33.8688, longitude: 151.2093, dominantEmotion: 'joie', averageIntensity: 8.5, averageEnergy: 8.8),
      ],
    );
  }
}
