import 'package:flutter/material.dart';

import 'ads/ads_init.dart';
import 'ui/game_screen.dart';
import 'ui/tile_style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAds();
  runApp(const Game2048App());
}

class Game2048App extends StatelessWidget {
  const Game2048App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: GameColors.gradientTop,
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}
