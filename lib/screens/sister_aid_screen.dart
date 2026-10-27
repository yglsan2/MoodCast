import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/sister_aid.dart';
import '../services/sister_aid_service.dart';
import '../theme/app_colors.dart';
import '../widgets/feel_good_card.dart';
import '../widgets/gradient_app_bar.dart';

/// Lien Sœurs — entraide **réservée aux femmes** (sécurité / anti-débordements).
class SisterAidScreen extends StatefulWidget {
  const SisterAidScreen({super.key});

  @override
  State<SisterAidScreen> createState() => _SisterAidScreenState();
}

class _SisterAidScreenState extends State<SisterAidScreen> {
  SisterAidNetwork _network = const SisterAidNetwork();
  List<NearbySister> _nearby = [];
  bool _loading = true;
  bool _refreshingNearby = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final network = await SisterAidService.getNetwork();
    if (!mounted) return;
    setState(() {
      _network = network;
      _loading = false;
    });
    if (network.profile.enabled) {
      await SisterAidService.publishMyPresence();
      await _refreshNearby();
    }
  }

  Future<void> _refreshNearby() async {
    setState(() => _refreshingNearby = true);
    final list = await SisterAidService.discoverNearby();
    if (!mounted) return;
    setState(() {
      _nearby = list;
      _refreshingNearby = false;
    });
  }

  Future<void> _saveProfile(SisterAidProfile profile) async {
    await SisterAidService.updateProfile(profile);
    await _reload();
  }

  Future<void> _addSister() async {
    final nick = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter une sœur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Uniquement une femme de confiance qui a MoodCast et accepte l’entraide. '
              'Le Lien Sœurs est réservé aux femmes. Elle sera contactée (SMS + position) si tu demandes de l’aide.',
              style: TextStyle(fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nick,
              decoration: const InputDecoration(
                labelText: 'Pseudo / prénom',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ajouter')),
        ],
      ),
    );
    if (ok != true) return;
    final p = phone.text.trim();
    if (p.isEmpty) return;
    final added = await SisterAidService.addPeer(
      SisterPeer(
        id: 's_${DateTime.now().millisecondsSinceEpoch}',
        nickname: nick.text.trim().isEmpty ? 'Sœur' : nick.text.trim(),
        phone: p,
        available: true,
      ),
    );
    if (!mounted) return;
    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Active d’abord le Lien Sœurs (attestation femme).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    HapticFeedback.selectionClick();
    await _reload();
  }

  Future<void> _requestHelp() async {
    final result = await SisterAidService.requestHelp(includeDemoNote: true);
    if (!mounted) return;

    if (result.reason == SisterHelpFailReason.notEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Active d’abord le Lien Sœurs (opt-in).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (result.reason == SisterHelpFailReason.noPeers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoute au moins une sœur au réseau pour l’alerter.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(result.success ? 'Demande envoyée' : 'Envoi incomplet'),
        content: Text(
          [
            if (result.sentDirect > 0)
              '${result.sentDirect} sœur(s) contactée(s) avec ta position.'
            else if (result.openedComposer)
              'SMS préparé — envoie le message.'
            else
              'Vérifie les permissions SMS / numéros.',
            if (result.demoNote != null) '\n\n${result.demoNote}',
          ].join(),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _showConsentThenEnable() async {
    var attestWoman = false;
    var acceptRules = false;
    final accept = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Espace réservé aux femmes'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pour sécuriser l’entraide et limiter les risques d’intrusion '
                  'ou de harcèlement, le Lien Sœurs est réservé aux femmes '
                  'dans un premier temps.\n\n'
                  '• Tu peux être contactée si tu te déclares « disponible ».\n'
                  '• Position partagée seulement lors d’une demande d’aide '
                  '(ou approximative si tu publies ta présence).\n'
                  '• N’ajoute que des femmes de confiance.\n\n'
                  'Danger immédiat : 17 / 112.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: attestWoman,
                  onChanged: (v) => setLocal(() => attestWoman = v ?? false),
                  title: const Text(
                    'Je confirme être une femme',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: acceptRules,
                  onChanged: (v) => setLocal(() => acceptRules = v ?? false),
                  title: const Text(
                    'J’accepte les règles d’entraide et de confidentialité',
                    style: TextStyle(fontSize: 13),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(
              onPressed: (attestWoman && acceptRules) ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Rejoindre'),
            ),
          ],
        ),
      ),
    );
    if (accept != true) return;
    if (!mounted) return;
    final nickCtrl = TextEditingController(text: _network.profile.nickname);
    final nick = await showDialog<String>(
      context: this.context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ton pseudo'),
        content: TextField(
          controller: nickCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Pseudo visible par les sœurs',
            hintText: 'ex. Inès',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nickCtrl.text.trim()),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    if (nick == null) return;
    await _saveProfile(
      _network.profile.copyWith(
        enabled: true,
        availableToHelp: true,
        womenOnlyAttestation: true,
        nickname: nick.isEmpty ? 'Sœur' : nick,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _network.profile;

    return Scaffold(
      appBar: const GradientAppBar(
        title: '💜 Lien Sœurs',
        gradient: AppColors.gradientSos,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  FeelGoodCard(
                    margin: EdgeInsets.zero,
                    gradient: AppColors.gradientSos,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Réservé aux femmes',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Espace d’entraide entre femmes uniquement (pour l’instant), '
                          'afin de limiter les risques d’intrusion. Attestation obligatoire à l’entrée.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            height: 1.45,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FeelGoodCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.woman_rounded, color: AppColors.error, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hommes : merci de ne pas rejoindre ce réseau. '
                            'Le cercle famille / Mode Diwall reste disponible pour tout le monde.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FeelGoodCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Participer au Lien Sœurs'),
                          subtitle: Text(
                            p.canUseSisterNetwork
                                ? 'Active · attestation femme enregistrée'
                                : 'Réservé aux femmes · opt-in + attestation',
                          ),
                          value: p.canUseSisterNetwork,
                          onChanged: (v) async {
                            if (v) {
                              await _showConsentThenEnable();
                            } else {
                              await _saveProfile(
                                p.copyWith(
                                  enabled: false,
                                  availableToHelp: false,
                                  // Garde l’attestation si elle quitte temporairement.
                                ),
                              );
                            }
                          },
                          activeThumbColor: AppColors.error,
                        ),
                        if (p.canUseSisterNetwork) ...[
                          SwitchListTile(
                            title: const Text('Je suis dispo pour aider'),
                            subtitle: const Text('Les autres peuvent te solliciter'),
                            value: p.availableToHelp,
                            onChanged: (v) async {
                              await _saveProfile(p.copyWith(availableToHelp: v));
                              if (v) await SisterAidService.publishMyPresence();
                            },
                            activeThumbColor: AppColors.error,
                          ),
                          SwitchListTile(
                            title: const Text('Alerter aussi en Mode Diwall'),
                            value: p.alertSistersOnAttention,
                            onChanged: (v) => _saveProfile(p.copyWith(alertSistersOnAttention: v)),
                            activeThumbColor: AppColors.error,
                          ),
                          SwitchListTile(
                            title: const Text('Aperçu proximité (démo)'),
                            subtitle: const Text('Profils simulés autour de toi — pas de SMS'),
                            value: p.demoNearbyEnabled,
                            onChanged: (v) async {
                              await _saveProfile(p.copyWith(demoNearbyEnabled: v));
                            },
                            activeThumbColor: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (p.enabled) ...[
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _requestHelp,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.front_hand_rounded),
                      label: const Text('Demander de l’aide aux sœurs'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'À proximité',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const Spacer(),
                        if (_refreshingNearby)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            onPressed: _refreshNearby,
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Actualiser',
                          ),
                      ],
                    ),
                    Text(
                      'Rayon ~${p.radiusKm.toStringAsFixed(0)} km · '
                      'badge « démo » = aperçu jusqu’au serveur de présence',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    if (_nearby.isEmpty)
                      FeelGoodCard(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Personne à proximité pour l’instant. Ajoute des sœurs ou active l’aperçu démo.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ..._nearby.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FeelGoodCard(
                            margin: EdgeInsets.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.error.withValues(alpha: 0.15),
                                child: Icon(
                                  s.isDemo ? Icons.radar_rounded : Icons.favorite_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                s.displayName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                s.isDemo
                                    ? 'Aperçu proximité · ${s.distanceLabel}'
                                    : 'Réseau · ${s.distanceLabel}',
                              ),
                              trailing: s.isDemo
                                  ? Chip(
                                      label: const Text('démo'),
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: AppColors.surface,
                                    )
                                  : IconButton(
                                      tooltip: 'Demander de l’aide (réseau)',
                                      onPressed: _requestHelp,
                                      icon: const Icon(Icons.sms_rounded),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Mon réseau sœurs',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addSister,
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    if (_network.peers.isEmpty)
                      Text(
                        'Ajoute uniquement des femmes de confiance qui ont l’app : elles formeront ton filet d’entraide réel (SMS).',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      )
                    else
                      ..._network.peers.map(
                        (peer) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FeelGoodCard(
                            margin: EdgeInsets.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              title: Text(peer.nickname, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(peer.phone),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: peer.available,
                                    onChanged: (v) => SisterAidService.setPeerAvailable(peer.id, v)
                                        .then((_) => _reload()),
                                  ),
                                  IconButton(
                                    onPressed: () => SisterAidService.removePeer(peer.id).then((_) => _reload()),
                                    icon: const Icon(Icons.delete_outline_rounded),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}
