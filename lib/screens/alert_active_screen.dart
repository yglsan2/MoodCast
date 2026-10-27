import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/attention_mode_service.dart';
import '../theme/app_colors.dart';
import '../widgets/feel_good_card.dart';

/// Écran urgence unifié : carte, accusés d’envoi, résolution par code.
class AlertActiveScreen extends StatefulWidget {
  const AlertActiveScreen({super.key, this.session});

  final MoodSafeAlertSession? session;

  @override
  State<AlertActiveScreen> createState() => _AlertActiveScreenState();
}

class _AlertActiveScreenState extends State<AlertActiveScreen> {
  MoodSafeAlertSession? _session;
  StreamSubscription<MoodSafeAlertSession?>? _sub;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? AttentionModeService.currentSession;
    _sub = AttentionModeService.sessionStream.listen((s) {
      if (mounted) setState(() => _session = s);
    });
    if (_session == null) {
      AttentionModeService.restoreSession().then((_) {
        if (mounted) setState(() => _session = AttentionModeService.currentSession);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _resolve() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Résoudre l’alerte'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Code de désactivation',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (code == null || !mounted) return;
    final ok = await AttentionModeService.deactivateWithCode(code);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Alerte traitée.' : 'Code incorrect.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
    if (ok) Navigator.pop(context);
  }

  Future<void> _openMaps() async {
    final s = _session;
    if (s?.lastLat == null || s?.lastLng == null) return;
    final uri = Uri.parse('https://www.google.com/maps?q=${s!.lastLat},${s.lastLng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    final hasPos = s?.lastLat != null && s?.lastLng != null;
    final timeLabel = s == null
        ? '—'
        : DateFormat.Hm('fr_FR').format(s.startedAt);

    return Scaffold(
      backgroundColor: const Color(0xFF1F1518),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Alerte active'),
        actions: [
          TextButton(
            onPressed: _resolve,
            child: const Text('Code', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: s == null || !s.active
          ? Center(
              child: Text(
                'Aucune alerte en cours.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FeelGoodCard(
                    margin: EdgeInsets.zero,
                    gradient: AppColors.gradientSos,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Déclenchée à $timeLabel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Accusés locaux : ${s.sentCount} SMS envoyé(s) · '
                          '${s.notifiedOrPreparedCount} destinataire(s) préparés',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ce ne sont pas des accusés de lecture des proches '
                          '(nécessite un serveur). Suivi GPS toutes les 2 min.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 5,
                  child: hasPos
                      ? FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(s.lastLat!, s.lastLng!),
                            initialZoom: 15,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.moodcast.worldflow',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(s.lastLat!, s.lastLng!),
                                  width: 48,
                                  height: 48,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: AppColors.error,
                                    size: 48,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            'Position en cours de récupération…',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                          ),
                        ),
                ),
                if (hasPos)
                  TextButton.icon(
                    onPressed: _openMaps,
                    icon: const Icon(Icons.map_rounded, color: Colors.white70),
                    label: const Text('Ouvrir dans Maps', style: TextStyle(color: Colors.white70)),
                  ),
                Expanded(
                  flex: 4,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: s.deliveries.length,
                    itemBuilder: (context, i) {
                      final d = s.deliveries[i];
                      final ok = d.status == DeliveryStatus.sentDirect ||
                          d.status == DeliveryStatus.composerOpened;
                      return Card(
                        color: const Color(0xFF2A2226),
                        child: ListTile(
                          leading: Icon(
                            ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                            color: ok ? AppColors.success : AppColors.warning,
                          ),
                          title: Text(
                            d.label,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${d.layer.labelFr} · ${d.statusLabelFr}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                          ),
                          trailing: d.phone.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.phone_rounded, color: Colors.white70),
                                  onPressed: () async {
                                    final uri = Uri(scheme: 'tel', path: d.phone);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: FilledButton.icon(
                      onPressed: _resolve,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.error,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.lock_rounded),
                      label: const Text('Résoudre avec le code'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
