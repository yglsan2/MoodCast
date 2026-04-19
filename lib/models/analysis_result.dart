// Résultat d'analyse d'humeur et de génération de podcast (partagé entre API et services).

class MoodAnalysisResult {
  const MoodAnalysisResult({
    required this.emotion,
    required this.intensity,
    required this.energy,
  });

  final String emotion;
  final int intensity;
  final int energy;
}

class PodcastResult {
  const PodcastResult({required this.text, required this.style});

  final String text;
  final String style;
}
