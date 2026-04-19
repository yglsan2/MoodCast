import 'dart:math' as math;

import 'package:record/record.dart';

import '../models/analysis_result.dart';
import '../models/emotions.dart';
import 'ser_emotion_tflite.dart';

/// Analyse **locale** avancée à partir du **signal d’amplitude** (dBFS) pendant l’enregistrement.
/// Sans transcription : on infère l’activation, la monotonie, la dérive temporelle et la « parole » vs silence.
/// Des **garde-fous** évitent les contre-sens grossiers (ex. joie sur voix très faible et plate).
class VoiceMoodAnalyzer {
  VoiceMoodAnalyzer._();

  /// Fusionne une analyse externe éventuelle avec l’inférence locale (garde-fous appliqués en tout cas).
  static MoodAnalysisResult mergeWithApi(
    MoodAnalysisResult? api,
    List<Amplitude> samples,
    int durationSeconds,
  ) {
    final profile = VoiceSignalProfile.fromSamples(samples, durationSeconds);
    final local = _resultFromProfile(profile);

    if (api == null) {
      return local;
    }
    if (samples.length < 6) {
      return api;
    }

    final scores = _baseScores(profile, durationSeconds);
    _applyConsistencyGates(profile, scores);
    scores[api.emotion] = (scores[api.emotion] ?? 0) + 1.6;

    var bestE = local.emotion;
    var bestS = -1.0;
    scores.forEach((e, s) {
      if (s > bestS) {
        bestS = s;
        bestE = e;
      }
    });

    const wApi = 0.35;
    const wLoc = 0.65;
    final intensity = ((api.intensity * wApi) + (local.intensity * wLoc)).round().clamp(1, 10);
    final energy = ((api.energy * wApi) + (local.energy * wLoc)).round().clamp(1, 10);

    return MoodAnalysisResult(
      emotion: Emotions.normalize(bestE),
      intensity: intensity,
      energy: energy,
    );
  }

  /// **Amplitude + TFLite** (MFCC → SER 4 classes) fusionnés avec garde-fous.
  static Future<MoodAnalysisResult> analyzeHybrid({
    required String? wavPath,
    required List<Amplitude> samples,
    required int durationSeconds,
  }) async {
    final ampOnly = mergeWithApi(null, samples, durationSeconds);
    if (wavPath == null || !wavPath.toLowerCase().endsWith('.wav')) {
      return ampOnly;
    }
    try {
      final ser = await SerEmotionTflite.instance.classify(wavPath);
      if (ser == null) return ampOnly;
      return _fuseSerWithAmplitude(ser, ampOnly, samples, durationSeconds);
    } catch (_) {
      return ampOnly;
    }
  }

  static MoodAnalysisResult _fuseSerWithAmplitude(
    SerEmotionOutput ser,
    MoodAnalysisResult amp,
    List<Amplitude> samples,
    int durationSec,
  ) {
    final p = VoiceSignalProfile.fromSamples(samples, durationSec);
    final conf = ser.confidence;
    if (conf < 0.38) return amp;

    String serFrench() {
      switch (ser.classIndex) {
        case 0:
          return 'calme';
        case 1:
          return 'joie';
        case 2:
          return 'enthousiasme';
        case 3:
          if (p.isFlatQuietVoice) return 'tristesse';
          if (p.volatility01 > 0.52 && p.jitter01 > 0.45) return 'stress';
          return 'anxiété';
        default:
          return amp.emotion;
      }
    }

    if (ser.classIndex == 1 && p.isFlatQuietVoice) {
      return amp;
    }
    if (ser.classIndex == 3 &&
        (amp.emotion == 'joie' || amp.emotion == 'heureux' || amp.emotion == 'enthousiasme') &&
        conf < 0.62) {
      return amp;
    }

    final e = Emotions.normalize(serFrench());
    final intens = (amp.intensity * (1 - conf * 0.45) + 6 * conf * 0.45).round().clamp(1, 10);
    return MoodAnalysisResult(emotion: e, intensity: intens, energy: amp.energy);
  }

  static MoodAnalysisResult _resultFromProfile(VoiceSignalProfile p) {
    final scores = _baseScores(p, p.durationSec);
    _applyConsistencyGates(p, scores);

    var bestE = 'motivation';
    var bestS = -1.0;
    scores.forEach((e, s) {
      if (s > bestS) {
        bestS = s;
        bestE = e;
      }
    });

    return MoodAnalysisResult(
      emotion: Emotions.normalize(bestE),
      intensity: _intensityFromProfile(p),
      energy: _energyFromProfile(p),
    );
  }

