import 'package:flutter/material.dart';

import '../models/mood_safe_session.dart';
import '../services/premium_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/feel_good_card.dart';
import '../widgets/gradient_app_bar.dart';
import 'mood_cast_plus_screen.dart';

/// Réglages : qui est alerté et quel déclencheur Diwall / SOS.
class DiffusionProfileScreen extends StatefulWidget {
  const DiffusionProfileScreen({super.key});

  @override
  State<DiffusionProfileScreen> createState() => _DiffusionProfileScreenState();
}

class _DiffusionProfileScreenState extends State<DiffusionProfileScreen> {
  DiffusionProfile _profile = const DiffusionProfile();
  bool _loading = true;
  bool _securityPremium = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await StorageService.getDiffusionProfile();
    final premium = await PremiumService.hasSecurityPremium();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _securityPremium = premium;
      _loading = false;
    });
  }

  Future<void> _save(DiffusionProfile p) async {
    await StorageService.setDiffusionProfile(p);
    final saved = await StorageService.getDiffusionProfile();
    if (!mounted) return;
    setState(() => _profile = saved);
  }

  Future<void> _openPlus() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MoodCastPlusScreen()),
    );
    await _load();
  }

  Future<void> _requirePremium(VoidCallback action) async {
    if (_securityPremium) {
      action();
      return;
    }
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sécurité+ (MoodCast+)'),
        content: const Text(
          'La personnalisation des délais et le SOS classique font partie du pack Sécurité+.\n\n'
          'En free : Diwall fixe à 3 secondes (relâcher = alerte).\n'
          'Avec MoodCast+ : durée 2–10 s, SOS avec annulation, délais sur mesure.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Plus tard')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Voir MoodCast+')),
        ],
      ),
    );
    if (go == true && mounted) await _openPlus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Profil de diffusion',
        gradient: AppColors.gradientSos,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Une seule alerte MoodSafe, plusieurs couches. Tu configures ici qui est prévenu, une fois pour toutes.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 13),
                ),
                const SizedBox(height: 16),
                FeelGoodCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Prioritaires ★ en premier'),
                        subtitle: const Text('Parents / urgence d’abord'),
                        value: _profile.notifyPriorityFirst,
                        onChanged: (v) => _save(_profile.copyWith(notifyPriorityFirst: v)),
                        activeThumbColor: AppColors.error,
                      ),
                      SwitchListTile(
                        title: const Text('Tout le cercle ensuite'),
                        subtitle: const Text('Famille / amis non prioritaires'),
                        value: _profile.notifyFullCircle,
                        onChanged: (v) => _save(_profile.copyWith(notifyFullCircle: v)),
                        activeThumbColor: AppColors.error,
                      ),
                      SwitchListTile(
                        title: const Text('Lien Sœurs (si activé)'),
                        subtitle: const Text('Uniquement femmes · opt-in séparé'),
                        value: _profile.notifySisterAid,
                        onChanged: (v) => _save(_profile.copyWith(notifySisterAid: v)),
                        activeThumbColor: AppColors.error,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Déclencheur & délais',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    if (!_securityPremium)
                      TextButton.icon(
                        onPressed: _openPlus,
                        icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                        label: const Text('Sécurité+'),
                      ),
                  ],
                ),
                if (!_securityPremium) ...[
                  const SizedBox(height: 8),
                  FeelGoodCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_rounded, color: AppColors.warning, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Free : Diwall fixe à ${PremiumService.freeAttentionHoldSeconds} s. '
                            'MoodCast+ Sécurité+ : durée personnalisable + SOS classique.',
                            style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                FeelGoodCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          _profile.defaultTrigger == AttentionTriggerStyle.deadManSwitch
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: AppColors.error,
                        ),
                        title: const Text('Diwall (recommandé)'),
                        subtitle: Text(
                          _securityPremium
                              ? 'Maintien ${_profile.attentionHoldSeconds} s = OK · Relâcher = alerte'
                              : 'Maintien ${PremiumService.freeAttentionHoldSeconds} s = OK · Relâcher = alerte',
                        ),
                        onTap: () => _save(
                          _profile.copyWith(defaultTrigger: AttentionTriggerStyle.deadManSwitch),
                        ),
                      ),
                      if (_profile.defaultTrigger == AttentionTriggerStyle.deadManSwitch)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Row(
                            children: [
                              Text(
                                '${_securityPremium ? _profile.attentionHoldSeconds : PremiumService.freeAttentionHoldSeconds} s',
                              ),
                              Expanded(
                                child: Slider(
                                  value: (_securityPremium
                                          ? _profile.attentionHoldSeconds
                                          : PremiumService.freeAttentionHoldSeconds)
                                      .toDouble()
                                      .clamp(2, 10),
                                  min: 2,
                                  max: 10,
                                  divisions: 8,
                                  label:
                                      '${_securityPremium ? _profile.attentionHoldSeconds : PremiumService.freeAttentionHoldSeconds} s',
                                  onChanged: _securityPremium
                                      ? (v) => _save(
                                            _profile.copyWith(attentionHoldSeconds: v.round()),
                                          )
                                      : null,
                                  onChangeEnd: _securityPremium
                                      ? null
                                      : (_) => _requirePremium(() {}),
                                  activeColor: AppColors.error,
                                ),
                              ),
                              if (!_securityPremium)
                                IconButton(
                                  tooltip: 'Personnaliser avec Sécurité+',
                                  onPressed: () => _requirePremium(() {}),
                                  icon: const Icon(Icons.lock_rounded, size: 20),
                                ),
                            ],
                          ),
                        ),
                      ListTile(
                        leading: Icon(
                          _profile.defaultTrigger == AttentionTriggerStyle.classicCancelWindow
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: _securityPremium ? AppColors.error : AppColors.textSecondary,
                        ),
                        title: Row(
                          children: [
                            const Text('SOS classique'),
                            if (!_securityPremium) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.lock_rounded, size: 16, color: AppColors.warning),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          _securityPremium
                              ? 'Compte à rebours ${_profile.classicCancelSeconds} s, annulation possible'
                              : 'Inclus dans MoodCast+ Sécurité+',
                        ),
                        onTap: () => _requirePremium(() {
                          _save(
                            _profile.copyWith(
                              defaultTrigger: AttentionTriggerStyle.classicCancelWindow,
                            ),
                          );
                        }),
                      ),
                      if (_securityPremium &&
                          _profile.defaultTrigger == AttentionTriggerStyle.classicCancelWindow)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              Text('${_profile.classicCancelSeconds} s'),
                              Expanded(
                                child: Slider(
                                  value: _profile.classicCancelSeconds.toDouble().clamp(5, 15),
                                  min: 5,
                                  max: 15,
                                  divisions: 10,
                                  label: '${_profile.classicCancelSeconds} s',
                                  onChanged: (v) => _save(
                                    _profile.copyWith(classicCancelSeconds: v.round()),
                                  ),
                                  activeColor: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Les destinataires ne voient jamais une carte publique : seulement SMS / notifs autorisées. '
                  'Le 17 / 112 reste indispensable en danger vital.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary),
                ),
              ],
            ),
    );
  }
}
