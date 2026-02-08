import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'storage_service.dart';

/// Service d'alerte proche : un geste ouvre le SMS avec la position.
/// Aucune manipulation supplémentaire — l'utilisateur n'a qu'à envoyer le SMS.
class AlertProcheService {
  AlertProcheService._();

  static const String _messagePrefix = 'MoodCast – Je me sens en danger. ';
  static const Duration _locationTimeout = Duration(seconds: 5);

  /// Ouvre l'app SMS avec le proche préenregistré et un message contenant la position.
  /// Si aucun proche n'est configuré, retourne false (il faudra afficher un message).
  static Future<bool> trigger() async {
    final phone = await StorageService.getAlertContactPhone();
    if (phone == null || phone.trim().isEmpty) return false;

    final cleanPhone = phone.replaceAll(RegExp(r'[\s\.\-\(\)]'), '');
    String body = _messagePrefix;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      if (await Geolocator.isLocationServiceEnabled()) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            timeLimit: _locationTimeout,
          ),
        );
        final url = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
        body += 'Ma position : $url';
      } else {
        body += 'Ma position n\'a pas pu être récupérée.';
      }
    } catch (_) {
      body += 'Ma position n\'a pas pu être récupérée.';
    }

    final uri = Uri.parse(
      'sms:$cleanPhone${body.isNotEmpty ? '?body=${Uri.encodeComponent(body)}' : ''}',
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
