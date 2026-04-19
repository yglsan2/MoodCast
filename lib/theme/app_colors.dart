import 'package:flutter/material.dart';

/// Charte unifiée « rose thé & mauve poudré » : une seule famille de teintes
/// (chaud, doux, premium), accents et émotions dérivés pour cohérence visuelle.
class AppColors {
  AppColors._();

  // ——— Marque (déclinaisons d’un même mauve-rose) ———
  static const Color primary = Color(0xFF6E5A66);
  static const Color primaryLight = Color(0xFF8E7A82);
  static const Color primaryDark = Color(0xFF5A4A55);

  /// Compagnon (liens, WorldFlow) — même température que le primaire.
  static const Color secondary = Color(0xFF7D6E78);
  static const Color teal = secondary;

  /// Accent chaud (récompenses, soleil) — reste dans les roses désaturés.
  static const Color accent = Color(0xFFC9A399);
  static const Color accentDeep = Color(0xFFB08A82);

  static const Color coral = Color(0xFFC4776E);

  // ——— Dégradés (tous basés sur primary / accent, pas de teal isolé) ———
  static const LinearGradient gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B7380), Color(0xFF6E5A66)],
  );

  static const LinearGradient gradientSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7D6E78), Color(0xFF6A5C68)],
  );

  static const LinearGradient gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4B5AD), Color(0xFFC9A399)],
  );

  static const LinearGradient gradientOcean = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7A6B76), Color(0xFF6E5A66)],
  );

  static const LinearGradient gradientSos = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC45C6A), Color(0xFF9E4D5C)],
  );

  /// Fond écran : crème rosé très léger (cohérent avec les cartes).
  static const LinearGradient scaffoldWash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFBFA),
      Color(0xFFFBF6F4),
      Color(0xFFF5EEEB),
    ],
  );

  static const LinearGradient gradientCalm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9A8A92), Color(0xFF7D6E78)],
  );

  static const LinearGradient gradientWarm = gradientAccent;
  static const LinearGradient gradientSunrise = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8C4B8), Color(0xFFD4A896)],
  );
  static const LinearGradient gradientForest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8A9B8E), Color(0xFF6E7D72)],
  );
  static const LinearGradient gradientCosmic = gradientPrimary;

  /// Émotions : restent dans mauve / rose / sauge doux (pas de verts criards ni bleus froids).
  static const Map<String, Color> emotionColors = {
    'joie': Color(0xFF7FA08A),
    'heureux': Color(0xFF7FA08A),
    'sérénité': Color(0xFF8E7A82),
    'calme': Color(0xFF9A8A92),
    'enthousiasme': Color(0xFFD4A896),
    'gratitude': Color(0xFFC4A574),
    'motivation': Color(0xFF6E5A66),
    'espoir': Color(0xFF8FA896),
    'amour': Color(0xFFC98FA0),
    'confiance': Color(0xFF7D6E78),
    'détente': Color(0xFF9A8A92),
    'inspiration': Color(0xFFA892B8),
    'fierté': Color(0xFFD4A896),
    'tendresse': Color(0xFFC98FA0),
    'curiosité': Color(0xFF8E7A82),
    'optimisme': Color(0xFF7FA08A),
    'légèreté': Color(0xFFC4B89A),
    'bienveillance': Color(0xFF8FA896),
    'créativité': Color(0xFFA892B8),
    'nostalgie': Color(0xFF8E7E8A),
    'doute': Color(0xFF918A8E),
    'stress': Color(0xFFC4776E),
    'anxiété': Color(0xFFC9A399),
    'fatigue': Color(0xFF8E868A),
    'tristesse': Color(0xFF7D8A96),
    'mélancolie': Color(0xFF8E7E8A),
    'colere': Color(0xFFC45C5C),
    'irritation': Color(0xFFD4A896),
    'inquiétude': Color(0xFFC9A399),
  };

  static Color emotionColor(String? emotion) {
    if (emotion == null) return const Color(0xFF8E868A);
    return emotionColors[emotion] ?? emotionColors[emotion.toLowerCase()] ?? const Color(0xFF8E868A);
  }

  static const Color success = Color(0xFF7FA08A);
  static const Color warning = Color(0xFFC4A574);
  static const Color error = Color(0xFFC45C6A);
  static const Color info = Color(0xFF8E7A82);

  static const Color background = Color(0xFFFBF6F4);
  static const Color cardBackground = Color(0xFFFFFEFE);
  static const Color surface = Color(0xFFF0E8E5);
  static const Color textPrimary = Color(0xFF2D2428);
  static const Color textSecondary = Color(0xFF6B6066);
  static const Color textOnPrimary = Color(0xFFFFFBFA);
}
