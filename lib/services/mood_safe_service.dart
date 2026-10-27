import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/emotions.dart';
import 'mood_safe_log.dart';
import 'sms_sender_service.dart';
import 'storage_service.dart';

/// Alerte danger MoodSafe : message type "Alerte danger", position, optionnel dernier mood.
/// Envoi au(x) contact(s) de confiance (principal + optionnel 2 et 3).
class MoodSafeService {
  MoodSafeService._();

  static const String _messagePrefix =
      'Alerte danger : Je me sens menacé(e). Voici ma localisation en temps réel. ';
  static const Duration _locationTimeout = Duration(seconds: 5);

  /// Construit le message d'alerte (position + optionnel dernier mood).
  static Future<String> buildMessage({String? prefix}) async {
    var body = prefix ?? _messagePrefix;
    try {
      // 1) Permission
      try {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
      } catch (e) {
        MoodSafeLog.warn('buildMessage permission', e);
      }

      // 2) GPS
      try {
        if (await Geolocator.isLocationServiceEnabled()) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(timeLimit: _locationTimeout),
          );
          final url =
              'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
          body += 'Ma position : $url';
        } else {
          body += 'Ma position n\'a pas pu être récupérée.';
        }
      } catch (e) {
        MoodSafeLog.warn('buildMessage GPS', e);
        body += 'Ma position n\'a pas pu être récupérée.';
      }

      // 3) Mood optionnel
      try {
        final includeMood = await StorageService.getMoodSafeIncludeMood();
        if (includeMood) {
          final moodCasts = await StorageService.getMoodCasts();
          moodCasts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          if (moodCasts.isNotEmpty) {
            final last = moodCasts.first;
            body += '\n\nDernier mood : ${Emotions.label(last.emotion)}.';
          }
        }
      } catch (e) {
        MoodSafeLog.warn('buildMessage mood', e);
      }

      // 4) Timestamp de secours
      try {
        body += '\nHeure : ${DateTime.now().toIso8601String()}';
      } catch (_) {}

      return body;
    } catch (e, st) {
      MoodSafeLog.error('buildMessage fatal', e, st);
      return '${prefix ?? _messagePrefix}Ma position n\'a pas pu être récupérée.';
    } finally {
      MoodSafeLog.info('buildMessage finally len=${body.length}');
    }
  }

  /// Déclenche l'alerte vers tous les contacts (SMS auto Android, composeur sinon).
  static Future<MoodSafeTriggerResult> trigger() async {
    final phones = await StorageService.getMoodSafePhones();
    if (phones.isEmpty) {
      return MoodSafeTriggerResult(success: false, message: '', remainingPhones: []);
    }

    final message = await buildMessage();
    final result = await SmsSenderService.sendToMany(phones, message);
    final remaining = phones.length > 1 && result.openedComposer
        ? phones.sublist(1)
        : <String>[];

    return MoodSafeTriggerResult(
      success: result.success,
      message: message,
      remainingPhones: remaining,
      sentDirect: result.sentDirect,
    );
  }

  /// Ouvre l'app SMS vers un numéro avec le message donné.
  static Future<bool> openSmsTo(String phone, String body) async {
    final clean = phone.replaceAll(RegExp(r'[\s\.\-\(\)]'), '');
    if (clean.isEmpty) return false;
    final uri = Uri.parse(
      'sms:$clean${body.isNotEmpty ? '?body=${Uri.encodeComponent(body)}' : ''}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {}
    return false;
  }

}

class MoodSafeTriggerResult {
  const MoodSafeTriggerResult({
    required this.success,
    required this.message,
    required this.remainingPhones,
    this.sentDirect = 0,
  });

  final bool success;
  final String message;
  final List<String> remainingPhones;
  final int sentDirect;
}
