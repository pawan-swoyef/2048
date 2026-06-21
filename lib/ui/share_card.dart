import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

/// Google Play listing for the app. Used both in share text (tappable link)
/// and as the call-to-action on the share image.
const String kStoreLink =
    'https://play.google.com/store/apps/details?id=com.number.twofoureight';
const String kAppName = '2048 Number Puzzle';

// Fixed brand palette for share images so a shared result looks the same
// regardless of which in-app theme the player has selected.
const _brandTop = Color(0xFF4A2BA8);
const _brandBottom = Color(0xFF2A1655);
const _brandGold = Color(0xFFFFC93C);

/// A self-contained, branded result image rendered off-screen and shared as a
/// PNG. Designed at a fixed logical size; capture at a higher [pixelRatio] for
/// a crisp social-sized image.
class ShareCard extends StatelessWidget {
  final String title; // e.g. "2048 DAILY #128"
  final String valueLabel; // small line above the big value, e.g. "You reached"
  final String value; // the big gold value, e.g. "512"
  final String? valueSub; // small line below, e.g. "in 47 moves"
  final String? badge; // e.g. "🔥 5 day streak"

  const ShareCard({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.value,
    this.valueSub,
    this.badge,
  });

  /// Logical size of the card; the PNG is this multiplied by the pixel ratio.
  static const Size logicalSize = Size(340, 460);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: logicalSize,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_brandTop, _brandBottom],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('👑', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 6),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(valueLabel,
                  style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: _brandGold,
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              if (valueSub != null) ...[
                const SizedBox(height: 4),
                Text(valueSub!,
                    style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 16)),
              ],
              if (badge != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0x22FF7A3D),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0x99FF7A3D), width: 1.4),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                ),
              ],
              const Spacer(),
              const Divider(color: Color(0x33FFFFFF), height: 1),
              const SizedBox(height: 12),
              Text(
                kAppName,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              const Text(
                '▶  Play free on Google Play',
                style: TextStyle(color: _brandGold, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Captures the [RepaintBoundary] behind [key] to PNG bytes. Returns null if
/// the boundary isn't available (e.g. not yet laid out).
Future<Uint8List?> captureBoundaryPng(GlobalKey key, {double pixelRatio = 3}) async {
  // Make sure a frame has been painted so the (off-screen) boundary is ready.
  await WidgetsBinding.instance.endOfFrame;
  final object = key.currentContext?.findRenderObject();
  if (object is! RenderRepaintBoundary) return null;
  final image = await object.toImage(pixelRatio: pixelRatio);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data?.buffer.asUint8List();
}

/// Shares the result as an image (captured from [boundaryKey]) plus [text]
/// (which carries the tappable app link). Falls back to text-only sharing if
/// the image can't be captured.
Future<void> shareResultImage({
  required GlobalKey boundaryKey,
  required String text,
}) async {
  final bytes = await captureBoundaryPng(boundaryKey);
  if (bytes == null) {
    await Share.share(text);
    return;
  }
  final file = XFile.fromData(bytes, mimeType: 'image/png', name: 'result.png');
  await Share.shareXFiles([file], text: text);
}

/// Wraps [card] in a [RepaintBoundary] positioned off-screen so it is laid out
/// and painted (capturable) without being visible. Place inside a
/// `Stack(clipBehavior: Clip.none)`.
class OffscreenShareCard extends StatelessWidget {
  final GlobalKey boundaryKey;
  final ShareCard card;
  const OffscreenShareCard({super.key, required this.boundaryKey, required this.card});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -3000,
      top: 0,
      child: RepaintBoundary(
        key: boundaryKey,
        child: MediaQuery(
          // Lock text scaling so the captured image is consistent.
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: Directionality(textDirection: TextDirection.ltr, child: card),
        ),
      ),
    );
  }
}