  /// Scores de base (0–1+) pour chaque émotion connue.
  static Map<String, double> _baseScores(VoiceSignalProfile p, int durationSec) {
    final loud = p.loudness01;
    final quiet = 1.0 - loud;
    final volN = p.volatility01;
    final rangeN = p.range01;
    final jitN = p.jitter01;
    final mono = p.monotony01;
    final sil = p.silenceRatio;
    final slope = p.energySlopeDb; // négatif = voix qui s’éteint
    final express = p.expressiveness01;

    double S(
      double activation,
      double calm,
      double tension,
      double warmth,
    ) {
      return activation * 0.28 + calm * 0.22 + tension * 0.22 + warmth * 0.18;
    }

    final scores = <String, double>{};

    for (final e in Emotions.all) {
      double s;
      switch (e) {
        case 'joie':
        case 'heureux':
          s = loud * 0.42 + express * 0.38 + math.max(0.0, volN - 0.25) * 0.2;
          if (slope < -0.8) s *= 0.55;
          break;
        case 'enthousiasme':
          s = loud * 0.4 + express * 0.35 + jitN * 0.22;
          break;
        case 'optimisme':
        case 'légèreté':
          s = loud * 0.35 + express * 0.3 + (1 - mono) * 0.25;
          break;
        case 'motivation':
          s = loud * 0.38 + (1 - (volN - 0.42).abs()) * 0.28 + rangeN * 0.18;
          if (mono > 0.72 && loud < 0.45) s *= 0.4;
          break;
        case 'confiance':
        case 'fierté':
          s = loud * 0.4 + (1 - jitN) * 0.25 + rangeN * 0.22;
          break;
        case 'curiosité':
        case 'créativité':
        case 'inspiration':
          s = loud * 0.34 + volN * 0.32 + rangeN * 0.2;
          break;
        case 'sérénité':
        case 'calme':
          s = quiet * 0.38 + (1 - volN) * 0.32 + (1 - jitN) * 0.18;
          if (durationSec > 14) s += 0.08;
          break;
        case 'détente':
        case 'bienveillance':
        case 'tendresse':
          s = quiet * 0.4 + (1 - volN) * 0.28 + (1 - sil) * 0.15;
          break;
        case 'gratitude':
        case 'amour':
          s = quiet * 0.36 + rangeN * 0.22 + (1 - mono) * 0.22;
          break;
        case 'nostalgie':
          s = quiet * 0.42 + volN * 0.18 + (slope < 0 ? 0.12 : 0.04);
          break;
        case 'stress':
          s = loud * 0.28 + volN * 0.38 + jitN * 0.28;
          break;
        case 'anxiété':
        case 'inquiétude':
          s = quiet * 0.32 + volN * 0.36 + jitN * 0.28;
          break;
        case 'irritation':
        case 'colere':
          s = loud * 0.35 + volN * 0.4 + jitN * 0.22;
          break;
        case 'fatigue':
          s = quiet * 0.45 + (1 - volN) * 0.22 + (slope < -0.5 ? 0.22 : 0.08) + sil * 0.12;
          break;
        case 'tristesse':
        case 'mélancolie':
          s = quiet * 0.48 + mono * 0.28 + (1 - rangeN) * 0.15 + (slope < -0.4 ? 0.18 : 0.06);
          break;
        case 'doute':
          s = 0.18 + (1 - (volN - 0.45).abs()) * 0.28 + quiet * 0.22;
          break;
        case 'espoir':
          s = loud * 0.3 + (1 - mono) * 0.25 + math.max(0.0, slope) * 0.15;
          break;
        default:
          s = S(loud, 1 - volN, jitN, rangeN) * 0.85;
      }
      scores[e] = s;
    }

    if (durationSec < 9) {
      scores.updateAll((_, v) => v * 0.92);
      scores['doute'] = (scores['doute'] ?? 0) + 0.12;
    }

    return scores;
  }

