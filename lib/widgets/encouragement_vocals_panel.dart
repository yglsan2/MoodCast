import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';

import '../models/encouragement_vocal.dart';
import '../services/encouragement_vocal_storage.dart';
import '../theme/app_colors.dart';

const int _encouragementMinSeconds = 3;
const int _encouragementShortMaxSeconds = 90;
const int _encouragementLongMaxSeconds = 300;

/// Enregistrement, lecture et partage des vocaux d'encouragement (MoodSOS).
class EncouragementVocalsPanel extends StatefulWidget {
  const EncouragementVocalsPanel({super.key});

  @override
  State<EncouragementVocalsPanel> createState() => _EncouragementVocalsPanelState();
}

class _EncouragementVocalsPanelState extends State<EncouragementVocalsPanel> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  List<EncouragementVocal> _items = [];
  bool _loadingList = true;

  EncouragementTarget _target = EncouragementTarget.self;
  EncouragementLengthMode _lengthMode = EncouragementLengthMode.short;

  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  StreamSubscription<void>? _playerCompleteSub;

  String? _playingId;
  String? _errorMessage;

  int get _maxSeconds =>
      _lengthMode == EncouragementLengthMode.short ? _encouragementShortMaxSeconds : _encouragementLongMaxSeconds;

  @override
  void initState() {
    super.initState();
    _playerCompleteSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
    _refreshList();
  }

  Future<void> _refreshList() async {
    final list = await EncouragementVocalStorage.loadAll();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loadingList = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_playerCompleteSub?.cancel());
    unawaited(_player.dispose());
    unawaited(_recorder.dispose());
    super.dispose();
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds s';
    final m = seconds ~/ 60;
    final r = seconds % 60;
    if (r == 0) return '$m min';
    return '$m min $r s';
  }

  String _targetLabel(EncouragementTarget t) =>
      t == EncouragementTarget.self ? 'Pour moi' : 'Pour un proche';

  Future<void> _startRecording() async {
    setState(() => _errorMessage = null);
    final ok = await _recorder.hasPermission();
    if (!ok) {
      setState(() => _errorMessage = 'Autorise le micro pour enregistrer un message vocal.');
      return;
    }

    try {
      final dir = await EncouragementVocalStorage.vocalDirectory();
      final id = EncouragementVocalStorage.newRecordingId();
      final wavOk = await _recorder.isEncoderSupported(AudioEncoder.wav);
      final ext = wavOk ? 'wav' : 'm4a';
      final path = p.join(dir.path, '$id.$ext');
      final RecordConfig cfg = wavOk
          ? const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1)
          : const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000, numChannels: 1);

      await _recorder.start(cfg, path: path);
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= _maxSeconds) {
          unawaited(_stopRecording(autoMax: true));
        }
      });
    } catch (_) {
      setState(() => _errorMessage = 'Impossible de démarrer l\'enregistrement. Réessaie.');
    }
  }

  Future<void> _stopRecording({bool autoMax = false}) async {
    if (!_isRecording) return;
    _timer?.cancel();
    _timer = null;

    final seconds = _recordingSeconds;
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = null;
    }

    setState(() => _isRecording = false);

    if (seconds < _encouragementMinSeconds) {
      if (path != null) {
        try {
          final f = File(path);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _errorMessage =
              'Message un peu court. Enregistre au moins $_encouragementMinSeconds secondes, ou annule en ne sauvegardant pas.';
        });
      }
      return;
    }

    if (path == null || path.isEmpty) {
      setState(() => _errorMessage = 'Aucun fichier enregistré. Réessaie.');
      return;
    }

    final fileName = p.basename(path);
    await EncouragementVocalStorage.appendMetadata(
      fileName: fileName,
      target: _target,
      lengthMode: _lengthMode,
      durationSeconds: seconds,
    );
    await _refreshList();

    if (mounted && autoMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durée max (${_formatDuration(_maxSeconds)}) atteinte — message enregistré.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    _timer?.cancel();
    _timer = null;
    try {
      final path = await _recorder.stop();
      if (path != null) {
        final f = File(path);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
    }
  }

  Future<void> _togglePlay(EncouragementVocal v) async {
    setState(() => _errorMessage = null);
    final full = await EncouragementVocalStorage.fullPath(v);
    final f = File(full);
    if (!await f.exists()) {
      setState(() => _errorMessage = 'Fichier introuvable. Supprime cette entrée et réenregistre.');
      return;
    }

    if (_playingId == v.id) {
      await _player.stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }

    await _player.stop();
    try {
      await _player.play(DeviceFileSource(full));
      if (mounted) setState(() => _playingId = v.id);
    } catch (_) {
      if (mounted) {
        setState(() => _playingId = null);
        _errorMessage = 'Lecture impossible pour ce fichier.';
      }
    }
  }

  Future<void> _share(EncouragementVocal v) async {
    final full = await EncouragementVocalStorage.fullPath(v);
    final f = File(full);
    if (!await f.exists()) return;
    final text = v.target == EncouragementTarget.proche
        ? 'Un message vocal pour toi — avec toute ma tendresse.'
        : 'Un message pour toi (MoodCast / MoodSOS).';
    await Share.shareXFiles([XFile(full)], text: text);
  }

  Future<void> _confirmDelete(EncouragementVocal v) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce message ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (go != true) return;
    if (_playingId == v.id) {
      await _player.stop();
      _playingId = null;
    }
    await EncouragementVocalStorage.delete(v);
    await _refreshList();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy à HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tes vocaux d\'encouragement',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enregistre un message pour toi (tu pourras le réécouter quand tu en as besoin) '
          'ou pour un proche (tu peux le partager par message). Court jusqu’à 1 min 30, long jusqu’à 5 min.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 16),
        Text('Destinataire', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SegmentedButton<EncouragementTarget>(
          segments: const [
            ButtonSegment(value: EncouragementTarget.self, label: Text('Pour moi'), icon: Icon(Icons.person_rounded, size: 18)),
            ButtonSegment(
              value: EncouragementTarget.proche,
              label: Text('Un proche'),
              icon: Icon(Icons.favorite_rounded, size: 18),
            ),
          ],
          selected: {_target},
          onSelectionChanged: _isRecording
              ? null
              : (s) {
                  setState(() => _target = s.first);
                },
        ),
        const SizedBox(height: 14),
        Text('Durée max', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SegmentedButton<EncouragementLengthMode>(
          segments: const [
            ButtonSegment(value: EncouragementLengthMode.short, label: Text('Court'), icon: Icon(Icons.timer_rounded, size: 18)),
            ButtonSegment(value: EncouragementLengthMode.long, label: Text('Long'), icon: Icon(Icons.hourglass_top_rounded, size: 18)),
          ],
          selected: {_lengthMode},
          onSelectionChanged: _isRecording
              ? null
              : (s) {
                  setState(() => _lengthMode = s.first);
                },
        ),
        const SizedBox(height: 16),
        if (_isRecording)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.coral.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.fiber_manual_record_rounded, color: AppColors.coral, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Enregistrement… ${_formatDuration(_recordingSeconds)} / ${_formatDuration(_maxSeconds)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _target == EncouragementTarget.self
                      ? 'Parle-toi avec la même douceur qu’à un ami.'
                      : 'Imagine la personne : ton message lui fera du bien.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _stopRecording(),
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Terminer et sauver'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _cancelRecording,
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          FilledButton.icon(
            onPressed: _startRecording,
            icon: const Icon(Icons.mic_rounded, size: 22),
            label: const Text('Enregistrer un vocal'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.accentDeep,
              foregroundColor: Colors.white,
            ),
          ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(_errorMessage!, style: TextStyle(fontSize: 13, color: AppColors.coral, height: 1.35)),
        ],
        const SizedBox(height: 22),
        Text(
          'Messages enregistrés',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 10),
        if (_loadingList)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_items.isEmpty)
          Text(
            'Aucun vocal pour l’instant. Le premier t’attend — un petit mot suffit souvent.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final v = _items[i];
              final playing = _playingId == v.id;
              return Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _togglePlay(v),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_targetLabel(v.target)} · ${_formatDuration(v.durationSeconds)}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateFmt.format(v.createdAt),
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Partager',
                          onPressed: () => _share(v),
                          icon: const Icon(Icons.share_rounded),
                          color: AppColors.secondary,
                        ),
                        IconButton(
                          tooltip: 'Supprimer',
                          onPressed: () => _confirmDelete(v),
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
