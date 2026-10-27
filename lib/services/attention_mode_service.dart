import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/mood_safe_session.dart';
import '../models/safety_circle.dart';
import 'mood_safe_log.dart';
import 'mood_safe_service.dart';
import 'notification_service.dart';
import 'sister_aid_service.dart';
import 'sms_sender_service.dart';
import 'storage_service.dart';

export '../models/safety_circle.dart' show AttentionAlertLog;
export '../models/mood_safe_session.dart';

enum AttentionPhase { idle, holding, cancelledSafe, alerting, alertActive, classicCountdown }

/// Mode Diwall unifié MoodSafe (dead-man's switch / SOS).
class AttentionModeService {
  AttentionModeService._();

  static const Duration defaultHoldDuration = Duration(seconds: 3);
  static const Duration liveLocationInterval = Duration(minutes: 2);

  static Future<Duration> configuredHoldDuration() async {
    try {
      final p = await StorageService.getDiffusionProfile();
      return p.attentionHoldDuration;
    } catch (e, st) {
      MoodSafeLog.error('configuredHoldDuration', e, st);
      return defaultHoldDuration;
    }
  }

  static AttentionPhase phase = AttentionPhase.idle;
  static DateTime? alertStartedAt;
  static String? lastAlertMessage;
  static MoodSafeAlertSession? currentSession;
  static Timer? _liveTimer;
  static Timer? _classicTimer;

  static final StreamController<AttentionPhase> _phaseController =
      StreamController<AttentionPhase>.broadcast();
  static final StreamController<MoodSafeAlertSession?> _sessionController =
      StreamController<MoodSafeAlertSession?>.broadcast();

  static Stream<AttentionPhase> get phaseStream => _phaseController.stream;
  static Stream<MoodSafeAlertSession?> get sessionStream => _sessionController.stream;

  static void _setPhase(AttentionPhase p) {
    try {
      phase = p;
      if (!_phaseController.isClosed) _phaseController.add(p);
    } catch (e, st) {
      MoodSafeLog.error('_setPhase', e, st);
      phase = p;
    }
  }

  static Future<void> _setSession(MoodSafeAlertSession? s) async {
    try {
      currentSession = s;
      await StorageService.setAlertSession(s);
      if (!_sessionController.isClosed) _sessionController.add(s);
    } catch (e, st) {
      MoodSafeLog.error('_setSession', e, st);
      currentSession = s;
    }
  }

  static Future<void> restoreSession() async {
    try {
      final s = await StorageService.getAlertSession();
      if (s == null || !s.active) {
        MoodSafeLog.info('restoreSession: aucune session active');
        return;
      }
      currentSession = s;
      alertStartedAt = s.startedAt;
      lastAlertMessage = s.message;
      try {
        await StorageService.setAttentionAlertActive(true);
      } catch (e) {
        MoodSafeLog.warn('restoreSession setAttentionAlertActive', e);
      }
      _setPhase(AttentionPhase.alertActive);
      try {
        _startLiveLocationUpdates();
      } catch (e) {
        MoodSafeLog.warn('restoreSession live updates', e);
      }
      try {
        if (!_sessionController.isClosed) _sessionController.add(s);
      } catch (_) {}
      MoodSafeLog.info('restoreSession OK', s.id);
    } catch (e, st) {
      MoodSafeLog.error('restoreSession', e, st);
    } finally {
      MoodSafeLog.info('restoreSession finally phase=$phase');
    }
  }

  static Future<MoodSafeSystemState> systemState() async {
    try {
      if (await StorageService.isAttentionAlertActive()) {
        return MoodSafeSystemState.alerteActive;
      }
      if (phase == AttentionPhase.holding || phase == AttentionPhase.classicCountdown) {
        return MoodSafeSystemState.attentionArmee;
      }
      if (phase == AttentionPhase.cancelledSafe) {
        return MoodSafeSystemState.resolu;
      }
      return MoodSafeSystemState.veille;
    } catch (e, st) {
      MoodSafeLog.error('systemState', e, st);
      return MoodSafeSystemState.veille;
    }
  }

  static Future<List<SafetyContact>> recipients() async {
    try {
      final circle = await StorageService.getSafetyCircle();
      final fromCircle = circle.resolveAlertRecipients();
      if (fromCircle.isNotEmpty) return fromCircle;

      final phones = await StorageService.getMoodSafePhones();
      return phones
          .asMap()
          .entries
          .map(
            (e) => SafetyContact(
              id: 'legacy_${e.key}',
              name: e.key == 0 ? 'Contact principal' : 'Contact ${e.key + 1}',
              phone: e.value,
              priority: e.key == 0,
            ),
          )
          .toList();
    } catch (e, st) {
      MoodSafeLog.error('recipients', e, st);
      return const [];
    }
  }

