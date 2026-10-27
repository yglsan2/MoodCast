import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'mood_safe_log.dart';

/// Envoi SMS : direct sur Android (permission SEND_SMS), composeur ailleurs.
class SmsSenderService {
  SmsSenderService._();

  static const MethodChannel _channel = MethodChannel('moodcast/sms');

  /// Envoie [body] à chaque numéro. Retourne le nombre d'envois réussis (direct)
  /// ou ouvre le composeur pour le premier contact si le direct n'est pas dispo.
  static Future<SmsSendResult> sendToMany(List<String> phones, String body) async {
    final cleaned = <String>[];
    try {
      cleaned.addAll(
        phones
            .map((p) => p.replaceAll(RegExp(r'[\s\.\-\(\)]'), ''))
            .where((p) => p.isNotEmpty)
            .toSet(),
      );
    } catch (e, st) {
      MoodSafeLog.error('SmsSenderService.sendToMany cleanPhones', e, st);
      return const SmsSendResult(sentDirect: 0, openedComposer: false, failed: 1);
    }

    if (cleaned.isEmpty) {
      MoodSafeLog.warn('SmsSenderService.sendToMany: aucun numéro valide');
      return const SmsSendResult(sentDirect: 0, openedComposer: false, failed: 0);
    }

    var sent = 0;
    var failed = 0;
    var openedComposer = false;

    try {
      // 1) Android : envoi direct si possible
      try {
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          for (final phone in cleaned) {
            try {
              final ok = await _channel.invokeMethod<bool>('sendSms', {
                'phone': phone,
                'body': body,
              });
              if (ok == true) {
                sent++;
              } else {
                failed++;
              }
            } catch (e) {
              MoodSafeLog.warn('SMS direct échoué pour $phone', e);
              failed++;
            }
          }
        }
      } catch (e, st) {
        MoodSafeLog.error('SmsSenderService Android channel', e, st);
        failed = cleaned.length;
      }

      // 2) Fallback composeur si aucun SMS direct
      try {
        if (sent == 0) {
          openedComposer = await openComposer(cleaned.first, body);
          if (!openedComposer) failed = cleaned.length;
        }
      } catch (e, st) {
        MoodSafeLog.error('SmsSenderService fallback composer', e, st);
        openedComposer = false;
      }

      // 3) Log résumé
      try {
        MoodSafeLog.info(
          'SMS batch terminé',
          'sent=$sent composer=$openedComposer failed=$failed total=${cleaned.length}',
        );
      } catch (_) {}

      // 4) Garde-fou résultat cohérent
      try {
        if (sent < 0) sent = 0;
        if (failed < 0) failed = 0;
      } catch (_) {}

      return SmsSendResult(
        sentDirect: sent,
        openedComposer: openedComposer,
        failed: failed,
      );
    } catch (e, st) {
      MoodSafeLog.error('SmsSenderService.sendToMany fatal', e, st);
      // Dernier recours : tenter le composeur
      final opened = await openComposer(cleaned.first, body);
      return SmsSendResult(
        sentDirect: 0,
        openedComposer: opened,
        failed: cleaned.length,
      );
    } finally {
      MoodSafeLog.info('SmsSenderService.sendToMany finally');
    }
  }

  static Future<bool> openComposer(String phone, String body) async {
    final clean = phone.replaceAll(RegExp(r'[\s\.\-\(\)]'), '');
    if (clean.isEmpty) return false;
    try {
      final uri = Uri.parse(
        'sms:$clean${body.isNotEmpty ? '?body=${Uri.encodeComponent(body)}' : ''}',
      );
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return true;
        }
      } catch (e) {
        MoodSafeLog.warn('openComposer canLaunch/launch', e);
      }
      // Fallback URI smsto:
      try {
        final alt = Uri.parse(
          'smsto:$clean${body.isNotEmpty ? '?body=${Uri.encodeComponent(body)}' : ''}',
        );
        if (await canLaunchUrl(alt)) {
          await launchUrl(alt, mode: LaunchMode.externalApplication);
          return true;
        }
      } catch (e) {
        MoodSafeLog.warn('openComposer smsto fallback', e);
      }
      return false;
    } catch (e, st) {
      MoodSafeLog.error('openComposer', e, st);
      return false;
    } finally {
      // no-op cleanup hook
    }
  }
}

class SmsSendResult {
  const SmsSendResult({
    required this.sentDirect,
    required this.openedComposer,
    required this.failed,
  });

  final int sentDirect;
  final bool openedComposer;
  final int failed;

  bool get success => sentDirect > 0 || openedComposer;
}
