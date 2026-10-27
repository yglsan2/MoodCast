import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../models/sister_aid.dart';
import 'mood_safe_log.dart';
import 'mood_safe_service.dart';
import 'notification_service.dart';
import 'sms_sender_service.dart';
import 'storage_service.dart';

/// Lien Sœurs : entraide entre utilisatrices (esprit Sorority, implémentation MoodCast).
class SisterAidService {
  SisterAidService._();

  static Future<SisterAidNetwork> getNetwork() async {
    try {
      return await StorageService.getSisterAidNetwork();
    } catch (e, st) {
      MoodSafeLog.error('SisterAid getNetwork', e, st);
      return const SisterAidNetwork();
    }
  }

  static Future<void> saveNetwork(SisterAidNetwork network) async {
    try {
      await StorageService.setSisterAidNetwork(network);
    } catch (e, st) {
      MoodSafeLog.error('SisterAid saveNetwork', e, st);
    }
  }

  static Future<SisterAidProfile> getProfile() async {
    try {
      return (await getNetwork()).profile;
    } catch (e, st) {
      MoodSafeLog.error('SisterAid getProfile', e, st);
      return const SisterAidProfile();
    }
  }

  static Future<void> updateProfile(SisterAidProfile profile) async {
    try {
      final n = await getNetwork();
      var next = profile;
      if (next.enabled && !next.womenOnlyAttestation) {
        next = next.copyWith(enabled: false, availableToHelp: false);
      }
      if (!next.womenOnlyAttestation) {
        next = next.copyWith(enabled: false, availableToHelp: false);
      }
      await saveNetwork(n.copyWith(profile: next));
      MoodSafeLog.info('SisterAid updateProfile', 'enabled=${next.enabled}');
    } catch (e, st) {
      MoodSafeLog.error('SisterAid updateProfile', e, st);
    }
  }

  static Future<bool> addPeer(SisterPeer peer) async {
    try {
      final n = await getNetwork();
      if (!n.profile.canUseSisterNetwork) return false;
      final peers = [...n.peers.where((p) => p.cleanPhone != peer.cleanPhone), peer];
      await saveNetwork(n.copyWith(peers: peers));
      return true;
    } catch (e, st) {
      MoodSafeLog.error('SisterAid addPeer', e, st);
      return false;
    }
  }

  static Future<void> removePeer(String id) async {
    try {
      final n = await getNetwork();
      await saveNetwork(n.copyWith(peers: n.peers.where((p) => p.id != id).toList()));
    } catch (e, st) {
      MoodSafeLog.error('SisterAid removePeer', e, st);
    }
  }

  static Future<void> setPeerAvailable(String id, bool available) async {
    try {
      final n = await getNetwork();
      await saveNetwork(
        n.copyWith(
          peers: n.peers
              .map((p) => p.id == id ? p.copyWith(available: available) : p)
              .toList(),
        ),
      );
    } catch (e, st) {
      MoodSafeLog.error('SisterAid setPeerAvailable', e, st);
    }
  }

  static Future<void> publishMyPresence() async {
    try {
      final n = await getNetwork();
      if (!n.profile.canUseSisterNetwork || !n.profile.availableToHelp) return;
      final pos = await _position();
      if (pos == null) return;
      final approxLat = (pos.latitude * 200).round() / 200.0;
      final approxLng = (pos.longitude * 200).round() / 200.0;
      await StorageService.setSisterAidMyPresence(
        lat: approxLat,
        lng: approxLng,
        at: DateTime.now(),
      );
    } catch (e, st) {
      MoodSafeLog.error('SisterAid publishMyPresence', e, st);
    } finally {
      MoodSafeLog.info('SisterAid publishMyPresence finally');
    }
  }

