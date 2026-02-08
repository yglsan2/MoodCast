/// Liste étendue d'émotions pour une détection plus précise.
/// Plus de choix = moins anxiogène, plus de nuances (positifs en premier).
/// Le backend peut renvoyer une de ces valeurs ou une valeur proche (mapping ci-dessous).
class Emotions {
  Emotions._();

  /// Toutes les émotions : positifs et agréables d'abord, puis neutres, puis plus difficiles.
  static const List<String> all = [
    // Positifs / agréables
    'joie',
    'heureux',
    'sérénité',
    'calme',
    'enthousiasme',
    'gratitude',
    'motivation',
    'espoir',
    'amour',
    'confiance',
    'détente',
    'inspiration',
    'fierté',
    'tendresse',
    'curiosité',
    'optimisme',
    'légèreté',
    'bienveillance',
    'créativité',
    // Neutres / mixtes
    'nostalgie',
    'doute',
    // Plus difficiles
    'stress',
    'anxiété',
    'fatigue',
    'tristesse',
    'mélancolie',
    'colere',
    'irritation',
    'inquiétude',
  ];

  /// Associe une réponse API (ex: "joie") à notre liste étendue.
  static String normalize(String? apiEmotion) {
    if (apiEmotion == null || apiEmotion.isEmpty) return 'motivation';
    final lower = apiEmotion.toLowerCase().trim();
    if (all.contains(lower)) return lower;
    const mapping = {
      'joy': 'joie',
      'happy': 'heureux',
      'joyeux': 'joie',
      'calm': 'calme',
      'peaceful': 'sérénité',
      'excited': 'enthousiasme',
      'grateful': 'gratitude',
      'anxious': 'anxiété',
      'worried': 'inquiétude',
      'tired': 'fatigue',
      'sad': 'tristesse',
      'melancholy': 'mélancolie',
      'angry': 'colere',
      'irritated': 'irritation',
      'doubt': 'doute',
      'hopeful': 'espoir',
      'love': 'amour',
      'relaxed': 'détente',
      'inspired': 'inspiration',
      'proud': 'fierté',
      'tender': 'tendresse',
      'curious': 'curiosité',
      'optimistic': 'optimisme',
      'creative': 'créativité',
      'nostalgic': 'nostalgie',
    };
    return mapping[lower] ?? lower;
  }

  static String label(String emotion) {
    switch (emotion) {
      case 'joie': return 'Joie';
      case 'heureux': return 'Heureux';
      case 'sérénité': return 'Sérénité';
      case 'calme': return 'Calme';
      case 'enthousiasme': return 'Enthousiasme';
      case 'gratitude': return 'Gratitude';
      case 'motivation': return 'Motivation';
      case 'espoir': return 'Espoir';
      case 'amour': return 'Amour';
      case 'confiance': return 'Confiance';
      case 'détente': return 'Détente';
      case 'inspiration': return 'Inspiration';
      case 'fierté': return 'Fierté';
      case 'tendresse': return 'Tendresse';
      case 'curiosité': return 'Curiosité';
      case 'optimisme': return 'Optimisme';
      case 'légèreté': return 'Légèreté';
      case 'bienveillance': return 'Bienveillance';
      case 'créativité': return 'Créativité';
      case 'nostalgie': return 'Nostalgie';
      case 'doute': return 'Doute';
      case 'stress': return 'Stress';
      case 'anxiété': return 'Anxiété';
      case 'fatigue': return 'Fatigue';
      case 'tristesse': return 'Tristesse';
      case 'mélancolie': return 'Mélancolie';
      case 'colere': return 'Colère';
      case 'irritation': return 'Irritation';
      case 'inquiétude': return 'Inquiétude';
      default: return emotion.isNotEmpty ? emotion[0].toUpperCase() + emotion.substring(1) : 'Humeur';
    }
  }
}
