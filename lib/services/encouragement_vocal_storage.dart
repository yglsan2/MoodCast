import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/encouragement_vocal.dart';

/// Stockage local des vocaux d'encouragement (fichiers + métadonnées JSON).
class EncouragementVocalStorage {
  EncouragementVocalStorage._();

  static const _prefsKey = 'encouragement_vocals_v1';
  static const _subDirName = 'encouragement_vocals';
  static const int maxItems = 40;

  static Future<Directory> vocalDirectory() async {
    final doc = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(doc.path, _subDirName));
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return d;
  }

  static Future<String> fullPath(EncouragementVocal v) async {
    final dir = await vocalDirectory();
    return p.join(dir.path, v.fileName);
  }

  static Future<List<EncouragementVocal>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final items = list
          .map((e) => EncouragementVocal.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveList(List<EncouragementVocal> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static String newRecordingId() =>
      '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1 << 20)}';

  /// Enregistre un fichier déjà présent dans [vocalDirectory] (nom = [fileName]).
  static Future<EncouragementVocal> appendMetadata({
    required String fileName,
    required EncouragementTarget target,
    required EncouragementLengthMode lengthMode,
    required int durationSeconds,
  }) async {
    var items = await loadAll();
    final id = p.basenameWithoutExtension(fileName);
    final vocal = EncouragementVocal(
      id: id,
      fileName: fileName,
      target: target,
      lengthMode: lengthMode,
      durationSeconds: durationSeconds,
      createdAt: DateTime.now(),
    );
    items = [vocal, ...items.where((e) => e.id != id)];

    while (items.length > maxItems) {
      final removed = items.removeLast();
      try {
        final path = await fullPath(removed);
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }

    await _saveList(items);
    return vocal;
  }

  static Future<void> delete(EncouragementVocal v) async {
    try {
      final path = await fullPath(v);
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    final items = await loadAll();
    await _saveList(items.where((e) => e.id != v.id).toList());
  }
}
