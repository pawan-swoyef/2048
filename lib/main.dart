import 'package:flutter/material.dart';

import 'ads/ads_init.dart';
import 'game/score_store.dart';
import 'ui/game_screen.dart';
import 'ui/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAds();
  runApp(const Game2048App());
}

class Game2048App extends StatefulWidget {
  const Game2048App({super.key});

  @override
  State<Game2048App> createState() => _Game2048AppState();
}

class _Game2048AppState extends State<Game2048App> {
  final ScoreStore _store = ScoreStore();
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController(
      onChanged: (id, premium) => _store.saveTheme(id, premium),
    );
    _loadThemePrefs();
  }

  Future<void> _loadThemePrefs() async {
    final premium = await _store.loadPremiumUnlocked();
    final themeId = await _store.loadThemeId();
    _themeController.setPremiumUnlocked(premium);
    _themeController.select(themeId);
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _themeController,
      child: MaterialApp(
        title: '2048 Blocks: Merge Puzzle',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: kThemes.first.backgroundGradient.first,
          useMaterial3: true,
        ),
        home: const GameScreen(),
      ),
    );
  }
}