  static Future<({List<SafetyContact> priority, List<SafetyContact> circle})> resolveDiffusionWaves() async {
    try {
      final profile = await StorageService.getDiffusionProfile();
      final all = await recipients();
      final priority = all.where((c) => c.priority).toList();
      final rest = all.where((c) => !c.priority).toList();

      final first = profile.notifyPriorityFirst
          ? (priority.isNotEmpty ? priority : (profile.notifyFullCircle ? all : <SafetyContact>[]))
          : <SafetyContact>[];

      List<SafetyContact> second;
      if (!profile.notifyFullCircle) {
        second = [];
      } else if (profile.notifyPriorityFirst && priority.isNotEmpty) {
        second = rest;
      } else if (!profile.notifyPriorityFirst) {
        second = all;
      } else {
        second = [];
      }

      final firstPhones = first.map((c) => c.cleanPhone).toSet();
      second = second.where((c) => !firstPhones.contains(c.cleanPhone)).toList();
      return (priority: first, circle: second);
    } catch (e, st) {
      MoodSafeLog.error('resolveDiffusionWaves', e, st);
      return (priority: <SafetyContact>[], circle: <SafetyContact>[]);
    }
  }

  static Future<AttentionAlertResult> triggerAlert({
    bool silentUi = false,
    AttentionTriggerStyle triggerStyle = AttentionTriggerStyle.deadManSwitch,
  }) async {
    _classicTimer?.cancel();
    _liveTimer?.cancel();
    _setPhase(AttentionPhase.alerting);

    var sentDirect = 0;
    var openedComposer = false;
    var sistersNotified = 0;
    var contacts = <SafetyContact>[];
    var priorityCount = 0;
    var message = '🚨 ALERTE MoodCast : Je me sens en danger.';
    MoodSafeAlertSession? session;
    AttentionFailReason? failReason;

    try {
      // 1) Destinataires
      late final ({List<SafetyContact> priority, List<SafetyContact> circle}) waves;
      try {
        waves = await resolveDiffusionWaves();
        contacts = [...waves.priority, ...waves.circle];
        priorityCount = waves.priority.length;
      } catch (e, st) {
        MoodSafeLog.error('triggerAlert resolve waves', e, st);
        failReason = AttentionFailReason.noContacts;
        return const AttentionAlertResult(
          success: false,
          recipientCount: 0,
          message: '',
          reason: AttentionFailReason.noContacts,
        );
      }

      if (contacts.isEmpty) {
        failReason = AttentionFailReason.noContacts;
        return const AttentionAlertResult(
          success: false,
          recipientCount: 0,
          message: '',
          reason: AttentionFailReason.noContacts,
        );
      }

      // 2) Message + géoloc (fallback texte si GPS KO)
      try {
        final circle = await StorageService.getSafetyCircle();
        final who = circle.profile.displayName.trim();
        message = await MoodSafeService.buildMessage(
          prefix: who.isEmpty
              ? '🚨 ALERTE MoodCast : Je me sens en danger / mal à l’aise. Position : '
              : '🚨 ALERTE MoodCast : $who a besoin d’aide (se sent mal / endroit bizarre). Position : ',
        );
      } catch (e, st) {
        MoodSafeLog.error('triggerAlert buildMessage', e, st);
        message =
            '🚨 ALERTE MoodCast : Je me sens en danger. (position indisponible)';
      }
      lastAlertMessage = message;
      alertStartedAt = DateTime.now();

      final deliveries = <AlertDeliveryAck>[];
      final diffusion = await StorageService.getDiffusionProfile();

      Future<void> sendWave(List<SafetyContact> wave, AlertLayer layer, String prefix) async {
        if (wave.isEmpty) return;
        final start = deliveries.length;
        for (final c in wave) {
          deliveries.add(
            AlertDeliveryAck(
              id: c.id,
              label: c.name,
              phone: c.cleanPhone,
              layer: layer,
              status: DeliveryStatus.pending,
            ),
          );
        }
        try {
          final sms = await SmsSenderService.sendToMany(
            wave.map((c) => c.cleanPhone).toList(),
            '$prefix$message',
          );
          sentDirect += sms.sentDirect;
          openedComposer = openedComposer || sms.openedComposer;
          final status = sms.sentDirect > 0
              ? DeliveryStatus.sentDirect
              : sms.openedComposer
                  ? DeliveryStatus.composerOpened
                  : DeliveryStatus.failed;
          for (var i = start; i < deliveries.length; i++) {
            deliveries[i] = deliveries[i].copyWith(status: status);
          }
        } catch (e, st) {
          MoodSafeLog.error('triggerAlert sendWave $layer', e, st);
          for (var i = start; i < deliveries.length; i++) {
            deliveries[i] = deliveries[i].copyWith(status: DeliveryStatus.failed);
          }
        }
      }

      // 3) Cascade SMS
      try {
        await sendWave(waves.priority, AlertLayer.priority, '');
        await sendWave(waves.circle, AlertLayer.circle, '📣 MoodCast (cercle) – ');
      } catch (e, st) {
        MoodSafeLog.error('triggerAlert cascade SMS', e, st);
      }

      // 4) Lien Sœurs (optionnel, ne doit jamais faire échouer l’alerte privée)
      if (diffusion.notifySisterAid) {
        try {
          final sisterNet = await SisterAidService.getNetwork();
          if (sisterNet.profile.canUseSisterNetwork &&
              sisterNet.profile.alertSistersOnAttention) {
            final sisterResult = await SisterAidService.requestHelp(
              messageOverride: await MoodSafeService.buildMessage(
                prefix:
                    '🚨 LIEN SŒURS – Alerte Diwall MoodCast. Une sœur a besoin d’aide. Position : ',
              ),
            );
            sistersNotified = sisterResult.notified;
            for (final p in sisterNet.peers.where((e) => e.available)) {
              deliveries.add(
                AlertDeliveryAck(
                  id: 'sister_${p.id}',
                  label: p.nickname,
                  phone: p.cleanPhone,
                  layer: AlertLayer.sisterAid,
                  status: sisterResult.sentDirect > 0
                      ? DeliveryStatus.sentDirect
                      : sisterResult.openedComposer
                          ? DeliveryStatus.composerOpened
                          : DeliveryStatus.failed,
                ),
              );
            }
          }
        } catch (e, st) {
          MoodSafeLog.error('triggerAlert Lien Sœurs', e, st);
        }
      }

      final pos = await peekLocation();
      session = MoodSafeAlertSession(
        id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
        startedAt: alertStartedAt ?? DateTime.now(),
        message: message,
        deliveries: deliveries,
        lastLat: pos?.latitude,
        lastLng: pos?.longitude,
        active: true,
        triggerStyle: triggerStyle,
      );

      try {
        await _setSession(session);
      } catch (e) {
        MoodSafeLog.warn('triggerAlert persist session', e);
      }

      try {
        await StorageService.addAttentionAlertLog(
          AttentionAlertLog(
            at: DateTime.now(),
            recipientCount: contacts.length + sistersNotified,
            messagePreview:
                message.length > 120 ? '${message.substring(0, 120)}…' : message,
            sentDirect: sentDirect,
          ),
        );
      } catch (e) {
        MoodSafeLog.warn('triggerAlert alert log', e);
      }

      try {
        await StorageService.setAttentionAlertActive(true);
      } catch (e) {
        MoodSafeLog.warn('triggerAlert set active', e);
      }

      if (!silentUi) {
        try {
          await NotificationService.showEmergencyAlert(
            title: 'Alerte MoodSafe active',
            body:
                'SMS : $sentDirect · Destinataires : ${session.notifiedOrPreparedCount}. Suivi position ON.',
          );
        } catch (e) {
          MoodSafeLog.warn('triggerAlert notification', e);
        }
      }

      final success = sentDirect > 0 || openedComposer || sistersNotified > 0;
      if (!success) failReason = AttentionFailReason.sendFailed;

      MoodSafeLog.info(
        'triggerAlert OK',
        'success=$success sent=$sentDirect composer=$openedComposer sisters=$sistersNotified',
      );

      return AttentionAlertResult(
        success: success,
        recipientCount: contacts.length,
        priorityCount: priorityCount,
        message: message,
        sentDirect: sentDirect,
        openedComposer: openedComposer,
        session: session,
        reason: failReason,
      );
    } catch (e, st) {
      MoodSafeLog.error('triggerAlert fatal', e, st);
      // Fallback minimal : session locale même si SMS a planté
      try {
        session ??= MoodSafeAlertSession(
          id: 'alert_fallback_${DateTime.now().millisecondsSinceEpoch}',
          startedAt: DateTime.now(),
          message: message,
          deliveries: const [],
          active: true,
          triggerStyle: triggerStyle,
        );
        await StorageService.setAttentionAlertActive(true);
        await _setSession(session);
      } catch (e2) {
        MoodSafeLog.warn('triggerAlert fallback session', e2);
      }
      return AttentionAlertResult(
        success: false,
        recipientCount: contacts.length,
        priorityCount: priorityCount,
        message: message,
        sentDirect: sentDirect,
        openedComposer: openedComposer,
        session: session,
        reason: AttentionFailReason.sendFailed,
      );
    } finally {
      try {
        if (session != null && session.active) {
          _setPhase(AttentionPhase.alertActive);
          _startLiveLocationUpdates();
        } else if (failReason == AttentionFailReason.noContacts) {
          _setPhase(AttentionPhase.idle);
        } else if (phase == AttentionPhase.alerting) {
          // Si on est encore en alerting sans session, revenir idle
          if (session == null) {
            _setPhase(AttentionPhase.idle);
          } else {
            _setPhase(AttentionPhase.alertActive);
            _startLiveLocationUpdates();
          }
        }
      } catch (e, st) {
        MoodSafeLog.error('triggerAlert finally', e, st);
        _setPhase(AttentionPhase.idle);
      }
      MoodSafeLog.info('triggerAlert finally phase=$phase');
    }
  }

