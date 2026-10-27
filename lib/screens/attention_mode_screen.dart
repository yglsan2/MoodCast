import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/attention_mode_service.dart';
import '../services/premium_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/attention_hold_button.dart';
import 'alert_active_screen.dart';
import 'diffusion_profile_screen.dart';
import 'mood_cast_plus_screen.dart';
import 'settings_screen.dart';

/// Mode Diwall — dead-man's switch ou SOS classique (selon profil de diffusion).
class AttentionModeScreen extends StatefulWidget {
  const AttentionModeScreen({super.key});

  @override
  State<AttentionModeScreen> createState() => _AttentionModeScreenState();
}

class _AttentionModeScreenState extends State<AttentionModeScreen> {
  bool _discrete = false;
  bool _childMode = false;
  String _protectedName = '';
  String? _statusMessage;
  int _recipientCount = 0;
  int _priorityCount = 0;
  DiffusionProfile _diffusion = const DiffusionProfile();
  bool _securityPremium = false;
  int _classicLeft = 0;
  bool _classicRunning = false;

  @override
  void initState() {
    super.initState();
    _load();
    AttentionModeService.handleCheckInExpiredIfNeeded();
    AttentionModeService.restoreSession();
  }

  Future<void> _load() async {
    final discrete = await StorageService.getAttentionDiscreteMode();
    final recipients = await AttentionModeService.recipients();
    final circle = await StorageService.getSafetyCircle();
    final diffusion = await StorageService.getDiffusionProfile();
    final premium = await PremiumService.hasSecurityPremium();
    if (!mounted) return;
    setState(() {
      _discrete = discrete;
      _recipientCount = recipients.length;
      _priorityCount = recipients.where((c) => c.priority).length;
      _childMode = circle.profile.childFriendlyMode;
      _protectedName = circle.profile.displayName.trim();
      _diffusion = diffusion;
      _securityPremium = premium;
    });

    if (await StorageService.isAttentionAlertActive() && mounted) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AlertActiveScreen()),
      );
    }
  }

  Future<void> _onAlert({AttentionTriggerStyle? style}) async {
    AttentionAlertResult result;
    try {
      result = await AttentionModeService.triggerAlert(
        silentUi: _discrete,
        triggerStyle: style ?? _diffusion.defaultTrigger,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l’alerte. Réessaie ou appelle le 17 / 112.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!mounted) return;

    if (result.reason == AttentionFailReason.noContacts) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Aucun contact'),
          content: const Text(
            'Ajoute au moins un proche dans ton cercle de confiance '
            '(MoodSafe → cercle / profil de diffusion).',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Plus tard')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Paramètres')),
          ],
        ),
      );
      if (go == true && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        _load();
      }
      return;
    }

    setState(() {
      _classicRunning = false;
      _statusMessage = result.session != null
          ? 'Alerte active — ${result.session!.notifiedOrPreparedCount} destinataire(s).'
          : 'Alerte déclenchée.';
    });

    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AlertActiveScreen(session: result.session),
      ),
    );
  }

  void _onSafeCancel() {
    if (_discrete) return;
    setState(() => _statusMessage = 'Mode Diwall désactivé — tout va bien.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tout va bien — aucune alerte envoyée.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _startClassic() {
    if (_classicRunning) return;
    setState(() {
      _classicRunning = true;
      _classicLeft = _diffusion.classicCancelSeconds;
      _statusMessage = 'SOS armé — annule avant la fin du compte à rebours.';
    });
    AttentionModeService.startClassicSosCountdown(
      seconds: _diffusion.classicCancelSeconds,
      onTick: (left) {
        if (!mounted) return;
        setState(() => _classicLeft = left);
      },
      onFire: () => _onAlert(style: AttentionTriggerStyle.classicCancelWindow),
    );
  }

  void _cancelClassic() {
    AttentionModeService.cancelClassicSos();
    setState(() {
      _classicRunning = false;
      _classicLeft = 0;
      _statusMessage = 'SOS annulé.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = _discrete ? const Color(0xFF1A1819) : const Color(0xFF2A1F24);
    final fg = Colors.white.withValues(alpha: _discrete ? 0.55 : 0.92);
    final useClassic = _diffusion.defaultTrigger == AttentionTriggerStyle.classicCancelWindow;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: fg,
        title: Text(
          _discrete
              ? 'Notes'
              : (_childMode
                  ? (_protectedName.isEmpty ? 'Besoin d’aide' : 'Aide $_protectedName')
                  : 'Mode Diwall'),
          style: TextStyle(color: fg, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Profil de diffusion',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiffusionProfileScreen()),
              );
              _load();
            },
            icon: Icon(Icons.tune_rounded, color: fg),
          ),
          IconButton(
            tooltip: _discrete ? 'Mode discret activé' : 'Mode discret',
            onPressed: () async {
              final next = !_discrete;
              await StorageService.setAttentionDiscreteMode(next);
              HapticFeedback.selectionClick();
              setState(() => _discrete = next);
            },
            icon: Icon(
              _discrete ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: fg,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              if (!_discrete) ...[
                Text(
                  useClassic
                      ? 'Appuie pour armer le SOS. Tu as ${_diffusion.classicCancelSeconds} s pour annuler. '
                          'Sinon l’alerte part selon ton profil de diffusion.'
                      : (_childMode
                          ? 'Tu te sens bizarre ou pas en sécurité ?\n'
                              'Garde le doigt ${_diffusion.attentionHoldSeconds} secondes si ça va mieux.\n'
                              'Lâche le bouton → papa, maman ou tes proches sont prévenus.'
                          : 'Maintiens ${_diffusion.attentionHoldSeconds} secondes si tout va bien.\n'
                              'Relâche si ça dégénère → alerte cascade (prioritaires → cercle → sœurs).'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: fg, height: 1.45, fontSize: _childMode ? 16 : 15),
                ),
                const SizedBox(height: 10),
                Text(
                  _recipientCount > 0
                      ? (_priorityCount > 0
                          ? '★ $_priorityCount prioritaire(s) · $_recipientCount dans le cercle'
                          : '$_recipientCount proche(s) seront alertés')
                      : 'Aucun contact configuré',
                  style: TextStyle(
                    color: _recipientCount > 0 ? AppColors.accent : AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
              const Spacer(),
              if (useClassic) ...[
                if (_classicRunning)
                  Column(
                    children: [
                      Text(
                        '$_classicLeft',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _cancelClassic,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        ),
                        child: const Text('Annuler le SOS'),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: _startClassic,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withValues(alpha: 0.9),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.45),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 36,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ] else
                AttentionHoldButton(
                  discrete: _discrete,
                  holdSeconds: _diffusion.attentionHoldSeconds,
                  onAlertTriggered: () => _onAlert(),
                  onSafeCancel: _onSafeCancel,
                ),
              const Spacer(),
              if (_statusMessage != null && !_discrete)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              if (!_discrete)
                TextButton(
                  onPressed: () async {
                    if (useClassic) {
                      await StorageService.setDiffusionProfile(
                        _diffusion.copyWith(defaultTrigger: AttentionTriggerStyle.deadManSwitch),
                      );
                      setState(() {
                        _diffusion = _diffusion.copyWith(
                          defaultTrigger: AttentionTriggerStyle.deadManSwitch,
                        );
                        _classicRunning = false;
                      });
                      AttentionModeService.cancelClassicSos();
                      return;
                    }
                    if (!_securityPremium) {
                      final go = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('SOS classique — Sécurité+'),
                          content: const Text(
                            'Le SOS avec délai d’annulation fait partie de MoodCast+ (pack Sécurité+).',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Fermer'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('MoodCast+'),
                            ),
                          ],
                        ),
                      );
                      if (go == true) {
                        if (!mounted) return;
                        final nav = Navigator.of(this.context);
                        await nav.push(
                          MaterialPageRoute(builder: (_) => const MoodCastPlusScreen()),
                        );
                        if (mounted) _load();
                      }
                      return;
                    }
                    await StorageService.setDiffusionProfile(
                      _diffusion.copyWith(
                        defaultTrigger: AttentionTriggerStyle.classicCancelWindow,
                      ),
                    );
                    setState(() {
                      _diffusion = _diffusion.copyWith(
                        defaultTrigger: AttentionTriggerStyle.classicCancelWindow,
                      );
                      _classicRunning = false;
                    });
                  },
                  child: Text(
                    useClassic
                        ? 'Passer en mode Diwall (relâcher)'
                        : (_securityPremium
                            ? 'Passer en SOS classique'
                            : 'SOS classique (Sécurité+)'),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
