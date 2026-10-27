import '../models/mood_safe_session.dart';
import 'attention_mode_service.dart';
import 'premium_service.dart';
import 'sister_aid_service.dart';
import 'storage_service.dart';

/// Synthèse « prêt à alerter » pour l’UX MoodSafe.
class MoodSafeReadiness {
  const MoodSafeReadiness({
    required this.contactCount,
    required this.priorityCount,
    required this.hasDeactivateCode,
    required this.hasFakeCode,
    required this.holdSeconds,
    required this.securityPremium,
    required this.diffusion,
    required this.sisterEnabled,
    required this.sisterPeerCount,
    required this.alertActive,
    required this.systemState,
    required this.protectedName,
  });

  final int contactCount;
  final int priorityCount;
  final bool hasDeactivateCode;
  final bool hasFakeCode;
  final int holdSeconds;
  final bool securityPremium;
  final DiffusionProfile diffusion;
  final bool sisterEnabled;
  final int sisterPeerCount;
  final bool alertActive;
  final MoodSafeSystemState systemState;
  final String protectedName;

  bool get canAlert => contactCount > 0;
  bool get isFullyReady =>
      canAlert && priorityCount > 0 && hasDeactivateCode;

  String get holdLabel =>
      securityPremium ? '$holdSeconds s (Sécurité+)' : '$holdSeconds s (défaut)';

  String get triggerLabel => diffusion.defaultTrigger == AttentionTriggerStyle.classicCancelWindow
      ? 'SOS classique · ${diffusion.classicCancelSeconds} s'
      : 'Diwall · maintien $holdSeconds s';

  List<String> get missingSteps {
    final out = <String>[];
    if (contactCount == 0) out.add('Ajoute au moins un contact de confiance');
    if (priorityCount == 0 && contactCount > 0) {
      out.add('Marque un contact ★ prioritaire (parent recommandé)');
    }
    if (!hasDeactivateCode) out.add('Définis un code de désactivation (4 chiffres)');
    return out;
  }

  static Future<MoodSafeReadiness> load() async {
    final recipients = await AttentionModeService.recipients();
    final circle = await StorageService.getSafetyCircle();
    final diffusion = await StorageService.getDiffusionProfile();
    final premium = await PremiumService.hasSecurityPremium();
    final code = await StorageService.getMoodSafeCode();
    final fake = await StorageService.getMoodSafeFakeCode();
    final active = await StorageService.isAttentionAlertActive();
    final state = await AttentionModeService.systemState();
    final sisters = await SisterAidService.getNetwork();

    final hold = premium
        ? diffusion.attentionHoldSeconds.clamp(2, 10)
        : PremiumService.freeAttentionHoldSeconds;

    return MoodSafeReadiness(
      contactCount: recipients.length,
      priorityCount: recipients.where((c) => c.priority).length,
      hasDeactivateCode: code != null && code.length == 4,
      hasFakeCode: fake != null && fake.length == 4,
      holdSeconds: hold,
      securityPremium: premium,
      diffusion: diffusion,
      sisterEnabled: sisters.profile.canUseSisterNetwork,
      sisterPeerCount: sisters.peers.length,
      alertActive: active,
      systemState: state,
      protectedName: circle.profile.displayName.trim(),
    );
  }
}
