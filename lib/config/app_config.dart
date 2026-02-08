/// Configuration de l'application (API, clés optionnelles).
class AppConfig {
  AppConfig._();

  /// URL du backend. En dev sur appareil réel, utiliser votre IP locale (ex. http://192.168.1.x:3000).
  static const String apiBaseUrl = 'http://localhost:3000';

  static const String openAiApiKey = ''; // optionnel
  static const String googleMapsApiKey = ''; // optionnel (flutter_map utilise OSM par défaut)
}
