import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fft/fft.dart';

/// MFCC (13 × 47) aligné sur le notebook SER (librosa : sr=16000, n_fft=2048, hop=512, n_mels=128, centre).
/// Entrée : exactement [targetSamples] échantillons (24000 = 1,5 s à 16 kHz).
class MfccSer {
  MfccSer._();

  static const int sr = 16000;
  static const int nFft = 2048;
  static const int hop = 512;
  static const int nMels = 128;
  static const int nMfcc = 13;
  static const int targetSamples = 24000;

  static List<List<double>>? _melBasis;
  static List<double>? _hann;

  static void _ensureInit() {
    if (_melBasis != null) return;
    _hann = List.generate(nFft, (i) => 0.5 - 0.5 * math.cos(2 * math.pi * i / nFft));
    _melBasis = _buildMel(sr.toDouble(), nFft, nMels, 0.0, sr / 2.0, htk: false);
  }

  /// Retourne [47][13] : une ligne par trame temporelle, 13 coefficients MFCC.
  static List<List<double>>? computeMfcc47(Float32List y) {
    _ensureInit();
    final mel = _melBasis!;
    final hann = _hann!;

    if (y.length < nFft) return null;

    // Fenêtrage identique au STFT librosa center=True : reflect pad de nFft/2 de chaque côté.
    final pad = nFft ~/ 2;
    final yPad = Float32List(y.length + 2 * pad);
    for (var i = 0; i < pad; i++) {
      yPad[i] = _reflectAt(y, i - pad);
    }
    for (var i = 0; i < y.length; i++) {
      yPad[pad + i] = y[i];
    }
    for (var i = 0; i < pad; i++) {
      yPad[pad + y.length + i] = _reflectAt(y, y.length - 1 - i);
    }

    final nFrames = 1 + (yPad.length - nFft) ~/ hop;
    if (nFrames < 47) return null;

    // Prend les 47 trames centrées si l’audio est plus long (ex. enregistrement MoodCast).
    var startFrame = 0;
    if (nFrames > 47) {
      startFrame = ((nFrames - 47) ~/ 2).clamp(0, nFrames - 47);
    }

    final out = List.generate(47, (_) => List<double>.filled(nMfcc, 0));

    for (var fi = 0; fi < 47; fi++) {
      final t = (startFrame + fi) * hop;
      final frame = Float32List(nFft);
      for (var i = 0; i < nFft; i++) {
        frame[i] = yPad[t + i] * hann[i];
      }

      final fftOut = FFT.Transform(frame.map((e) => e.toDouble()).toList());
      final nBins = nFft ~/ 2 + 1;
      final spec = List.generate(nBins, (k) {
        final c = fftOut[k];
        final p = c.real * c.real + c.imaginary * c.imaginary;
        return p + 1e-10;
      });

      final melPow = List<double>.filled(nMels, 0);
      for (var m = 0; m < nMels; m++) {
        var s = 0.0;
        for (var k = 0; k < spec.length; k++) {
          s += mel[m][k] * spec[k];
        }
        melPow[m] = s;
      }

      final logMel = List.generate(nMels, (m) {
        final v = math.max(melPow[m], 1e-10);
        return 10 * math.log(v) / math.ln10;
      });

      final mfccCol = _dct2OrthoFirst13(logMel);
      for (var c = 0; c < nMfcc; c++) {
        out[fi][c] = mfccCol[c];
      }
    }

    return out;
  }

  static double _reflectAt(Float32List y, int idx) {
    if (idx < 0) {
      var j = -idx;
      while (j >= y.length) {
        j = 2 * (y.length - 1) - j;
      }
      return y[j.clamp(0, y.length - 1)];
    }
    if (idx >= y.length) {
      var j = idx - y.length;
      j = y.length - 1 - (j % y.length);
      return y[j.clamp(0, y.length - 1)];
    }
    return y[idx];
  }

  /// DCT-II orthonormée (type scipy `dct(..., type=2, norm='ortho')`), 13 premiers coeffs.
  static List<double> _dct2OrthoFirst13(List<double> x) {
    final n = x.length;
    const kMax = nMfcc;
    final out = List<double>.filled(kMax, 0);
    final scale0 = math.sqrt(1.0 / n);
    final scale = math.sqrt(2.0 / n);
    for (var k = 0; k < kMax; k++) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += x[i] * math.cos(math.pi / n * (i + 0.5) * k);
      }
      out[k] = (k == 0) ? s * scale0 : s * scale;
    }
    return out;
  }

  /// Slaney hz ↔ mel (htk=false), comme librosa.
  static double _hzToMel(double hz, {required bool htk}) {
    if (htk) {
      return 2595.0 * math.log(1.0 + hz / 700.0) / math.ln10;
    }
    const fMin = 0.0;
    const fSp = 200.0 / 3.0;
    var mel = (hz - fMin) / fSp;
    const minLogHz = 1000.0;
    final minLogMel = (minLogHz - fMin) / fSp;
    final logStep = math.log(6.4) / 27.0;
    if (hz >= minLogHz) {
      mel = minLogMel + math.log(hz / minLogHz) / logStep;
    }
    return mel;
  }

  static double _melToHz(double mel, {required bool htk}) {
    if (htk) {
      return 700.0 * (math.pow(10.0, mel * math.ln10 / 2595.0) - 1.0);
    }
    const fMin = 0.0;
    const fSp = 200.0 / 3.0;
    const minLogHz = 1000.0;
    final minLogMel = (minLogHz - fMin) / fSp;
    final logStep = math.log(6.4) / 27.0;
    if (mel < minLogMel) {
      return fMin + fSp * mel;
    }
    return minLogHz * math.exp(logStep * (mel - minLogMel));
  }

  /// `nPoints` points en Hz, uniformément espacés sur l’échelle mel entre fMin et fMax.
  static List<double> _melSpacedHz(int nPoints, double fMin, double fMax, {required bool htk}) {
    final minM = _hzToMel(fMin, htk: htk);
    final maxM = _hzToMel(fMax, htk: htk);
    return List.generate(nPoints, (i) {
      final t = nPoints <= 1 ? 0.0 : i / (nPoints - 1);
      return _melToHz(minM + t * (maxM - minM), htk: htk);
    });
  }

  static List<double> _fftFreqs(int nF, double sr) {
    return List.generate(nF ~/ 2 + 1, (i) => (i * sr) / nF);
  }

  /// Matrice mel (n_mels × n_fft/2+1), norm Slaney.
  static List<List<double>> _buildMel(double sr, int nFft, int nMels, double fMin, double fMax, {required bool htk}) {
    final nF = nFft ~/ 2 + 1;
    final weights = List.generate(nMels, (_) => List<double>.filled(nF, 0.0));
    final fftFreqs = _fftFreqs(nFft, sr);
    final melF = _melSpacedHz(nMels + 2, fMin, fMax, htk: htk);
    final fdiff = List<double>.generate(nMels + 1, (i) => melF[i + 1] - melF[i]);

    for (var i = 0; i < nMels; i++) {
      final ramps = List<double>.generate(nF, (j) => melF[i] - fftFreqs[j]);
      for (var j = 0; j < nF; j++) {
        final lower = -ramps[j] / fdiff[i];
        final upper = (melF[i + 2] - fftFreqs[j]) / fdiff[i + 1];
        weights[i][j] = math.max(0.0, math.min(lower, upper));
      }
    }

    for (var i = 0; i < nMels; i++) {
      final enorm = 2.0 / (melF[i + 2] - melF[i]);
      for (var j = 0; j < nF; j++) {
        weights[i][j] *= enorm;
      }
    }
    return weights;
  }
}