  /// Réduit les scores incohérents avec le profil global (évite joie sur voix « à plat »).
  static void _applyConsistencyGates(VoiceSignalProfile p, Map<String, double> scores) {
    void mulAll(Iterable<String> keys, double factor) {
      for (final k in keys) {
        scores[k] = (scores[k] ?? 0) * factor;
      }
    }

    void addAll(Iterable<String> keys, double bonus) {
      for (final k in keys) {
        scores[k] = (scores[k] ?? 0) + bonus;
      }
    }

    const highPositive = {
      'joie', 'heureux', 'enthousiasme', 'optimisme', 'légèreté',
    };
    const energeticUp = {
      'motivation', 'fierté', 'curiosité', 'créativité', 'inspiration', 'confiance',
    };
    const lowMood = {
      'tristesse', 'mélancolie', 'fatigue', 'anxiété', 'inquiétude', 'nostalgie',
    };
    const tense = {'stress', 'irritation', 'colere', 'anxiété', 'inquiétude'};

    // Profil « voix basse, peu de dynamique » : très incompatible avec joie / enthousiasme.
    if (p.isFlatQuietVoice) {
      mulAll(highPositive, 0.08);
      mulAll(energeticUp, p.loudness01 < 0.28 ? 0.22 : 0.38);
      addAll(lowMood, 0.55);
      scores['calme'] = (scores['calme'] ?? 0) + 0.15;
      scores['sérénité'] = (scores['sérénité'] ?? 0) + 0.12;
    }

    // Profil « voix qui s’effondre » : renforce tristesse / fatigue, pas l’enthousiasme.
    if (p.energySlopeDb < -1.2 && p.loudness01 < 0.55) {
      mulAll(highPositive, 0.35);
      mulAll({'enthousiasme', 'joie', 'heureux'}, 0.15);
      addAll({'tristesse', 'mélancolie', 'fatigue'}, 0.45);
    }

    // Beaucoup de silence + faible volume : retrait, fatigue, doute — pas fête.
    if (p.silenceRatio > 0.38 && p.loudness01 < 0.42) {
      mulAll(highPositive, 0.12);
      mulAll(energeticUp, 0.45);
      scores['fatigue'] = (scores['fatigue'] ?? 0) + 0.4;
      scores['tristesse'] = (scores['tristesse'] ?? 0) + 0.25;
    }

    // Signal vif, large, pas monotone : les états « à plat » peuplent moins.
    if (p.isExpressiveBrightVoice) {
      mulAll(lowMood, 0.35);
      mulAll({'tristesse', 'mélancolie'}, 0.18);
      scores['fatigue'] = (scores['fatigue'] ?? 0) * 0.4;
      addAll(highPositive, 0.25);
    }

    // Aiguë / instable sans être « joyeuse » : stress / irritation.
    if (p.loudness01 > 0.52 && p.jitter01 > 0.62 && p.volatility01 > 0.55) {
      addAll(tense, 0.35);
      scores['enthousiasme'] = (scores['enthousiasme'] ?? 0) * 0.55;
    }

    // Monotonie extrême + pas fort : priorité tristesse / mélancolie sur « motivation ».
    if (p.monotony01 > 0.78 && p.loudness01 < 0.48) {
      scores['motivation'] = (scores['motivation'] ?? 0) * 0.25;
      scores['tristesse'] = (scores['tristesse'] ?? 0) + 0.35;
      scores['mélancolie'] = (scores['mélancolie'] ?? 0) + 0.3;
    }
  }

  static int _intensityFromProfile(VoiceSignalProfile p) {
    final raw = 3.6 + p.volatility01 * 4.2 + p.range01 * 3.8 + p.jitter01 * 2.2;
    return raw.round().clamp(1, 10);
  }

  static int _energyFromProfile(VoiceSignalProfile p) {
    final loud = p.loudness01;
    final peak = ((-p.peakDb).clamp(12.0, 58.0) - 12) / 46;
    final slopeBoost = (p.energySlopeDb / 6).clamp(-0.35, 0.35);
    final dur = (p.durationSec / 24).clamp(0.0, 1.0);
    var v = 2.8 + loud * 4.5 + peak * 2.0 + dur * 1.4 + slopeBoost * 2.5;
    if (p.isFlatQuietVoice) v -= 1.4;
    if (p.energySlopeDb < -1.5) v -= 1.1;
    return v.round().clamp(1, 10);
  }
}

/// Métriques dérivées des échantillons [Amplitude] (courant + max par fenêtre).
class VoiceSignalProfile {
  VoiceSignalProfile._({
    required this.durationSec,
    required this.meanDb,
    required this.peakDb,
    required this.volatility,
    required this.rangeDb,
    required this.jitterDb,
    required this.silenceRatio,
    required this.energySlopeDb,
    required this.earlyMeanDb,
    required this.midMeanDb,
    required this.lateMeanDb,
    required this.sampleCount,
  });

