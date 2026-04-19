import 'dart:io';
import 'dart:typed_data';

/// Lit un WAV PCM 16 bits little-endian **mono** et renvoie les échantillons float [-1, 1].
/// Retourne null si le format n’est pas supporté.
Future<Float32List?> readWavMonoFloat32(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length < 44) return null;
    if (String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF') return null;
    if (String.fromCharCodes(bytes.sublist(8, 12)) != 'WAVE') return null;

    var offset = 12;
    int? audioFormat;
    int? numChannels;
    int? sampleRate;
    int? bitsPerSample;
    var dataOffset = -1;
    var dataSize = 0;

    while (offset + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final size = ByteData.sublistView(bytes, offset + 4, offset + 8).getUint32(0, Endian.little);
      offset += 8;
      if (id == 'fmt ') {
        if (offset + size > bytes.length) return null;
        final fmt = ByteData.sublistView(bytes, offset, offset + size);
        audioFormat = fmt.getUint16(0, Endian.little);
        numChannels = fmt.getUint16(2, Endian.little);
        sampleRate = fmt.getUint32(4, Endian.little);
        bitsPerSample = fmt.getUint16(14, Endian.little);
      } else if (id == 'data') {
        dataOffset = offset;
        dataSize = size;
        break;
      }
      offset += size + (size & 1);
    }

    if (dataOffset < 0 || audioFormat != 1 || bitsPerSample != 16 || numChannels == null) return null;
    if (numChannels != 1) return null;
    if (sampleRate != 16000) return null;

    final end = (dataOffset + dataSize).clamp(0, bytes.length);
    final pcm = bytes.sublist(dataOffset, end);
    final n = pcm.length ~/ 2;
    final out = Float32List(n);
    final bd = ByteData.sublistView(Uint8List.fromList(pcm));
    for (var i = 0; i < n; i++) {
      final s = bd.getInt16(i * 2, Endian.little);
      out[i] = s / 32768.0;
    }
    return out;
  } catch (_) {
    return null;
  }
}
