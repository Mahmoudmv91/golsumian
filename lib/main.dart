import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled1/jump_circle_game/screens/game_screen.dart';
import 'package:untitled1/night_thief/night_thief.dart';

import 'jump_circle_game/providers/game_provider.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("✅ main started");
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => GameModel())],
    child:   const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Position Skip Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF00A3CC),
      ),
      home: GameScreen(),
    );
  }
}
