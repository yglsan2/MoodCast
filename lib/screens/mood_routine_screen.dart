import 'package:flutter/material.dart';

import '../models/emotions.dart';
import '../services/horoscope_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';
import 'mood_cast_screen.dart';
import 'settings_screen.dart';

/// Rituel matin / soir : intention, micro-mood, astro du jour.
class MoodRoutineScreen extends StatefulWidget {
  const MoodRoutineScreen({super.key});

  @override
  State<MoodRoutineScreen> createState() => _MoodRoutineScreenState();
}

class _MoodRoutineScreenState extends State<MoodRoutineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _userName;
  String _intention = '';
  String? _morningEmotion;
  String? _eveningEmotion;
  String _astroShort = '';
  String _today = '';
  bool _loading = true;
  final _intentionController = TextEditingController();

  static const List<String> _microMoodEmotions = [
    'joie',
    'heureux',
    'sérénité',
    'calme',
    'enthousiasme',
    'motivation',
    'gratitude',
    'détente',
    'fatigue',
    'stress',
    'tristesse',
  ];

  static const Map<String, String> _emotionEmoji = {
    'joie': '😊',
    'heureux': '😄',
    'sérénité': '😌',
    'calme': '🌿',
    'enthousiasme': '✨',
    'motivation': '💪',
    'gratitude': '🙏',
    'détente': '😎',
    'fatigue': '😴',
    'stress': '😰',
    'tristesse': '😢',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _intentionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final name = await StorageService.getUserName();
    final intention = await StorageService.getRoutineIntention();
    final morningEmotion = await StorageService.getRoutineMorningEmotion();
    final eveningEmotion = await StorageService.getRoutineEveningEmotion();
    _today = StorageService.todayString();
    _intentionController.text = intention ?? '';

    final birthDate = await StorageService.getBirthDate();
    final sign = birthDate != null
        ? HoroscopeService.getSignForDate(birthDate)
        : HoroscopeService.getSignForDate(DateTime.now());
    final decan = birthDate != null
        ? HoroscopeService.getDecanForDate(birthDate)
        : null;
    final fullAstro = HoroscopeService.dailyHoroscope(
      sign,
      DateTime.now(),
      decan: decan,
    );
    final firstTwo = fullAstro.split(RegExp(r'\n\n')).first;
    _astroShort = firstTwo.length > 180 ? '${firstTwo.substring(0, 177)}...' : firstTwo;

    if (mounted) {
      setState(() {
        _userName = name;
        _intention = intention ?? '';
        _morningEmotion = morningEmotion;
        _eveningEmotion = eveningEmotion;
        _loading = false;
      });
    }
  }

  Future<void> _saveMorningRoutine() async {
    final intention = _intentionController.text.trim();
    if (intention.isNotEmpty) {
      await StorageService.setRoutineIntention(intention);
    }
    await StorageService.setRoutineMorningDone(
      _today,
      emotion: _morningEmotion,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rituel du matin enregistré. Belle journée !'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveEveningRoutine() async {
    await StorageService.setRoutineEveningDone(
      _today,
      emotion: _eveningEmotion,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rituel du soir enregistré. Bonne soirée !'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: const GradientAppBar(
          title: '🌅 MoodRoutine',
          gradient: AppColors.gradientSunrise,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: GradientAppBar(
        title: '🌅 MoodRoutine',
        gradient: AppColors.gradientSunrise,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
          tabs: const [
            Tab(text: 'Matin'),
            Tab(text: 'Soir'),
          ],
        ),
      ),
      body: Container(
        color: AppColors.background,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMorningTab(),
            _buildEveningTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMorningTab() {
    return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FeelGoodCard(
                gradient: AppColors.gradientSunrise,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour${_userName != null && _userName!.isNotEmpty ? ' ${_userName}' : ''} !',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textOnPrimary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _astroShort,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.textOnPrimary.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FeelGoodCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intention du jour',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _intentionController,
                      decoration: const InputDecoration(
                        hintText: 'Ex. Aujourd\'hui je choisis la bienveillance',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                      onChanged: (v) => setState(() => _intention = v),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        'Bienveillance',
                        'Gratitude',
                        'Patience',
                        'Courage',
                      ].map((s) {
                        final article = s == 'Courage' ? 'le' : 'la';
                        return ActionChip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          onPressed: () {
                            _intentionController.text =
                                'Aujourd\'hui je choisis $article ${s.toLowerCase()}.';
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FeelGoodCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comment te sens-tu ce matin ?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _microMoodEmotions.map((e) {
                        final selected = _morningEmotion == e;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _morningEmotion = _morningEmotion == e ? null : e),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.emotionColor(e).withValues(alpha: 0.2)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppColors.emotionColor(e)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _emotionEmoji[e]!,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  Emotions.label(e),
                                  style: TextStyle(
                                    fontWeight:
                                        selected ? FontWeight.w700 : FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                icon: const Icon(Icons.notifications_active_rounded, size: 20),
                label: const Text('Rappels : activer dans Paramètres'),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _saveMorningRoutine(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Valider mon rituel matin'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildEveningTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeelGoodCard(
            gradient: AppColors.gradientSecondary,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comment était ta journée ?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Un petit mot pour clôturer la journée.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FeelGoodCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ton mood du soir',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _microMoodEmotions.map((e) {
                    final selected = _eveningEmotion == e;
                    return GestureDetector(
                      onTap: () => setState(
                          () => _eveningEmotion = _eveningEmotion == e ? null : e),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.emotionColor(e).withValues(alpha: 0.2)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.emotionColor(e)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _emotionEmoji[e]!,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              Emotions.label(e),
                              style: TextStyle(
                                fontWeight:
                                    selected ? FontWeight.w700 : FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _saveEveningRoutine(),
            icon: const Icon(Icons.nightlight_rounded),
            label: const Text('Valider mon rituel soir'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MoodCastScreen()),
              );
            },
            icon: const Icon(Icons.mic_rounded),
            label: const Text('Faire un MoodCast complet'),
          ),
        ],
      ),
    );
  }
}