  static void startClassicSosCountdown({
    required int seconds,
    required void Function(int secondsLeft) onTick,
    required Future<void> Function() onFire,
  }) {
    try {
      _classicTimer?.cancel();
      _setPhase(AttentionPhase.classicCountdown);
      var left = seconds.clamp(1, 60);
      try {
        onTick(left);
      } catch (e) {
        MoodSafeLog.warn('classic onTick initial', e);
      }
      _classicTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
        left--;
        try {
          onTick(left);
        } catch (e) {
          MoodSafeLog.warn('classic onTick', e);
        }
        if (left <= 0) {
          t.cancel();
          _classicTimer = null;
          try {
            await onFire();
          } catch (e, st) {
            MoodSafeLog.error('classic onFire', e, st);
            _setPhase(AttentionPhase.idle);
          }
        }
      });
    } catch (e, st) {
      MoodSafeLog.error('startClassicSosCountdown', e, st);
      _setPhase(AttentionPhase.idle);
    }
  }

  static void cancelClassicSos() {
    try {
      _classicTimer?.cancel();
      _classicTimer = null;
      if (phase == AttentionPhase.classicCountdown) {
        _setPhase(AttentionPhase.cancelledSafe);
        Future<void>.delayed(const Duration(milliseconds: 700), () {
          if (phase == AttentionPhase.cancelledSafe) _setPhase(AttentionPhase.idle);
        });
      }
    } catch (e, st) {
      MoodSafeLog.error('cancelClassicSos', e, st);
      _setPhase(AttentionPhase.idle);
    }
  }

  static void markHoldSafeCancelled() {
    try {
      _setPhase(AttentionPhase.cancelledSafe);
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (phase == AttentionPhase.cancelledSafe) _setPhase(AttentionPhase.idle);
      });
    } catch (e, st) {
      MoodSafeLog.error('markHoldSafeCancelled', e, st);
      phase = AttentionPhase.idle;
    }
  }

  static void beginHolding() {
    try {
      _setPhase(AttentionPhase.holding);
    } catch (_) {
      phase = AttentionPhase.holding;
    }
  }

  static Future<bool> deactivateWithCode(String code) async {
    try {
      final real = await StorageService.getMoodSafeCode();
      final fake = await StorageService.getMoodSafeFakeCode();
      if (real != null && real.isNotEmpty && code == real) {
        await _stopAlert(realStop: true);
        return true;
      }
      if (fake != null && fake.isNotEmpty && code == fake) {
        MoodSafeLog.info('deactivateWithCode: faux code (UI only)');
        return true;
      }
      return false;
    } catch (e, st) {
      MoodSafeLog.error('deactivateWithCode', e, st);
      return false;
    }
  }

  static Future<void> stopAlertConfirmed() => _stopAlert(realStop: true);

  static Future<void> _stopAlert({required bool realStop}) async {
    try {
      _liveTimer?.cancel();
      _liveTimer = null;
      _classicTimer?.cancel();
      _classicTimer = null;
      if (!realStop) return;
      try {
        await StorageService.setAttentionAlertActive(false);
      } catch (e) {
        MoodSafeLog.warn('_stopAlert setActive false', e);
      }
      try {
        if (currentSession != null) {
          await _setSession(currentSession!.copyWith(active: false));
        } else {
          await _setSession(null);
        }
      } catch (e) {
        MoodSafeLog.warn('_stopAlert session', e);
      }
      alertStartedAt = null;
      lastAlertMessage = null;
      _setPhase(AttentionPhase.idle);
      Future<void>.delayed(const Duration(seconds: 2), () async {
        try {
          await _setSession(null);
        } catch (_) {}
      });
    } catch (e, st) {
      MoodSafeLog.error('_stopAlert', e, st);
      phase = AttentionPhase.idle;
    } finally {
      MoodSafeLog.info('_stopAlert finally phase=$phase');
    }
  }

  static void _startLiveLocationUpdates() {
    try {
      _liveTimer?.cancel();
      _liveTimer = Timer.periodic(liveLocationInterval, (_) async {
        try {
          if (!await StorageService.isAttentionAlertActive()) {
            _liveTimer?.cancel();
            return;
          }
          Position? pos;
          try {
            pos = await peekLocation();
          } catch (e) {
            MoodSafeLog.warn('live peekLocation', e);
          }
          String msg;
          try {
            msg = await MoodSafeService.buildMessage(
              prefix: '📍 MoodCast – Mise à jour position (alerte active) : ',
            );
          } catch (e) {
            MoodSafeLog.warn('live buildMessage', e);
            msg = '📍 MoodCast – Mise à jour position (détails indisponibles).';
          }
          try {
            final waves = await resolveDiffusionWaves();
            final phones =
                [...waves.priority, ...waves.circle].map((c) => c.cleanPhone).toList();
            if (phones.isNotEmpty) {
              await SmsSenderService.sendToMany(phones, msg);
            }
          } catch (e) {
            MoodSafeLog.warn('live SMS', e);
          }
          try {
            if (currentSession != null) {
              await _setSession(
                currentSession!.copyWith(
                  message: msg,
                  lastLat: pos?.latitude,
                  lastLng: pos?.longitude,
                ),
              );
            }
          } catch (e) {
            MoodSafeLog.warn('live session update', e);
          }
        } catch (e, st) {
          MoodSafeLog.error('live location tick', e, st);
        }
      });
    } catch (e, st) {
      MoodSafeLog.error('_startLiveLocationUpdates', e, st);
    }
  }

  static Future<void> scheduleCheckIn(Duration duration) async {
    try {
      final until = DateTime.now().add(duration);
      await StorageService.setAttentionCheckInUntil(until);
      try {
        await NotificationService.scheduleCheckInReminder(until);
      } catch (e) {
        MoodSafeLog.warn('scheduleCheckIn reminder', e);
      }
    } catch (e, st) {
      MoodSafeLog.error('scheduleCheckIn', e, st);
    }
  }

  static Future<void> confirmCheckInSafe() async {
    try {
      await StorageService.setAttentionCheckInUntil(null);
      try {
        await NotificationService.cancelCheckInReminder();
      } catch (e) {
        MoodSafeLog.warn('confirmCheckIn cancel reminder', e);
      }
    } catch (e, st) {
      MoodSafeLog.error('confirmCheckInSafe', e, st);
    }
  }

  static Future<void> handleCheckInExpiredIfNeeded() async {
    try {
      final until = await StorageService.getAttentionCheckInUntil();
      if (until == null) return;
      if (DateTime.now().isBefore(until)) return;
      await StorageService.setAttentionCheckInUntil(null);
      await triggerAlert();
    } catch (e, st) {
      MoodSafeLog.error('handleCheckInExpiredIfNeeded', e, st);
    }
  }

  static Future<Position?> peekLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        try {
          permission = await Geolocator.requestPermission();
        } catch (e) {
          MoodSafeLog.warn('peekLocation requestPermission', e);
          return null;
        }
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      try {
        if (!await Geolocator.isLocationServiceEnabled()) return null;
      } catch (e) {
        MoodSafeLog.warn('peekLocation isLocationServiceEnabled', e);
        return null;
      }
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(timeLimit: Duration(seconds: 5)),
        );
      } catch (e) {
        MoodSafeLog.warn('peekLocation getCurrentPosition', e);
        return null;
      }
    } catch (e, st) {
      MoodSafeLog.error('peekLocation', e, st);
      return null;
    } finally {
      // pas de ressource à libérer
    }
  }
}

enum AttentionFailReason { noContacts, sendFailed }

class AttentionAlertResult {
  const AttentionAlertResult({
    required this.success,
    required this.recipientCount,
    required this.message,
    this.priorityCount = 0,
    this.sentDirect = 0,
    this.openedComposer = false,
    this.session,
    this.reason,
  });

  final bool success;
  final int recipientCount;
  final int priorityCount;
  final String message;
  final int sentDirect;
  final bool openedComposer;
  final MoodSafeAlertSession? session;
  final AttentionFailReason? reason;
}
