// One-off generator for the game's sound effects.
//
// Synthesizes short, license-free WAV files (16-bit mono PCM) into
// assets/sounds/. Run with:  dart run tool/gen_sounds.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 44100;

void main() {
  final dir = Directory('assets/sounds')..createSync(recursive: true);

  _write('${dir.path}/move.wav', _move());
  _write('${dir.path}/merge.wav', _merge());
  _write('${dir.path}/win.wav', _win());
  _write('${dir.path}/gameover.wav', _gameOver());

  stdout.writeln('Generated sound effects in ${dir.path}/');
}

/// Soft, short tick for a slide.
List<double> _move() {
  return _envelope(_tone(280, 0.045, volume: 0.22),
      attack: 0.003, release: 0.03);
}

/// Bright two-note pop for a merge.
List<double> _merge() {
  final a = _envelope(_tone(660, 0.07, volume: 0.32), release: 0.04);
  final b = _envelope(_tone(990, 0.10, volume: 0.32), release: 0.06);
  return [...a, ...b];
}

/// Triumphant fanfare for a win: a quick rising run that lands on a held
/// major chord.
List<double> _win() {
  final out = <double>[];

  // Quick ascending flourish.
  for (final f in [523.25, 659.25, 783.99, 1046.50]) {
    out.addAll(_envelope(_tone(f, 0.10, volume: 0.28), release: 0.035));
  }

  // Sustained C-major chord to celebrate.
  out.addAll(_envelope(
    _chord([523.25, 659.25, 783.99, 1046.50], 0.7, volume: 0.20),
    attack: 0.006,
    release: 0.3,
  ));

  return out;
}

/// Several frequencies played together (a chord).
List<double> _chord(List<double> freqs, double seconds, {double volume = 0.2}) {
  final n = (seconds * sampleRate).round();
  return List<double>.generate(n, (i) {
    final t = i / sampleRate;
    var sample = 0.0;
    for (final f in freqs) {
      sample += sin(2 * pi * f * t);
    }
    return volume * sample / freqs.length;
  });
}

/// Descending tones for game over.
List<double> _gameOver() {
  final notes = [392.00, 311.13, 233.08]; // G4 Eb4 Bb3
  final out = <double>[];
  for (final f in notes) {
    out.addAll(_envelope(_tone(f, 0.20, volume: 0.30), release: 0.10));
  }
  return out;
}

/// A sine tone with a touch of second harmonic for warmth.
List<double> _tone(double freq, double seconds, {double volume = 0.3}) {
  final n = (seconds * sampleRate).round();
  return List<double>.generate(n, (i) {
    final t = i / sampleRate;
    final fundamental = sin(2 * pi * freq * t);
    final harmonic = 0.25 * sin(2 * pi * freq * 2 * t);
    return volume * (fundamental + harmonic) / 1.25;
  });
}

/// Applies a linear attack/release envelope to avoid clicks.
List<double> _envelope(List<double> samples,
    {double attack = 0.005, double release = 0.05}) {
  final n = samples.length;
  final aN = (attack * sampleRate).round();
  final rN = (release * sampleRate).round();
  for (var i = 0; i < n; i++) {
    var gain = 1.0;
    if (i < aN) gain = i / aN;
    if (i > n - rN) gain = min(gain, (n - i) / rN);
    samples[i] *= gain;
  }
  return samples;
}

/// Writes mono 16-bit PCM WAV.
void _write(String path, List<double> samples) {
  final dataBytes = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    dataBytes.setInt16(i * 2, (clamped * 32767).round(), Endian.little);
  }

  final dataSize = dataBytes.lengthInBytes;
  final header = ByteData(44);
  void s(int off, String str) {
    for (var i = 0; i < str.length; i++) {
      header.setUint8(off + i, str.codeUnitAt(i));
    }
  }

  s(0, 'RIFF');
  header.setUint32(4, 36 + dataSize, Endian.little);
  s(8, 'WAVE');
  s(12, 'fmt ');
  header.setUint32(16, 16, Endian.little); // PCM chunk size
  header.setUint16(20, 1, Endian.little); // audio format = PCM
  header.setUint16(22, 1, Endian.little); // channels = mono
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  header.setUint16(32, 2, Endian.little); // block align
  header.setUint16(34, 16, Endian.little); // bits per sample
  s(36, 'data');
  header.setUint32(40, dataSize, Endian.little);

  final out = BytesBuilder()
    ..add(header.buffer.asUint8List())
    ..add(dataBytes.buffer.asUint8List());
  File(path).writeAsBytesSync(out.toBytes());
}
