// One-off: strip the outer background from the app icon, leaving the rounded
// artwork on a fully TRANSPARENT background.
//
// The source art is a rounded-square icon sitting on a flat gray "checkerboard"
// background (baked opaque, not transparent). This flood-fills that flat
// background from the edges and makes it transparent, so the icon has no
// surrounding frame/background at all.
//
// Run from the project root: dart run tool/fix_icon.dart
import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  final art = img.decodePng(
      File('assets/icon/icon_original_backup.png').readAsBytesSync())!;
  final w = art.width, h = art.height;

  // A pixel belongs to the outer frame if it's near-neutral (the checkerboard's
  // light squares AND the gray drop-shadow). Flood-fill from the edges means the
  // saturated icon stops the spread, so the interior (white text, dark shadows)
  // is never touched even though it's also low-saturation.
  bool isFrame(int x, int y) {
    final p = art.getPixel(x, y);
    final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
    final sat = max(r, max(g, b)) - min(r, min(g, b));
    return sat <= 24;
  }

  // Flood-fill the frame from the borders so interior light pixels are safe.
  var bg = List<bool>.filled(w * h, false);
  final q = Queue<int>();
  void seed(int x, int y) {
    final i = y * w + x;
    if (!bg[i] && isFrame(x, y)) {
      bg[i] = true;
      q.add(i);
    }
  }

  for (var x = 0; x < w; x++) {
    seed(x, 0);
    seed(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    seed(0, y);
    seed(w - 1, y);
  }
  while (q.isNotEmpty) {
    final i = q.removeFirst();
    final x = i % w, y = i ~/ w;
    if (x > 0) seed(x - 1, y);
    if (x < w - 1) seed(x + 1, y);
    if (y > 0) seed(x, y - 1);
    if (y < h - 1) seed(x, y + 1);
  }

  // Dilate the frame mask a few px to eat the anti-aliased gray ring at the
  // rounded edge (invisible to lose, since the gradient matches the art).
  for (var pass = 0; pass < 4; pass++) {
    final next = List<bool>.from(bg);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        if (bg[i]) continue;
        if ((x > 0 && bg[i - 1]) ||
            (x < w - 1 && bg[i + 1]) ||
            (y > 0 && bg[i - w]) ||
            (y < h - 1 && bg[i + w])) {
          next[i] = true;
        }
      }
    }
    bg = next;
  }

  // Compose: transparent where the frame was, original art everywhere else.
  final out = img.Image(width: w, height: h, numChannels: 4);
  var cleared = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (bg[y * w + x]) {
        out.setPixelRgba(x, y, 0, 0, 0, 0); // transparent background
        cleared++;
        continue;
      }
      final p = art.getPixel(x, y);
      out.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
    }
  }
  // Zoom: enlarge the icon a little within the canvas and re-center it on the
  // artwork. Tweak [zoom] to taste (1.0 = no change).
  const zoom = 1.15;
  var minX = w, minY = h, maxX = -1, maxY = -1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (bg[y * w + x]) continue; // transparent background
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
  }
  final bw = maxX - minX + 1, bh = maxY - minY + 1;
  final crop = img.copyCrop(out, x: minX, y: minY, width: bw, height: bh);
  final resized = img.copyResize(crop,
      width: (bw * zoom).round(),
      height: (bh * zoom).round(),
      interpolation: img.Interpolation.cubic);

  final canvas = img.Image(width: w, height: h, numChannels: 4);
  img.compositeImage(canvas, resized,
      dstX: ((w - resized.width) / 2).round(),
      dstY: ((h - resized.height) / 2).round());
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(canvas));

  final pct = (cleared / (w * h) * 100).toStringAsFixed(1);
  stdout.writeln('Rebuilt assets/icon/icon.png '
      '(${w}x$h, transparent = $pct%, zoom = ${zoom}x).');
}
