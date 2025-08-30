import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../volcano_game.dart';

class ScoreDisplay extends PositionComponent with HasGameRef<VolcanoGame> {
  late TextComponent scoreText;
  
  @override
  Future<void> onLoad() async {
    // Position in top right corner, away from health bar
    position = Vector2(gameRef.size.x - 20, 20);
    
    scoreText = TextComponent(
      text: '00000',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace', // Use monospace for consistent number spacing
        ),
      ),
      anchor: Anchor.topRight,
    );
    add(scoreText);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update score display with leading zeros
    final formattedScore = gameRef.score.toString().padLeft(5, '0');
    scoreText.text = formattedScore;
  }
}