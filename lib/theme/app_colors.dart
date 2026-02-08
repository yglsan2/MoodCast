import 'package:flutter/material.dart';

/// Palette moderne, apaisante et un peu cool : bleu-gris doux, neutres frais, accent discret.
/// Jeune et sobre, pas flashy ni vieillot.
class AppColors {
  AppColors._();

  // ——— Bleu-gris (principal, moderne et calme) ———
  static const Color primary = Color(0xFF5B7A8F);
  static const Color primaryLight = Color(0xFF7A9AAF);
  static const Color primaryDark = Color(0xFF4A6578);

  // ——— Dégradés (cohérents, pas criards) ———
  /// Barres et boutons principaux.
  static const LinearGradient gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B7A8F), Color(0xFF6B8A9F)],
  );

  /// Écrans secondaires, cartes douces.
  static const LinearGradient gradientSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B8A9F), Color(0xFF7A9AAF)],
  );

  /// Accent (Horoscope, Biscuit, etc.) : ton chaud discret.
  static const LinearGradient gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC99B6D), Color(0xFFB8885A)],
  );

  /// WorldFlow, liens.
  static const LinearGradient gradientOcean = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B7A8F), Color(0xFF6B8A9F)],
  );

  /// Alerte / SOS.
  static const LinearGradient gradientSos = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC45C5C), Color(0xFFA84A4A)],
  );

  // ——— Alias ———
  static const LinearGradient gradientCalm = gradientSecondary;
  static const LinearGradient gradientWarm = gradientAccent;
  static const LinearGradient gradientSunrise = gradientAccent;
  static const LinearGradient gradientForest = gradientSecondary;
  static const LinearGradient gradientCosmic = gradientPrimary;

  // ——— Couleurs plates ———
  static const Color accent = Color(0xFFC99B6D);
  static const Color teal = Color(0xFF6B8A9F);
  static const Color coral = Color(0xFFC45C5C);

  // ——— Émotions (nuances lisibles, harmonie avec la palette) ———
  static const Map<String, Color> emotionColors = {
    'joie': Color(0xFF5B9A6B),
    'heureux': Color(0xFF5B9A6B),
    'sérénité': Color(0xFF6B8A9F),
    'calme': Color(0xFF7A9AAF),
    'enthousiasme': Color(0xFFC99B6D),
    'gratitude': Color(0xFFB8A050),
    'motivation': Color(0xFF5B7A8F),
    'espoir': Color(0xFF5B9A6B),
    'amour': Color(0xFFC97A8A),
    'confiance': Color(0xFF5B7A8F),
    'détente': Color(0xFF7A9AAF),
    'inspiration': Color(0xFF9A7AB8),
    'fierté': Color(0xFFC99B6D),
    'tendresse': Color(0xFFC97A8A),
    'curiosité': Color(0xFF7A9AAF),
    'optimisme': Color(0xFF5B9A6B),
    'légèreté': Color(0xFFB8A050),
    'bienveillance': Color(0xFF5B9A6B),
    'créativité': Color(0xFF9A7AB8),
    'nostalgie': Color(0xFF8A7A9F),
    'doute': Color(0xFF8A8580),
    'stress': Color(0xFFC45C5C),
    'anxiété': Color(0xFFB8885A),
    'fatigue': Color(0xFF7A7A7A),
    'tristesse': Color(0xFF6B8A9F),
    'mélancolie': Color(0xFF8A7A9F),
    'colere': Color(0xFFC45C5C),
    'irritation': Color(0xFFC99B6D),
    'inquiétude': Color(0xFFB8885A),
  };

  static Color emotionColor(String? emotion) {
    if (emotion == null) return const Color(0xFF7A7A7A);
    return emotionColors[emotion] ?? emotionColors[emotion.toLowerCase()] ?? const Color(0xFF7A7A7A);
  }

  static const Color success = Color(0xFF5B9A6B);
  static const Color warning = Color(0xFFB8A050);
  static const Color error = Color(0xFFC45C5C);
  static const Color info = Color(0xFF6B8A9F);

  // ——— Surfaces et texte (fond frais, lisible) ———
  static const Color background = Color(0xFFF4F6F8);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFEBEEF2);
  static const Color textPrimary = Color(0xFF1E252B);
  static const Color textSecondary = Color(0xFF5E6B78);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
}
