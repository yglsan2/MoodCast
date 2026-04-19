/// Génère les liens et contenus pour ajouter un "Post-it Mood" à l'agenda.
/// Google Calendar, Outlook, et format ICS (Apple Calendar, etc.).
class CalendarPostitService {
  CalendarPostitService._();

  static String _toUtcIso(DateTime d) {
    return '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}'
        'T${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}${d.second.toString().padLeft(2, '0')}Z';
  }

  static String _escapeIcs(String s) {
    return s.replaceAll('\\', '\\\\').replaceAll(';', '\\;').replaceAll(',', '\\,').replaceAll('\n', '\\n');
  }

  /// URL pour ouvrir Google Calendar avec l'événement pré-rempli.
  static String googleCalendarUrl({
    required String title,
    required String description,
    required DateTime start,
    DateTime? end,
  }) {
    final endDate = end ?? start.add(const Duration(hours: 1));
    final startStr = _toUtcIso(start.toUtc());
    final endStr = _toUtcIso(endDate.toUtc());
    final encodedTitle = Uri.encodeComponent(title);
    final encodedDesc = Uri.encodeComponent(description);
    return 'https://calendar.google.com/calendar/render?'
        'action=TEMPLATE'
        '&text=$encodedTitle'
        '&details=$encodedDesc'
        '&dates=$startStr/$endStr';
  }

  /// URL pour ouvrir Outlook (web) avec l'événement pré-rempli.
  static String outlookUrl({
    required String title,
    required String description,
    required DateTime start,
    DateTime? end,
  }) {
    final endDate = end ?? start.add(const Duration(hours: 1));
    final startStr = '${start.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first}Z';
    final endStr = '${endDate.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first}Z';
    final encodedTitle = Uri.encodeComponent(title);
    final encodedDesc = Uri.encodeComponent(description);
    return 'https://outlook.live.com/calendar/0/action/compose?'
        'subject=$encodedTitle'
        '&body=$encodedDesc'
        '&startdt=$startStr'
        '&enddt=$endStr';
  }

  /// Contenu ICS (pour copier et importer dans Apple Calendar, etc.).
  static String icsContent({
    required String title,
    required String description,
    required DateTime start,
    DateTime? end,
  }) {
    final endDate = end ?? start.add(const Duration(hours: 1));
    final startStr = _toUtcIso(start.toUtc());
    final endStr = _toUtcIso(endDate.toUtc());
    final safeTitle = _escapeIcs(title);
    final safeDesc = _escapeIcs(description);
    return [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//MoodCast//Post-it Mood//FR',
      'BEGIN:VEVENT',
      'DTSTART:$startStr',
      'DTEND:$endStr',
      'SUMMARY:$safeTitle',
      'DESCRIPTION:$safeDesc',
      'END:VEVENT',
      'END:VCALENDAR',
    ].join('\r\n');
  }
}
