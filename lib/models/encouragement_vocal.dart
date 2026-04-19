/// Message vocal enregistré pour se réconforter ou encourager un proche (MoodSOS).
class EncouragementVocal {
  EncouragementVocal({
    required this.id,
    required this.fileName,
    required this.target,
    required this.lengthMode,
    required this.durationSeconds,
    required this.createdAt,
  });

  final String id;
  final String fileName;
  final EncouragementTarget target;
  final EncouragementLengthMode lengthMode;
  final int durationSeconds;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'target': target.name,
        'lengthMode': lengthMode.name,
        'durationSeconds': durationSeconds,
        'createdAt': createdAt.toIso8601String(),
      };

  static EncouragementVocal fromJson(Map<String, dynamic> json) {
    EncouragementTarget t = EncouragementTarget.self;
    for (final v in EncouragementTarget.values) {
      if (v.name == json['target']) {
        t = v;
        break;
      }
    }
    EncouragementLengthMode m = EncouragementLengthMode.short;
    for (final v in EncouragementLengthMode.values) {
      if (v.name == json['lengthMode']) {
        m = v;
        break;
      }
    }
    return EncouragementVocal(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      target: t,
      lengthMode: m,
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

enum EncouragementTarget { self, proche }

enum EncouragementLengthMode { short, long }
