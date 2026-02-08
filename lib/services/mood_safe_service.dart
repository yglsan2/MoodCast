import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/emotions.dart';
import 'storage_service.dart';

/// Alerte danger MoodSafe : message type "Alerte danger", position, optionnel dernier mood.
/// Envoi au(x) contact(s) de confiance (principal + optionnel 2 et 3).
class MoodSafeService {
  MoodSafeService._();

  static const String _messagePrefix =
      'Alerte danger : Je me sens menacé(e). Voici ma localisation en temps réel. ';
  static const Duration _locationTimeout = Duration(seconds: 5);

  /// Construit le message d'alerte (position + optionnel dernier mood).
  static Future<String> buildMessage() async {
    String body = _messagePrefix;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
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
    } catch (_) {
      body += 'Ma position n\'a pas pu être récupérée.';
    }

    final includeMood = await StorageService.getMoodSafeIncludeMood();
    if (includeMood) {
      final moodCasts = await StorageService.getMoodCasts();
      moodCasts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (moodCasts.isNotEmpty) {
        final last = moodCasts.first;
        body += '\n\nDernier mood : ${Emotions.label(last.emotion)}.';
      }
    }

    return body;
  }

  /// Déclenche l'alerte : ouvre le SMS au premier contact avec le message d'alerte.
  /// Retourne (succès, message utilisé, liste des autres numéros pour envoi supplémentaire).
  static Future<MoodSafeTriggerResult> trigger() async {
    final phones = await StorageService.getMoodSafePhones();
    if (phones.isEmpty) {
      return MoodSafeTriggerResult(success: false, message: '', remainingPhones: []);
    }

    final message = await buildMessage();
    final first = phones.first;
    final remaining = phones.length > 1 ? phones.sublist(1) : <String>[];

    final opened = await _openSmsTo(first, message);
    return MoodSafeTriggerResult(
      success: opened,
      message: message,
      remainingPhones: remaining,
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

  static Future<bool> _openSmsTo(String phone, String body) async {
    return openSmsTo(phone, body);
  }
}

class MoodSafeTriggerResult {
  const MoodSafeTriggerResult({
    required this.success,
    required this.message,
    required this.remainingPhones,
  });

  final bool success;
  final String message;
  final List<String> remainingPhones;
}
