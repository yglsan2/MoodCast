import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'mfcc_ser.dart';
import 'wav_pcm16_mono.dart';

/// Inférence locale **TensorFlow Lite**.
///
/// Fichier `ser_quant.tflite` : dépôt [Speech-Emotion-Recognition-TinyML](https://github.com/Hannibal0420/Speech-Emotion-Recognition-TinyML)
/// (licence MIT, modèle quantifié ~150 Ko, entrées MFCC alignées notebook : 47×13).
/// Classes d’origine : neutral, happy, surprise, unpleasant (RAVDESS / TESS / SAVEE — dépôt Hannibal0420).
class SerEmotionTflite {
  SerEmotionTflite._();

  static final SerEmotionTflite instance = SerEmotionTflite._();

  Interpreter? _interpreter;
  bool _loadFailed = false;

  /// Probabilités softmax (4) et indice gagnant.
  Future<SerEmotionOutput?> classify(String wavPath) async {
    if (_loadFailed) return null;
    try {
      _interpreter ??= await Interpreter.fromAsset('assets/models/ser_quant.tflite');
    } catch (e, st) {
      _loadFailed = true;
      debugPrint('SerEmotionTflite: chargement modèle impossible: $e\n$st');
      return null;
    }

    final y = await readWavMonoFloat32(wavPath);
    if (y == null) {
      debugPrint('SerEmotionTflite: WAV 16 kHz mono introuvable ou invalide.');
      return null;
    }

    final y24 = _fitLength24000(y);
    final mfcc = MfccSer.computeMfcc47(y24);
    if (mfcc == null) {
      debugPrint('SerEmotionTflite: MFCC non calculé (audio trop court ?).');
      return null;
    }

    final interp = _interpreter!;
    final input = [
      List.generate(47, (t) => List.generate(13, (c) => mfcc[t][c])),
    ];

    final flatOut = List<double>.filled(4, 0.0);
    final nestedOut = [List<double>.filled(4, 0.0)];
    List<double> raw;
    try {
      interp.run(input, flatOut);
      raw = flatOut;
    } catch (_) {
      try {
        interp.run(input, nestedOut);
        raw = nestedOut[0];
      } catch (e, st) {
        debugPrint('SerEmotionTflite: inference $e\n$st');
        return null;
      }
    }
    final probs = _postprocessOutput(raw);
    var best = 0;
    for (var i = 1; i < 4; i++) {
      if (probs[i] > probs[best]) best = i;
    }
    return SerEmotionOutput(classIndex: best, probabilities: probs);
  }

  static Float32List _fitLength24000(Float32List y) {
    const n = MfccSer.targetSamples;
    if (y.length == n) return y;
    if (y.length > n) {
      final s = (y.length - n) ~/ 2;
      return Float32List.sublistView(y, s, s + n);
    }
    final o = Float32List(n);
    final off = (n - y.length) ~/ 2;
    for (var i = 0; i < y.length; i++) {
      o[off + i] = y[i];
    }
    return o;
  }

  /// Sortie dense softmax Keras : déjà des probabilités ; sinon logits → softmax.
  static List<double> _postprocessOutput(List<double> raw) {
    final sum = raw.fold<double>(0, (a, b) => a + b);
    if (sum > 0.98 && sum < 1.02 && raw.every((v) => v >= -1e-6)) {
      return List.generate(raw.length, (i) => (raw[i] / sum).clamp(0.0, 1.0));
    }
    return _softmax(raw);
  }

  static List<double> _softmax(List<double> z) {
    var m = -1e100;
    for (final v in z) {
      if (v > m) m = v;
    }
    var s = 0.0;
    final e = List<double>.generate(z.length, (i) {
      final v = math.exp(z[i] - m);
      s += v;
      return v;
    });
    return List.generate(e.length, (i) => e[i] / (s + 1e-12));
  }
}

class SerEmotionOutput {
  SerEmotionOutput({required this.classIndex, required this.probabilities});

  final int classIndex;
  final List<double> probabilities;

  double get confidence {
    var m = 0.0;
    for (final p in probabilities) {
      if (p > m) m = p;
    }
    return m;
  }
}
