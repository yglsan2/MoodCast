import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mood_cast.dart';

class StorageService {
  StorageService._();

  static const String _key = 'moodcasts';

  static Future<List<MoodCast>> getMoodCasts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr == null) return [];
      final list = jsonDecode(jsonStr) as List<dynamic>?;
      if (list == null) return [];
      return list
          .map((e) => MoodCast.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> saveMoodCast(MoodCast moodCast) async {
    try {
      final list = await getMoodCasts();
      list.add(moodCast);
      final prefs = await SharedPreferences.getInstance();
      return prefs.setString(
        _key,
        jsonEncode(list.map((e) => e.toJson()).toList()),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteMoodCast(String id) async {
    try {
      final list = await getMoodCasts();
      list.removeWhere((c) => c.id == id);
      final prefs = await SharedPreferences.getInstance();
      return prefs.setString(
        _key,
        jsonEncode(list.map((e) => e.toJson()).toList()),
      );
    } catch (_) {
      return false;
    }
  }

  // ——— Biscuit chinois : 1 par jour ———
  static const String _keyFortuneDate = 'fortune_cookie_date';
  static const String _keyFortuneMessage = 'fortune_cookie_message';

  /// Date du dernier biscuit ouvert (yyyy-MM-dd) ou null.
  static Future<String?> getLastFortuneDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyFortuneDate);
    } catch (_) {
      return null;
    }
  }

  /// Message du dernier biscuit ouvert.
  static Future<String?> getLastFortuneMessage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyFortuneMessage);
    } catch (_) {
      return null;
    }
  }

  /// Enregistre l’ouverture d’un biscuit aujourd’hui.
  static Future<void> saveTodayFortune(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _todayString();
      await prefs.setString(_keyFortuneDate, today);
      await prefs.setString(_keyFortuneMessage, message);
    } catch (_) {}
  }

  static String _todayString() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// True si l’utilisateur a déjà ouvert son biscuit aujourd’hui.
  static Future<bool> hasAlreadyOpenedFortuneToday() async {
    final last = await getLastFortuneDate();
    return last == _todayString();
  }

  // ——— Alerte proche (SOS sécurité) ———
  static const String _keyAlertContactName = 'alert_contact_name';
  static const String _keyAlertContactPhone = 'alert_contact_phone';

  static Future<String?> getAlertContactName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAlertContactName);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getAlertContactPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAlertContactPhone);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setAlertContact({String? name, String? phone}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (name != null) await prefs.setString(_keyAlertContactName, name);
      if (phone != null) await prefs.setString(_keyAlertContactPhone, phone);
    } catch (_) {}
  }

  static Future<bool> hasAlertContact() async {
    final phone = await getAlertContactPhone();
    return phone != null && phone.trim().isNotEmpty;
  }

  // ——— MoodSafe (alerte danger) ———
  static const String _keyMoodSafeIncludeMood = 'moodsafe_include_mood';
  static const String _keyMoodSafeCode = 'moodsafe_deactivate_code';
  static const String _keyMoodSafeFakeCode = 'moodsafe_fake_code';
  static const String _keyMoodSafePhone2 = 'moodsafe_phone_2';
  static const String _keyMoodSafePhone3 = 'moodsafe_phone_3';

  static Future<bool> getMoodSafeIncludeMood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyMoodSafeIncludeMood) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setMoodSafeIncludeMood(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyMoodSafeIncludeMood, value);
    } catch (_) {}
  }

  static Future<String?> getMoodSafeCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyMoodSafeCode);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setMoodSafeCode(String? code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (code != null && code.isNotEmpty) {
        await prefs.setString(_keyMoodSafeCode, code);
      } else {
        await prefs.remove(_keyMoodSafeCode);
      }
    } catch (_) {}
  }

  static Future<String?> getMoodSafeFakeCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyMoodSafeFakeCode);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setMoodSafeFakeCode(String? code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (code != null && code.isNotEmpty) {
        await prefs.setString(_keyMoodSafeFakeCode, code);
      } else {
        await prefs.remove(_keyMoodSafeFakeCode);
      }
    } catch (_) {}
  }

  static Future<String?> getMoodSafePhone2() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyMoodSafePhone2);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getMoodSafePhone3() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyMoodSafePhone3);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setMoodSafePhones({String? phone2, String? phone3}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (phone2 != null) {
        if (phone2.trim().isEmpty) {
          await prefs.remove(_keyMoodSafePhone2);
        } else {
          await prefs.setString(_keyMoodSafePhone2, phone2);
        }
      }
      if (phone3 != null) {
        if (phone3.trim().isEmpty) {
          await prefs.remove(_keyMoodSafePhone3);
        } else {
          await prefs.setString(_keyMoodSafePhone3, phone3);
        }
      }
    } catch (_) {}
  }

  /// Liste des numéros MoodSafe : contact principal + optionnels 2 et 3 (sans espaces).
  static Future<List<String>> getMoodSafePhones() async {
    final list = <String>[];
    final p1 = await getAlertContactPhone();
    if (p1 != null && p1.trim().isNotEmpty) {
      list.add(p1.replaceAll(RegExp(r'[\s\.\-\(\)]'), ''));
    }
    final p2 = await getMoodSafePhone2();
    if (p2 != null && p2.trim().isNotEmpty) {
      list.add(p2.replaceAll(RegExp(r'[\s\.\-\(\)]'), ''));
    }
    final p3 = await getMoodSafePhone3();
    if (p3 != null && p3.trim().isNotEmpty) {
      list.add(p3.replaceAll(RegExp(r'[\s\.\-\(\)]'), ''));
    }
    return list;
  }

  // ——— Horoscope (date de naissance) ———
  static const String _keyBirthDate = 'horoscope_birth_date';

  static Future<DateTime?> getBirthDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_keyBirthDate);
      if (s == null) return null;
      return DateTime.tryParse(s);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setBirthDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBirthDate, date.toIso8601String());
    } catch (_) {}
  }

  // ——— Engagement (rituel, streaks, badges, résumé, MoodPulse, etc.) ———
  static const String _keyUserName = 'engagement_user_name';
  static const String _keyRoutineIntention = 'routine_intention'; // intention du jour
  static const String _keyRoutineMorningDate = 'routine_morning_date'; // dernier matin fait (yyyy-MM-dd)
  static const String _keyRoutineMorningEmotion = 'routine_morning_emotion'; // émotion micro-mood du matin
  static const String _keyRoutineEveningDate = 'routine_evening_date';
  static const String _keyRoutineEveningEmotion = 'routine_evening_emotion';
  static const String _keyRoutineReminderMorning = 'routine_reminder_morning'; // "1" = enabled
  static const String _keyRoutineReminderMorningTime = 'routine_reminder_morning_time'; // "08:00"
  static const String _keyRoutineReminderEvening = 'routine_reminder_evening';
  static const String _keyRoutineReminderEveningTime = 'routine_reminder_evening_time'; // "20:00"
  static const String _keyMoodPulsePhone = 'mood_pulse_phone';
  static const String _keyRiskDaysReminder = 'risk_days_reminder';
  static const String _keyUnlockedBadges = 'unlocked_badges'; // JSON list of badge ids
  static const String _keyWeeklySummaryLastShown = 'weekly_summary_last_shown'; // yyyy-MM-dd
  static const String _keyMoodSafeCheckinLast = 'moodsafe_checkin_last';

  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserName);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setUserName(String? name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (name != null && name.isNotEmpty) {
        await prefs.setString(_keyUserName, name.trim());
      } else {
        await prefs.remove(_keyUserName);
      }
    } catch (_) {}
  }

  static Future<String?> getRoutineIntention() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRoutineIntention);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setRoutineIntention(String? text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (text != null && text.isNotEmpty) {
        await prefs.setString(_keyRoutineIntention, text.trim());
      } else {
        await prefs.remove(_keyRoutineIntention);
      }
    } catch (_) {}
  }

  static Future<String?> getRoutineMorningDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRoutineMorningDate);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setRoutineMorningDone(String dateYyyyMmDd, {String? emotion}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRoutineMorningDate, dateYyyyMmDd);
      if (emotion != null) await prefs.setString(_keyRoutineMorningEmotion, emotion);
    } catch (_) {}
  }

  static Future<String?> getRoutineMorningEmotion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRoutineMorningEmotion);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getRoutineEveningDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRoutineEveningDate);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setRoutineEveningDone(String dateYyyyMmDd, {String? emotion}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRoutineEveningDate, dateYyyyMmDd);
      if (emotion != null) await prefs.setString(_keyRoutineEveningEmotion, emotion);
    } catch (_) {}
  }

  static Future<String?> getRoutineEveningEmotion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRoutineEveningEmotion);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> getRoutineReminderMorningEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRoutineReminderMorning) == '1';
    } catch (_) {
      return false;
    }
  }

  static Future<void> setRoutineReminderMorningEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRoutineReminderMorning, value ? '1' : '0');
    } catch (_) {}
  }

  static Future<String> getRoutineReminderMorningTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRoutineReminderMorningTime) ?? '08:00';
    } catch (_) {
      return '08:00';
    }
  }

  static Future<void> setRoutineReminderMorningTime(String time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRoutineReminderMorningTime, time);
    } catch (_) {}
  }

  static Future<bool> getRoutineReminderEveningEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRoutineReminderEvening) == '1';
    } catch (_) {
      return false;
    }
  }

  static Future<void> setRoutineReminderEveningEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRoutineReminderEvening, value ? '1' : '0');
    } catch (_) {}
  }

  static Future<String> getRoutineReminderEveningTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRoutineReminderEveningTime) ?? '20:00';
    } catch (_) {
      return '20:00';
    }
  }

  static Future<void> setRoutineReminderEveningTime(String time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRoutineReminderEveningTime, time);
    } catch (_) {}
  }

  static Future<String?> getMoodPulsePhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyMoodPulsePhone);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setMoodPulsePhone(String? phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (phone != null && phone.trim().isNotEmpty) {
        await prefs.setString(_keyMoodPulsePhone, phone.trim());
      } else {
        await prefs.remove(_keyMoodPulsePhone);
      }
    } catch (_) {}
  }

  static Future<bool> getRiskDaysReminderEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyRiskDaysReminder) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setRiskDaysReminderEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRiskDaysReminder, value);
    } catch (_) {}
  }

  static Future<List<String>> getUnlockedBadges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_keyUnlockedBadges);
      if (json == null) return [];
      final list = jsonDecode(json) as List<dynamic>?;
      return list?.map((e) => e as String).toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> addUnlockedBadge(String badgeId) async {
    final list = await getUnlockedBadges();
    if (list.contains(badgeId)) return;
    list.add(badgeId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUnlockedBadges, jsonEncode(list));
    } catch (_) {}
  }

  static Future<String?> getWeeklySummaryLastShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyWeeklySummaryLastShown);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setWeeklySummaryShown(String dateYyyyMmDd) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyWeeklySummaryLastShown, dateYyyyMmDd);
    } catch (_) {}
  }

  static Future<String?> getMoodSafeCheckinLastDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyMoodSafeCheckinLast);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setMoodSafeCheckinDone(String dateYyyyMmDd) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyMoodSafeCheckinLast, dateYyyyMmDd);
    } catch (_) {}
  }

  // ——— Votes conseils Soutien (local, classement personnel) ———
  static const String _keySupportVotes = 'support_votes';

  /// Map tipId → nombre de « Ça m'a aidé ».
  static Future<Map<String, int>> getSupportVotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keySupportVotes);
      if (jsonStr == null) return {};
      final map = jsonDecode(jsonStr) as Map<String, dynamic>?;
      if (map == null) return {};
      return map.map((k, v) => MapEntry(k, (v is int) ? v : 0));
    } catch (_) {
      return {};
    }
  }

  /// Incrémente le vote pour un conseil et sauvegarde.
  static Future<void> incrementSupportVote(String tipId) async {
    try {
      final votes = await getSupportVotes();
      votes[tipId] = (votes[tipId] ?? 0) + 1;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySupportVotes, jsonEncode(votes));
    } catch (_) {}
  }

  static String todayString() => _todayString();
}
