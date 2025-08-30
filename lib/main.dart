import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'volcano_game.dart';

void main() {
  runApp(const VolcanoApp());
}

class VolcanoApp extends StatefulWidget {
  const VolcanoApp({super.key});
  
  @override
  _VolcanoAppState createState() => _VolcanoAppState();
}

class _VolcanoAppState extends State<VolcanoApp> {
  late VolcanoGame game;
  
  @override
  void initState() {
    super.initState();
    game = VolcanoGame();
  }

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
              child: Stack(
                children: [
                  GameWidget<VolcanoGame>.controlled(
                    gameFactory: () => game,
                  ),
                  // Flutter overlay buttons
                  Positioned(
                    bottom: 50,
                    left: 80,
                    child: _buildButton('D', Colors.blue, () {
                      print('Direction button pressed');
                      if (game.truck.isControlled) {
                        game.truck.changeDirection();
                      }
                    }),
                  ),
                  Positioned(
                    bottom: 50,
                    left: 240 - 30, // Center minus half button width
                    child: _buildButton('B', Colors.red, () {
                      print('Brake button pressed');
                      if (game.truck.isControlled) {
                        game.truck.startBraking();
                      }
                    }, () {
                      print('Brake button released');
                      game.truck.stopBraking();
                    }),
                  ),
                  Positioned(
                    bottom: 50,
                    right: 80,
                    child: _buildButton('A', Colors.green, () {
                      print('Accelerator button pressed');
                      if (game.truck.isControlled) {
                        game.truck.startAccelerating();
                      }
                    }, () {
                      print('Accelerator button released');
                      game.truck.stopAccelerating();
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
  
  Widget _buildButton(String text, Color color, VoidCallback onPressed, [VoidCallback? onReleased]) {
    return GestureDetector(
      onTapDown: (_) => onPressed(),
      onTapUp: onReleased != null ? (_) => onReleased() : null,
      onTapCancel: onReleased,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.7),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