  factory VoiceSignalProfile.fromSamples(List<Amplitude> samples, int durationSec) {
    if (samples.isEmpty) {
      return VoiceSignalProfile._(
        durationSec: durationSec,
        meanDb: -42,
        peakDb: -22,
        volatility: 2.0,
        rangeDb: 8,
        jitterDb: 1.2,
        silenceRatio: 0.2,
        energySlopeDb: 0,
        earlyMeanDb: -40,
        midMeanDb: -40,
        lateMeanDb: -40,
        sampleCount: 0,
      );
    }

    final currents = samples.map((a) => a.current).toList();
    final maxes = samples.map((a) => a.max).toList();

    final mean = currents.reduce((a, b) => a + b) / currents.length;
    final varSum = currents.map((c) => (c - mean) * (c - mean)).reduce((a, b) => a + b);
    final vol = math.sqrt(varSum / currents.length);

    final minC = currents.reduce((a, b) => a < b ? a : b);
    final maxC = currents.reduce((a, b) => a > b ? a : b);
    final range = (maxC - minC).clamp(0.5, 100.0);
    final peak = maxes.reduce((a, b) => a > b ? a : b);

    var jitterSum = 0.0;
    for (var i = 1; i < currents.length; i++) {
      jitterSum += (currents[i] - currents[i - 1]).abs();
    }
    final jitter = currents.length > 1 ? jitterSum / (currents.length - 1) : 0.0;

    const silenceDb = -38.0;
    var silent = 0;
    for (final c in currents) {
      if (c < silenceDb) silent++;
    }
    final silenceR = silent / currents.length;

    final n = currents.length;
    final t1 = (n / 3).ceil().clamp(1, n);
    final t2 = ((2 * n) / 3).floor().clamp(1, n);
    double segMean(int a, int b) {
      if (b <= a) return currents[a.clamp(0, n - 1)];
      var s = 0.0;
      for (var i = a; i < b && i < n; i++) {
        s += currents[i];
      }
      return s / (b - a);
    }

    final earlyM = segMean(0, t1);
    final midM = segMean(t1, t2);
    final lateM = segMean(t2, n);
    final slope = lateM - earlyM;

    return VoiceSignalProfile._(
      durationSec: durationSec,
      meanDb: mean,
      peakDb: peak,
      volatility: vol,
      rangeDb: range,
      jitterDb: jitter,
      silenceRatio: silenceR,
      energySlopeDb: slope,
      earlyMeanDb: earlyM,
      midMeanDb: midM,
      lateMeanDb: lateM,
      sampleCount: n,
    );
  }

  final int durationSec;
  final double meanDb;
  final double peakDb;
  final double volatility;
  final double rangeDb;
  final double jitterDb;
  final double silenceRatio;
  final double energySlopeDb;
  final double earlyMeanDb;
  final double midMeanDb;
  final double lateMeanDb;
  final int sampleCount;

  /// 0 = très faible, 1 = fort (proxy d’activation vocale).
  double get loudness01 => ((-meanDb) / 52).clamp(0.0, 1.0);

  double get volatility01 => (volatility / 9.5).clamp(0.0, 1.0);

  double get range01 => (rangeDb / 26).clamp(0.0, 1.0);

  double get jitter01 => (jitterDb / 7.0).clamp(0.0, 1.0);

  /// 1 = voix très « plate » (peu de variation).
  double get monotony01 {
    final v = 1.0 - volatility01;
    final r = 1.0 - range01;
    return ((v * 0.55 + r * 0.45)).clamp(0.0, 1.0);
  }

  /// Mélange dynamique + plage utile (joie / enthousiasme ont besoin d’expressivité).
  double get expressiveness01 {
    final m = 1.0 - monotony01;
    return ((m * 0.5 + loudness01 * 0.35 + range01 * 0.15)).clamp(0.0, 1.0);
  }

  bool get isFlatQuietVoice =>
      loudness01 < 0.42 &&
      monotony01 > 0.58 &&
      range01 < 0.52 &&
      volatility01 < 0.48;

  bool get isExpressiveBrightVoice =>
      loudness01 > 0.52 &&
      expressiveness01 > 0.55 &&
      range01 > 0.45 &&
      !isFlatQuietVoice;
}
