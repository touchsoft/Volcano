import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'volcano_game.dart';

void main() {
  runApp(const VolcanoApp());
}

class VolcanoApp extends StatelessWidget {
  const VolcanoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volcano Truck Game',
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: AspectRatio(
              aspectRatio: 480 / 720, // Match game dimensions
              child: GameWidget<VolcanoGame>.controlled(
                gameFactory: VolcanoGame.new,
              ),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
