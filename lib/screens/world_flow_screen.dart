import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/world_flow_data.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';

class WorldFlowScreen extends StatefulWidget {
  const WorldFlowScreen({super.key});

  @override
  State<WorldFlowScreen> createState() => _WorldFlowScreenState();
}

class _WorldFlowScreenState extends State<WorldFlowScreen> {
  WorldFlowData? _data;
  List<WorldFlowRegion> _userRegions = [];
  String _filter = 'today';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.fetchWorldFlowData(timeFilter: _filter);
    final moodCasts = await StorageService.getMoodCasts();
    final withLocation = moodCasts.where((c) => c.location != null).toList();
    final userRegions = withLocation
        .map((c) => WorldFlowRegion(
              name: 'Votre MoodCast',
              latitude: c.location!.latitude,
              longitude: c.location!.longitude,
              dominantEmotion: c.emotion,
              averageIntensity: c.intensity.toDouble(),
              averageEnergy: c.energy.toDouble(),
            ))
        .toList();
    if (mounted) {
      setState(() {
        _data = data;
        _userRegions = userRegions;
        _loading = false;
      });
    }
  }

  static Color _emotionColor(String e) => AppColors.emotionColor(e);
  static String _emotionEmoji(String e) {
    const m = {
      'joie': '😊', 'sérénité': '😌', 'enthousiasme': '🤩', 'gratitude': '🙏',
      'stress': '😰', 'anxiété': '😟', 'fatigue': '😴', 'motivation': '💪',
      'tristesse': '😢', 'mélancolie': '🌧️', 'colere': '😠', 'irritation': '😤',
      'doute': '🤔', 'espoir': '🌟', 'amour': '❤️',
    };
    return m[e] ?? '😐';
  }

  List<WorldFlowRegion> get _allRegions {
    final fromApi = _data?.regions ?? [];
    return [...fromApi, ..._userRegions];
  }

  int get _apiRegionsCount => _data?.regions.length ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '🌍 WorldFlow',
        gradient: AppColors.gradientOcean,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
            tooltip: 'Actualiser',
          ),
          PopupMenuButton<String>(
            initialValue: _filter,
            onSelected: (v) {
              setState(() => _filter = v);
              _load();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'today', child: Text('Aujourd\'hui')),
              const PopupMenuItem(value: 'week', child: Text('Semaine')),
              const PopupMenuItem(value: 'month', child: Text('Mois')),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.filter_list_rounded),
            ),
          ),
        ],
      ),
      body: Container(
        color: AppColors.background,
        child: _loading && _data == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_data != null || _userRegions.isNotEmpty)
                    FeelGoodCard(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: AppColors.gradientOcean,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _filter == 'today' ? 'Aujourd\'hui' : _filter == 'week' ? 'Semaine' : 'Mois',
                                  style: const TextStyle(
                                    color: AppColors.textOnPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${(_data?.totalMoodCasts ?? 0) + _userRegions.length} MoodCasts · ${_allRegions.length} point${_allRegions.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (_userRegions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${_emotionEmoji(_userRegions.first.dominantEmotion)} Vos MoodCasts avec position apparaissent sur la carte',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else if (_data?.trends.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              _data!.trends.first,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.teal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  Expanded(
                    child: _allRegions.isEmpty
                        ? Center(
                            child: FeelGoodCard(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              gradient: AppColors.gradientSecondary,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.public_rounded, size: 48, color: AppColors.primary),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Aucune donnée pour cette période',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Les MoodCasts enregistrés avec position (MoodCast) apparaîtront ici.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                _allRegions.first.latitude,
                                _allRegions.first.longitude,
                              ),
                              initialZoom: _allRegions.length == 1 ? 10.0 : 2.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.moodcast.worldflow',
                              ),
                              MarkerLayer(
                                markers: _allRegions.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final r = entry.value;
                                  final isUser = i >= _apiRegionsCount;
                                  return Marker(
                                    point: LatLng(r.latitude, r.longitude),
                                    width: 44,
                                    height: 44,
                                    child: Tooltip(
                                      message: isUser
                                          ? 'Votre MoodCast · ${_emotionEmoji(r.dominantEmotion)} ${r.dominantEmotion}'
                                          : '${r.name}\n${_emotionEmoji(r.dominantEmotion)} ${r.dominantEmotion}',
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _emotionColor(r.dominantEmotion),
                                          shape: BoxShape.circle,
                                          border: isUser
                                              ? Border.all(color: Colors.white, width: 3)
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: _emotionColor(r.dominantEmotion).withValues(alpha: 0.5),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            _emotionEmoji(r.dominantEmotion),
                                            style: const TextStyle(fontSize: 22),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
