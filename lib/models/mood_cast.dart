/// Modèle d'un MoodCast (enregistrement + analyse + podcast).
class MoodCast {
  const MoodCast({
    required this.id,
    required this.timestamp,
    required this.emotion,
    required this.intensity,
    required this.energy,
    required this.podcastText,
    required this.style,
    this.audioPath,
    this.location,
  });

  final String id;
  final DateTime timestamp;
  final String emotion;
  final int intensity;
  final int energy;
  final String podcastText;
  final String style;
  final String? audioPath;
  final MoodLocation? location;

  factory MoodCast.fromJson(Map<String, dynamic> json) {
    return MoodCast(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      emotion: json['emotion'] as String? ?? 'neutre',
      intensity: (json['intensity'] is num) ? (json['intensity'] as num).toInt() : 5,
      energy: (json['energy'] is num) ? (json['energy'] as num).toInt() : 5,
      podcastText: json['podcast'] is Map
          ? (json['podcast'] as Map)['text'] as String? ?? ''
          : json['podcastText'] as String? ?? '',
      style: json['style'] as String? ?? 'motivation',
      audioPath: json['audioUri'] as String? ?? json['audioPath'] as String?,
      location: json['location'] != null
          ? MoodLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'emotion': emotion,
      'intensity': intensity,
      'energy': energy,
      'podcast': {'text': podcastText, 'style': style},
      'podcastText': podcastText,
      'style': style,
      'audioUri': audioPath,
      'audioPath': audioPath,
      if (location != null) 'location': location!.toJson(),
    };
  }
}

class MoodLocation {
  const MoodLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory MoodLocation.fromJson(Map<String, dynamic> json) {
    return MoodLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'latitude': latitude, 'longitude': longitude};
}
