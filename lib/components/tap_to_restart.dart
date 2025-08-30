import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../volcano_game.dart';

class TapToRestart extends RectangleComponent with TapCallbacks, HasGameRef<VolcanoGame> {
  @override
  Future<void> onLoad() async {
    size = gameRef.size;
    position = Vector2.zero();
    paint.color = const Color(0x00000000); // Transparent
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (gameRef.isGameOver) {
      gameRef.restartGame();
      return true;
    }
    return false;
  }
}