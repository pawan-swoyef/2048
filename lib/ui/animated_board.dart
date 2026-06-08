import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../game/board.dart';
import '../game/game_state.dart';
import 'theme_controller.dart';
import 'tile_widget.dart';

/// The board with true sliding animation: tiles glide from their source cells
/// to their destinations, then merge results and new spawns pop in.
///
/// Each transition is identified by [tick]; when it changes, the slide replays
/// using [moves]. After the slide, the board settles to [board] and the cells
/// in [popCells] (flat row*size+col indices) pop.
class AnimatedBoard extends StatefulWidget {
  final List<List<int>> board;
  final List<TileMove> moves;
  final Set<int> popCells;
  final int tick;

  const AnimatedBoard({
    super.key,
    required this.board,
    required this.moves,
    required this.popCells,
    required this.tick,
  });

  @override
  State<AnimatedBoard> createState() => _AnimatedBoardState();
}

class _AnimatedBoardState extends State<AnimatedBoard>
    with SingleTickerProviderStateMixin {
  static const double _padding = 12;
  static const double _gap = 12;

  late final AnimationController _controller;
  bool _sliding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _sliding = false);
        }
      });
    _begin();
  }

  @override
  void didUpdateWidget(AnimatedBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tick != widget.tick) _begin();
  }

  void _begin() {
    final shouldSlide = widget.moves.any(
      (m) => m.fromRow != m.toRow || m.fromCol != m.toCol,
    );
    if (!shouldSlide) {
      setState(() => _sliding = false); // new game / first paint: just pop in
      return;
    }
    setState(() => _sliding = true);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final cell =
            (side - 2 * _padding - (kBoardSize - 1) * _gap) / kBoardSize;
        double leftOf(int c) => _padding + c * (cell + _gap);
        double topOf(int r) => _padding + r * (cell + _gap);

        return Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            color: theme.boardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.glassStroke, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              ..._backgroundCells(theme, cell, leftOf, topOf),
              Positioned.fill(
                child: _sliding
                    ? AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => Stack(
                          children: _slidingTiles(cell, leftOf, topOf),
                        ),
                      )
                    : Stack(children: _settledTiles(cell, leftOf, topOf)),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _backgroundCells(GameTheme theme, double cell,
      double Function(int) leftOf, double Function(int) topOf) {
    final cells = <Widget>[];
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        cells.add(Positioned(
          left: leftOf(c),
          top: topOf(r),
          width: cell,
          height: cell,
          child: Container(
            decoration: BoxDecoration(
              color: theme.emptyCell,
              borderRadius: BorderRadius.circular(cell * 0.13),
            ),
          ),
        ));
      }
    }
    return cells;
  }

  List<Widget> _slidingTiles(
      double cell, double Function(int) leftOf, double Function(int) topOf) {
    final t = Curves.easeInOut.transform(_controller.value);
    return [
      for (final m in widget.moves)
        Positioned(
          left: lerpDouble(leftOf(m.fromCol), leftOf(m.toCol), t)!,
          top: lerpDouble(topOf(m.fromRow), topOf(m.toRow), t)!,
          width: cell,
          height: cell,
          child: TileWidget(value: m.value, size: cell),
        ),
    ];
  }

  List<Widget> _settledTiles(
      double cell, double Function(int) leftOf, double Function(int) topOf) {
    final tiles = <Widget>[];
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        final value = widget.board[r][c];
        if (value == 0) continue;
        final index = r * kBoardSize + c;
        final pop = widget.popCells.contains(index);
        tiles.add(Positioned(
          left: leftOf(c),
          top: topOf(r),
          width: cell,
          height: cell,
          // Pop tiles get a tick-scoped key so the scale animation replays each
          // transition; static tiles keep a stable key so they don't re-animate.
          key: pop
              ? ValueKey('pop-$index-${widget.tick}')
              : ValueKey('cell-$index'),
          child: TileWidget(value: value, size: cell, animateIn: pop),
        ));
      }
    }
    return tiles;
  }
}
