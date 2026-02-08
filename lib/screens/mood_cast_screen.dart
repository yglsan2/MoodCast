import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/analysis_result.dart';
import '../models/emotions.dart';
import '../models/mood_cast.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/podcast_enricher_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';

/// Durée minimale d'enregistrement pour avoir "assez de matière" (secondes).
const int _minRecordingSeconds = 10;

class MoodCastScreen extends StatefulWidget {
  const MoodCastScreen({super.key});

  @override
  State<MoodCastScreen> createState() => _MoodCastScreenState();
}

class _MoodCastScreenState extends State<MoodCastScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();

  bool _isRecording = false;
  bool _isProcessing = false;
  int _recordingSeconds = 0;
  Timer? _timer;

  String _selectedStyle = 'motivation';
  static const List<String> _styles = ['motivation', 'humour', 'zen', 'poesie', 'energie'];

  MoodAnalysisResult? _moodResult;
  PodcastResult? _podcastResult;
  String? _recordPath;

  /// Après analyse : humeur détectée (affichée pour confirmation).
  MoodAnalysisResult? _detectedAnalysis;
  /// Humeur choisie par l'utilisateur (ou détectée) pour générer le podcast.
  String? _chosenEmotion;
  /// Génération du podcast en cours après confirmation.
  bool _isGeneratingPodcast = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('fr-FR');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    _clearError();
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      _showError('L\'accès au microphone est nécessaire pour enregistrer votre humeur.');
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, 'moodcast_${DateTime.now().millisecondsSinceEpoch}.m4a');
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() {
        _isRecording = true;
        _recordPath = path;
        _recordingSeconds = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingSeconds++);
      });
    } catch (e) {
      if (mounted) {
        _showError('L\'enregistrement n\'est pas disponible sur cet appareil. Réessayez ou utilisez un autre support.');
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _timer = null;
    if (_recordingSeconds < _minRecordingSeconds) {
      setState(() {
        _isRecording = false;
        _errorMessage = 'Pas assez de matière pour analyser votre humeur. Parlez au moins $_minRecordingSeconds secondes, puis réessayez.';
      });
      try {
        await _recorder.stop();
      } catch (_) {}
      return;
    }
    try {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _recordPath = path;
        _isProcessing = true;
        _errorMessage = null;
      });
      await _processRecording(path ?? _recordPath);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'L\'enregistrement a échoué. Réessayez dans un endroit calme.';
        });
      }
    }
  }

  void _clearError() => setState(() => _errorMessage = null);
  void _showError(String msg) => setState(() => _errorMessage = msg);

  Future<void> _processRecording(String? audioPath) async {
    if (audioPath == null || audioPath.isEmpty) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Aucun enregistrement reçu. Réessayez.';
        });
      }
      return;
    }

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      if (await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.getCurrentPosition();
      }
    } catch (_) {}

    final analysis = await ApiService.analyzeMood(audioUri: audioPath);

    if (analysis == null || !mounted) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Nous n\'avons pas pu analyser votre enregistrement. Parlez 10 à 20 secondes dans un endroit calme, puis réessayez.';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _detectedAnalysis = analysis;
        _chosenEmotion = analysis.emotion;
        _isProcessing = false;
        _errorMessage = null;
      });
    }
  }

  Future<void> _confirmMoodAndGenerate() async {
    final analysis = _detectedAnalysis;
    final chosen = _chosenEmotion;
    final audioPath = _recordPath;
    if (analysis == null || chosen == null || chosen.isEmpty || audioPath == null) return;

    setState(() => _isGeneratingPodcast = true);

    MoodLocation? location;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) await Geolocator.requestPermission();
      if (await Geolocator.isLocationServiceEnabled()) {
        final pos = await Geolocator.getCurrentPosition();
        location = MoodLocation(latitude: pos.latitude, longitude: pos.longitude);
      }
    } catch (_) {}

    final podcast = await ApiService.generatePodcast(
      emotion: chosen,
      intensity: analysis.intensity,
      energy: analysis.energy,
      style: _selectedStyle,
    );

    final enrichedText = await PodcastEnricherService.enrich(podcast.text);

    final moodCast = MoodCast(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      emotion: chosen,
      intensity: analysis.intensity,
      energy: analysis.energy,
      podcastText: enrichedText,
      style: podcast.style,
      audioPath: audioPath,
      location: location,
    );

    await StorageService.saveMoodCast(moodCast);
    await ApiService.uploadMoodData(
      emotion: chosen,
      intensity: analysis.intensity,
      energy: analysis.energy,
      location: location,
    );

    if (mounted) {
      setState(() {
        _moodResult = MoodAnalysisResult(emotion: chosen, intensity: analysis.intensity, energy: analysis.energy);
        _podcastResult = PodcastResult(text: enrichedText, style: podcast.style);
        _detectedAnalysis = null;
        _chosenEmotion = null;
        _isGeneratingPodcast = false;
      });
    }
  }

  Future<void> _playPodcast() async {
    if (_podcastResult == null) return;
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool('settings_sound_enabled') ?? true;
    if (!soundEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activez le son des podcasts dans Paramètres (Plus → Paramètres).'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    await _tts.speak(_podcastResult!.text);
  }

  Future<void> _stopPlayback() async {
    await _tts.stop();
  }

  void _reset() {
    setState(() {
      _moodResult = null;
      _podcastResult = null;
      _recordPath = null;
      _detectedAnalysis = null;
      _chosenEmotion = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: '🌗 MoodCast',
        gradient: AppColors.gradientPrimary,
      ),
      body: Container(
        color: AppColors.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) _buildErrorCard(),
            if (!_hasResult && !_isProcessing && _detectedAnalysis == null) _buildEmptyOrRecordState(),
            if (_isProcessing) _buildProcessingState(),
            if (_detectedAnalysis != null && !_hasResult) _buildRefineCard(),
            if (_isGeneratingPodcast) _buildProcessingState(),
            if (_hasResult) _buildResultCard(),
          ],
          ),
        ),
      ),
    );
  }

  bool get _hasResult => _moodResult != null && _podcastResult != null;

  Widget _buildErrorCard() {
    return Semantics(
      label: 'Message d\'erreur',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
          boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.error, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: AppColors.error, fontSize: 14, height: 1.35),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _clearError,
                tooltip: 'Fermer le message',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// État initial : on s'excuse de ne pas pouvoir donner d'avis tant qu'il n'y a pas d'enregistrement.
  Widget _buildEmptyOrRecordState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FeelGoodCard(
          gradient: AppColors.gradientSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.record_voice_over_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Pas encore d\'avis personnalisé',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Nous n\'avons pas encore assez de matière pour vous donner un avis. Enregistrez 10 à 20 secondes de voix pour recevoir un avis personnalisé basé sur votre humeur.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.45),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildStyleSelector(),
        const SizedBox(height: 28),
        _buildRecordButton(),
      ],
    );
  }

  Widget _buildStyleSelector() {
    return FeelGoodCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Style du podcast',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _styles.map((s) {
              final selected = _selectedStyle == s;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedStyle = s),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.gradientPrimary : null,
                      color: selected ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    final minReached = _recordingSeconds >= _minRecordingSeconds;
    return Column(
      children: [
        Semantics(
          label: _isRecording ? 'Arrêter l\'enregistrement' : 'Démarrer l\'enregistrement',
          button: true,
          child: GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: _isRecording ? _RecordingButtonWithPulse(recordingSeconds: _recordingSeconds) : _StaticRecordButton(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isRecording
              ? '$_recordingSeconds s — ${minReached ? "Vous pouvez arrêter" : "Parlez encore ${_minRecordingSeconds - _recordingSeconds} s"}'
              : 'Appuyez pour enregistrer (min. $_minRecordingSeconds s)',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProcessingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            _isGeneratingPodcast ? 'Génération de votre podcast…' : 'Analyse de votre humeur en cours…',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Carte pour confirmer ou modifier l'humeur détectée avant de générer le podcast.
  Widget _buildRefineCard() {
    return FeelGoodCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nous avons détecté cette humeur',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confirmez ou modifiez ci-dessous pour un texte parfaitement adapté.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Emotions.all.map((e) {
              final selected = _chosenEmotion == e;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _chosenEmotion = e),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.emotionColor(e).withValues(alpha: 0.2) : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.emotionColor(e) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      Emotions.label(e),
                      style: TextStyle(
                        color: selected ? AppColors.emotionColor(e) : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_chosenEmotion != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.emotionColor(_chosenEmotion).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.emotionColor(_chosenEmotion!).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.emotionColor(_chosenEmotion), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Mood sélectionné : ',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  Text(
                    Emotions.label(_chosenEmotion!),
                    style: TextStyle(
                      color: AppColors.emotionColor(_chosenEmotion),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isGeneratingPodcast ? null : _confirmMoodAndGenerate,
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text('Générer mon podcast'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final emotion = _moodResult!.emotion;
    final color = AppColors.emotionColor(emotion);
    return FeelGoodCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  Emotions.label(emotion),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _reset,
                child: const Text('Nouveau'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Intensité ${_moodResult!.intensity}  ·  Énergie ${_moodResult!.energy}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Text(
            _podcastResult!.text,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _playPodcast,
                icon: const Icon(Icons.volume_up_rounded, size: 20),
                label: const Text('Écouter'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _stopPlayback,
                icon: const Icon(Icons.stop_rounded, size: 20),
                label: const Text('Arrêter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StaticRecordButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.gradientSunrise,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 48),
    );
  }
}

class _RecordingButtonWithPulse extends StatefulWidget {
  const _RecordingButtonWithPulse({required this.recordingSeconds});

  final int recordingSeconds;

  @override
  State<_RecordingButtonWithPulse> createState() => _RecordingButtonWithPulseState();
}

class _RecordingButtonWithPulseState extends State<_RecordingButtonWithPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.coral,
              boxShadow: [
                BoxShadow(
                  color: AppColors.coral.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.stop_rounded, color: Colors.white, size: 48),
          ),
        );
      },
    );
  }
}
