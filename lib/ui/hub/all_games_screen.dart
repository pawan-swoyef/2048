import 'package:flutter/material.dart';

import '../../game/score_store.dart';
import '../theme_controller.dart';
import 'game_card.dart';
import 'game_registry.dart';

/// Lists every game in the collection. Reached from the hub's "See all".
class AllGamesScreen extends StatefulWidget {
  const AllGamesScreen({super.key});

  @override
  State<AllGamesScreen> createState() => _AllGamesScreenState();
}

class _AllGamesScreenState extends State<AllGamesScreen> {
  final ScoreStore _store = ScoreStore();
  final Map<String, int> _bests = {};

  @override
  void initState() {
    super.initState();
    _loadBests();
  }

  Future<void> _loadBests() async {
    for (final g in kGames) {
      _bests[g.id] = await _store.bestFor(g.id);
    }
    if (mounted) setState(() {});
  }

  Future<void> _open(GameInfo game) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => game.builder()));
    _loadBests();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: theme.onBackground),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      Text('All Games',
                          style: TextStyle(
                              color: theme.onBackground,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: kGames.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final g = kGames[i];
                        return GameCompactCard(
                          game: g,
                          best: _bests[g.id] ?? 0,
                          onTap: () => _open(g),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
