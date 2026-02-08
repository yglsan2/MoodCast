/// Données agrégées WorldFlow (carte mondiale).
class WorldFlowData {
  const WorldFlowData({
    required this.totalMoodCasts,
    required this.uniqueRegions,
    required this.globalTrend,
    required this.trends,
    required this.regions,
  });

  final int totalMoodCasts;
  final int uniqueRegions;
  final String globalTrend;
  final List<String> trends;
  final List<WorldFlowRegion> regions;

  factory WorldFlowData.fromJson(Map<String, dynamic> json) {
    final regionsList = json['regions'] as List<dynamic>? ?? [];
    return WorldFlowData(
      totalMoodCasts: json['totalMoodCasts'] as int? ?? 0,
      uniqueRegions: json['uniqueRegions'] as int? ?? 0,
      globalTrend: json['globalTrend'] as String? ?? '—',
      trends: (json['trends'] as List<dynamic>?)?.cast<String>() ?? [],
      regions: regionsList
          .map((e) => WorldFlowRegion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorldFlowRegion {
  const WorldFlowRegion({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.dominantEmotion,
    required this.averageIntensity,
    required this.averageEnergy,
    this.radius = 50000,
    this.description = '',
  });

  final String name;
  final double latitude;
  final double longitude;
  final String dominantEmotion;
  final double averageIntensity;
  final double averageEnergy;
  final double radius;
  final String description;

  factory WorldFlowRegion.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>?;
    return WorldFlowRegion(
      name: json['name'] as String? ?? '',
      latitude: (loc?['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (loc?['longitude'] as num?)?.toDouble() ?? 0,
      dominantEmotion: json['dominantEmotion'] as String? ?? 'neutre',
      averageIntensity: (json['averageIntensity'] as num?)?.toDouble() ?? 0,
      averageEnergy: (json['averageEnergy'] as num?)?.toDouble() ?? 0,
      radius: (json['radius'] as num?)?.toDouble() ?? 50000,
      description: json['description'] as String? ?? '',
    );
  }
}
