import 'dart:ui' show Offset;

import '../game/board.dart';

/// Maps an accumulated drag [delta] to a move [Direction], or null if the drag
/// hasn't yet travelled [threshold] pixels. The dominant axis wins, so a
/// roughly diagonal swipe still resolves to a single direction.
Direction? swipeDirection(Offset delta, {double threshold = 24}) {
  if (delta.distance < threshold) return null;
  if (delta.dx.abs() > delta.dy.abs()) {
    return delta.dx > 0 ? Direction.right : Direction.left;
  }
  return delta.dy > 0 ? Direction.down : Direction.up;
}
