import 'package:flutter/material.dart';

import '../services/attention_mode_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';
import 'alert_active_screen.dart';
import 'attention_mode_screen.dart';
import 'diffusion_profile_screen.dart';
import 'protected_setup_screen.dart';
import 'safety_circle_screen.dart';
import 'settings_screen.dart';
import 'sister_aid_screen.dart';
import 'mood_sos_screen.dart';

/// MoodSafe : hub sécurité — Mode Diwall, check-in, codes, test notif.
class MoodSafeScreen extends StatefulWidget {
  const MoodSafeScreen({super.key});

  @override
  State<MoodSafeScreen> createState() => _MoodSafeScreenState();
}

class _MoodSafeScreenState extends State<MoodSafeScreen> {
  int _contactCount = 0;
  int _priorityCount = 0;
  String _protectedName = '';
  bool _setupDone = false;
  DateTime? _checkInUntil;
  bool _alertActive = false;
  MoodSafeSystemState _systemState = MoodSafeSystemState.veille;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final recipients = await AttentionModeService.recipients();
    final until = await StorageService.getAttentionCheckInUntil();
    final active = await StorageService.isAttentionAlertActive();
    final circle = await StorageService.getSafetyCircle();
    final state = await AttentionModeService.systemState();
    if (!mounted) return;
    setState(() {
      _contactCount = recipients.length;
      _priorityCount = recipients.where((c) => c.priority).length;
      _checkInUntil = until;
      _alertActive = active;
      _systemState = state;
      _protectedName = circle.profile.displayName.trim();
      _setupDone = circle.profile.setupCompleted || circle.contacts.isNotEmpty;
    });
  }

  static Future<void> _showDeactivateDialog(BuildContext context) async {
    final codeController = TextEditingController();
    final entered = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Désactiver l\'alerte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez votre code de désactivation (4 chiffres).'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Code',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, codeController.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (entered == null || !context.mounted) return;
    final ok = await AttentionModeService.deactivateWithCode(entered);
    if (!context.mounted) return;

    final realCode = await StorageService.getMoodSafeCode();
    final fakeCode = await StorageService.getMoodSafeFakeCode();
    if (!context.mounted) return;
    final isReal = realCode != null && entered == realCode;
    final isFake = fakeCode != null && entered == fakeCode;

    if (ok && isReal) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Alerte désactivée'),
          content: const Text('L\'alerte a bien été désactivée. Le partage de position est arrêté.'),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    } else if (ok && isFake) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Alerte désactivée'),
          content: const Text(
            'L\'alerte semble désactivée. En cas de besoin, vos proches peuvent toujours être informés.',
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Code incorrect'),
          content: const Text('Le code saisi ne correspond pas. Réessayez.'),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Future<void> _startCheckIn(Duration duration) async {
    await AttentionModeService.scheduleCheckIn(duration);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Check-in dans ${duration.inMinutes} min. Confirme « Je vais bien » avant, sinon alerte auto.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final checkInActive = _checkInUntil != null && _checkInUntil!.isAfter(DateTime.now());

    return Scaffold(
      appBar: const GradientAppBar(
        title: '🛡️ MoodSafe',
        gradient: AppColors.gradientSecondary,
      ),
      body: Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    _alertActive ? Icons.warning_amber_rounded : Icons.shield_moon_rounded,
                    color: _alertActive ? AppColors.error : AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'État MoodSafe : ${_systemState.labelFr}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          _alertActive
                              ? 'Suivi position actif · ouvre le détail d’alerte'
                              : 'Veille · Diwall / cercles / Lien Sœurs prêts',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (_alertActive)
                    TextButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AlertActiveScreen()),
                        );
                        _refresh();
                      },
                      child: const Text('Voir'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FeelGoodCard(
              margin: EdgeInsets.zero,
              gradient: AppColors.gradientSos,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _protectedName.isEmpty
                        ? 'Mode Diwall'
                        : 'Sécurité · $_protectedName',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Style cercle de confiance : parents et proches prioritaires d’abord, '
                    'puis amis / famille. Maintiens le bouton le temps configuré si tout va bien ; lâche → alerte + position.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _contactCount > 0
                        ? '★ $_priorityCount prioritaire(s) · $_contactCount dans le cercle'
                        : 'Configure le cercle (ex. pour une enfant / un ado)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  if (_alertActive) ...[
                    const SizedBox(height: 8),
                    Text(
                      '⚠️ Alerte active — mise à jour de position en cours',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AttentionModeScreen()),
                      );
                      _refresh();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.radio_button_checked_rounded, size: 22),
                    label: const Text('Ouvrir le Mode Diwall'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Profil de diffusion',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Qui reçoit l’alerte : prioritaires → cercle → Lien Sœurs. '
                    'Délais personnalisés et SOS classique : pack Sécurité+ (MoodCast+).',
                    style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DiffusionProfileScreen()),
                      );
                      _refresh();
                    },
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Configurer la diffusion'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Lien Sœurs — réservé aux femmes',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Entraide entre femmes uniquement (pour l’instant), pour limiter les débordements. '
                    'Attestation obligatoire · réseau opt-in · aperçu proximité.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SisterAidScreen()),
                      );
                    },
                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                    icon: const Icon(Icons.favorite_rounded),
                    label: const Text('Ouvrir Lien Sœurs'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Protéger un enfant ou un proche',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _setupDone
                        ? 'Tu peux enrichir le cercle : parents, famille, ami(e)s — avec priorité d’alerte.'
                        : 'Donne l’app à une petite fille / un ado, configure parents + proches, et elle peut prévenir si elle se sent bizarre.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProtectedSetupScreen()),
                      );
                      _refresh();
                    },
                    icon: const Icon(Icons.child_care_rounded),
                    label: Text(_setupDone ? 'Relancer l’assistant' : 'Configurer le cercle'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SafetyCircleScreen()),
                      );
                      _refresh();
                    },
                    icon: const Icon(Icons.groups_rounded),
                    label: const Text('Voir le cercle de confiance'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Check-in programmé',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu sors / tu rentres tard ? Lance un timer. Si tu ne confirmes pas à temps, l’alerte part toute seule.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (checkInActive) ...[
                    Text(
                      'Actif jusqu’à ${_checkInUntil!.hour.toString().padLeft(2, '0')}:${_checkInUntil!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () async {
                        await AttentionModeService.confirmCheckInSafe();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Check-in confirmé — tu vas bien.'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _refresh();
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Je vais bien'),
                    ),
                  ] else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final m in [15, 30, 60])
                          OutlinedButton(
                            onPressed: () => _startCheckIn(Duration(minutes: m)),
                            child: Text('$m min'),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tout va bien ?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            await StorageService.setMoodSafeCheckinDone(StorageService.todayString());
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Merci, à bientôt !'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.thumb_up_rounded, size: 20),
                          label: const Text('Oui'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MoodSosScreen()),
                            );
                          },
                          icon: const Icon(Icons.chat_rounded, size: 20),
                          label: const Text('Parler'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showDeactivateDialog(context).then((_) => _refresh()),
                    icon: const Icon(Icons.lock_rounded, size: 20),
                    label: const Text('Désactiver l\'alerte (code secret)'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await NotificationService.showIncomingSafetyAlert(
                        fromName: 'Demo Proche',
                        mapsUrl: 'https://maps.google.com/?q=48.8566,2.3522',
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notif prioritaire de démo envoyée (teste avec le DND).'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_active_rounded, size: 20),
                    label: const Text('Tester notif prioritaire'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                      _refresh();
                    },
                    icon: const Icon(Icons.settings_rounded, size: 20),
                    label: const Text('Cercle de confiance & codes'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Système unifié : veille → Diwall/SOS → alerte active (carte + accusés d’envoi) → résolu. '
              'Cascade selon profil de diffusion. Lien Sœurs femmes opt-in. Le 17/112 reste indispensable.',
              style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
