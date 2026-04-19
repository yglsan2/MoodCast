import 'storage_service.dart';

/// MoodCast+ : couche monétisation **locale** (essai + codes promo).
/// Brancher RevenueCat / Play Billing / StoreKit ici quand les comptes développeur sont prêts.
class PremiumService {
  PremiumService._();

  /// Styles podcast réservés aux abonné·es (les plus « signature »).
  static const Set<String> premiumOnlyStyles = {'poesie', 'energie'};

  static Future<bool> isPremium() async {
    if (await StorageService.isLifetimePremium()) return true;
    final until = await StorageService.getPremiumUntil();
    return until != null && until.isAfter(DateTime.now());
  }

  /// Date de fin d’entitlement, ou null (sans abonnement time-bound).
  static Future<DateTime?> entitlementEnd() async {
    if (await StorageService.isLifetimePremium()) return null;
    return StorageService.getPremiumUntil();
  }

  /// Prolonge l’accès à partir de max(maintenant, fin actuelle).
  static Future<void> extendPremium(Duration duration) async {
    final now = DateTime.now();
    final current = await StorageService.getPremiumUntil();
    final base = (current != null && current.isAfter(now)) ? current : now;
    await StorageService.setPremiumUntil(base.add(duration));
  }

  /// 7 jours offerts, une fois par installation (marketing / rétention).
  static Future<String?> startFreeTrialIfEligible() async {
    if (await StorageService.isLifetimePremium()) {
      return 'Tu as déjà un accès illimité MoodCast+.';
    }
    if (await StorageService.hasConsumedFreeTrial()) {
      return 'L’essai gratuit a déjà été utilisé sur cet appareil. Utilise un code promo ou abonne-toi bientôt sur les stores.';
    }
    await extendPremium(const Duration(days: 7));
    await StorageService.setHasConsumedFreeTrial(true);
    return null;
  }

  /// Codes promo marketing / ambassadrices (majuscules, sans espace superflu).
  static Future<String?> redeemCode(String raw) async {
    final c = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (c.isEmpty) return 'Saisis un code.';

    switch (c) {
      case 'MOODPLUS7':
      case 'MOODCAST+':
        await extendPremium(const Duration(days: 7));
        return null;
      case 'BIENVENUE30':
      case 'MOOD30':
        await extendPremium(const Duration(days: 30));
        return null;
      case 'LUMIERE':
      case 'FOREVER':
        await StorageService.setLifetimePremium(true);
        await StorageService.setPremiumUntil(null);
        return null;
      default:
        return 'Code inconnu. Vérifie les majuscules ou demande un code à l’équipe MoodCast.';
    }
  }

  /// Texte « plan d’action » hebdo (contenu MoodCast+).
  static String weeklyDeepPlan(String dominantEmotion, int moodCastsThisWeek) {
    final label = dominantEmotion;
    if (moodCastsThisWeek >= 5) {
      return 'Cette semaine tu t’es beaucoup écouté·e — bravo. Pour $label : garde 2 créneaux « sans écran » de 10 min ; réutilise un MoodCast qui t’a fait du bien en re-lecture audio.';
    }
    if (moodCastsThisWeek >= 2) {
      return 'Tu poses des repères, c’est le bon rythme. Pour $label : un rituel MoodRoutine le matin + un MoodCast le soir 3 jours cette semaine suffisent à stabiliser ton ressenti.';
    }
    return 'Chaque semaine compte. Pour $label : vise 3 mini check-ins vocaux (MoodCast) aux mêmes horaires — ton cerveau associera vite la voix au calme.';
  }
}