  static Future<List<NearbySister>> discoverNearby() async {
    try {
      final n = await getNetwork();
      if (!n.profile.canUseSisterNetwork) return [];

      Position? me;
      try {
        me = await _position();
      } catch (e) {
        MoodSafeLog.warn('discoverNearby position', e);
      }

      final out = <NearbySister>[];

      try {
        for (final p in n.peers) {
          if (!p.available) continue;
          double meters = -1;
          if (me != null && p.lastLat != null && p.lastLng != null) {
            try {
              meters = Geolocator.distanceBetween(
                me.latitude,
                me.longitude,
                p.lastLat!,
                p.lastLng!,
              );
              if (meters > n.profile.radiusKm * 1000) continue;
            } catch (e) {
              MoodSafeLog.warn('discoverNearby distance', e);
            }
          }
          out.add(
            NearbySister(
              id: p.id,
              displayName: p.nickname.isEmpty ? 'Sœur' : p.nickname,
              distanceMeters: meters < 0 ? 800 : meters,
              isDemo: false,
              phone: p.phone,
              available: p.available,
            ),
          );
        }
      } catch (e, st) {
        MoodSafeLog.error('discoverNearby peers', e, st);
      }

      try {
        if (n.profile.demoNearbyEnabled && me != null) {
          out.addAll(_discoverDemoNearby(me, n.profile.radiusKm));
        }
      } catch (e) {
        MoodSafeLog.warn('discoverNearby demo', e);
      }

      try {
        out.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      } catch (_) {}

      return out;
    } catch (e, st) {
      MoodSafeLog.error('discoverNearby', e, st);
      return const [];
    } finally {
      MoodSafeLog.info('discoverNearby finally');
    }
  }

  static Future<SisterHelpResult> requestHelp({
    String? messageOverride,
    bool includeDemoNote = false,
  }) async {
    SisterAidNetwork? n;
    var notified = 0;
    var sentDirect = 0;
    var openedComposer = false;
    var message = '';

    try {
      // 1) Réseau
      try {
        n = await getNetwork();
      } catch (e, st) {
        MoodSafeLog.error('requestHelp getNetwork', e, st);
        return const SisterHelpResult(
          success: false,
          notified: 0,
          reason: SisterHelpFailReason.notEnabled,
        );
      }
      if (!n.profile.canUseSisterNetwork) {
        return const SisterHelpResult(
          success: false,
          notified: 0,
          reason: SisterHelpFailReason.notEnabled,
        );
      }

      // 2) Peers
      final peers = n.peers.where((p) => p.available && p.cleanPhone.isNotEmpty).toList();
      if (peers.isEmpty) {
        return const SisterHelpResult(
          success: false,
          notified: 0,
          reason: SisterHelpFailReason.noPeers,
        );
      }
      notified = peers.length;

      // 3) Message
      try {
        final nick =
            n.profile.nickname.trim().isEmpty ? 'Une sœur MoodCast' : n.profile.nickname.trim();
        message = messageOverride ??
            await MoodSafeService.buildMessage(
              prefix:
                  '💜 LIEN SŒURS MoodCast – $nick a besoin d’entraide à proximité. '
                  'Si tu peux, contacte-la / rapproche-toi en sécurité. Position : ',
            );
      } catch (e, st) {
        MoodSafeLog.error('requestHelp message', e, st);
        message = '💜 LIEN SŒURS MoodCast – besoin d’entraide à proximité.';
      }

      // 4) SMS
      try {
        final sms = await SmsSenderService.sendToMany(
          peers.map((p) => p.cleanPhone).toList(),
          message,
        );
        sentDirect = sms.sentDirect;
        openedComposer = sms.openedComposer;
      } catch (e, st) {
        MoodSafeLog.error('requestHelp SMS', e, st);
      }

      try {
        await NotificationService.showEmergencyAlert(
          title: 'Demande Lien Sœurs envoyée',
          body: sentDirect > 0
              ? 'Prévenu(e)s : $sentDirect sœur(s) du réseau.'
              : 'Message d’entraide préparé pour ton réseau.',
        );
      } catch (e) {
        MoodSafeLog.warn('requestHelp notif', e);
      }

      try {
        await StorageService.addSisterHelpLog(
          SisterHelpLog(
            at: DateTime.now(),
            peerCount: peers.length,
            sentDirect: sentDirect,
            preview: message.length > 100 ? '${message.substring(0, 100)}…' : message,
          ),
        );
      } catch (e) {
        MoodSafeLog.warn('requestHelp log', e);
      }

      final success = sentDirect > 0 || openedComposer;
      return SisterHelpResult(
        success: success,
        notified: notified,
        sentDirect: sentDirect,
        openedComposer: openedComposer,
        message: message,
        reason: success ? null : SisterHelpFailReason.sendFailed,
        demoNote: includeDemoNote && n.profile.demoNearbyEnabled
            ? 'Les profils « aperçu proximité » ne reçoivent pas de SMS (pas encore de serveur). '
                'Seules tes sœurs ajoutées sont contactées.'
            : null,
      );
    } catch (e, st) {
      MoodSafeLog.error('requestHelp fatal', e, st);
      return SisterHelpResult(
        success: false,
        notified: notified,
        sentDirect: sentDirect,
        openedComposer: openedComposer,
        message: message,
        reason: SisterHelpFailReason.sendFailed,
      );
    } finally {
      MoodSafeLog.info('requestHelp finally notified=$notified sent=$sentDirect');
    }
  }

  static Future<SisterHelpResult?> notifyOnAttentionIfEnabled() async {
    try {
      final n = await getNetwork();
      if (!n.profile.canUseSisterNetwork || !n.profile.alertSistersOnAttention) {
        return null;
      }
      if (n.peers.isEmpty) return null;
      return requestHelp(
        messageOverride: await MoodSafeService.buildMessage(
          prefix:
              '🚨 LIEN SŒURS – Alerte Diwall MoodCast. Une sœur a besoin d’aide. Position : ',
        ),
      );
    } catch (e, st) {
      MoodSafeLog.error('notifyOnAttentionIfEnabled', e, st);
      return null;
    }
  }

  static List<NearbySister> _discoverDemoNearby(Position me, double radiusKm) {
    try {
      final rnd = math.Random(
        (me.latitude * 1000).round() ^ (me.longitude * 1000).round() ^ DateTime.now().day,
      );
      const names = ['Inès', 'Sara', 'Camille', 'Nora', 'Léa', 'Amina', 'Chloé', 'Maya'];
      final count = 2 + rnd.nextInt(3);
      final list = <NearbySister>[];
      for (var i = 0; i < count; i++) {
        final meters = 120.0 + rnd.nextDouble() * math.max(1.0, radiusKm * 1000 - 120);
        if (meters > radiusKm * 1000) continue;
        list.add(
          NearbySister(
            id: 'demo_$i',
            displayName: names[rnd.nextInt(names.length)],
            distanceMeters: meters,
            isDemo: true,
            available: true,
          ),
        );
      }
      return list;
    } catch (e, st) {
      MoodSafeLog.error('_discoverDemoNearby', e, st);
      return const [];
    }
  }

  static Future<Position?> _position() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        try {
          permission = await Geolocator.requestPermission();
        } catch (e) {
          MoodSafeLog.warn('_position requestPermission', e);
          return null;
        }
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 5)),
      );
    } catch (e, st) {
      MoodSafeLog.error('SisterAid _position', e, st);
      return null;
    } finally {
      // no-op
    }
  }
}

enum SisterHelpFailReason { notEnabled, noPeers, sendFailed }

class SisterHelpResult {
  const SisterHelpResult({
    required this.success,
    required this.notified,
    this.sentDirect = 0,
    this.openedComposer = false,
    this.message = '',
    this.reason,
    this.demoNote,
  });

  final bool success;
  final int notified;
  final int sentDirect;
  final bool openedComposer;
  final String message;
  final SisterHelpFailReason? reason;
  final String? demoNote;
}
