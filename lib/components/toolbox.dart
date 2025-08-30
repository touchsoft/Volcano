import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../volcano_game.dart';
import 'truck.dart';

class Toolbox extends SpriteComponent with CollisionCallbacks, HasGameRef<VolcanoGame> {
  double lifeTimer = 0.0;
  static const double maxLifetime = 3.0; // 3 seconds on screen
  late ScaleEffect pulsateEffect;
  
  @override
  Future<void> onLoad() async {
    sprite = Sprite(gameRef.images.fromCache('toolbox.png'));
    size = Vector2(32, 32); // Smaller 32px square
    anchor = Anchor.center;
    priority = 20; // Above rocks but below UI
    
    add(RectangleHitbox());
    
    // Position on truck track but not behind volcano
    _positionOnTrack();
    
    // Add pulsating scale effect (80% to 120% of base size)
    pulsateEffect = ScaleEffect.to(
      Vector2.all(1.2), // Scale to 120%
      EffectController(
        duration: 1.0,
        alternate: true,
        infinite: true,
      ),
    );
    add(pulsateEffect);
    
    // Remove glow effect - no longer needed
  }
  
  void _positionOnTrack() {
    // Position randomly around the oval track but avoid volcano area
    final random = Random();
    final angle = random.nextDouble() * 2 * pi;
    
    // Use same oval dimensions as truck
    final ovalWidth = 160.0;
    final ovalHeight = 50.0;
    final centerX = gameRef.size.x / 2;
    final centerY = gameRef.size.y / 2 + 40;
    
    // Calculate position on oval
    final x = centerX + ovalWidth * cos(angle);
    final y = centerY + ovalHeight * sin(angle);
    
    // Check if position is behind volcano (avoid center area)
    final volcanoCenter = Vector2(centerX, centerY - 10);
    final distanceFromVolcano = (Vector2(x, y) - volcanoCenter).length;
    
    if (distanceFromVolcano < 80) {
      // Too close to volcano, adjust position outward
      final direction = (Vector2(x, y) - volcanoCenter).normalized();
      final newPosition = volcanoCenter + (direction * 100);
      position = newPosition;
    } else {
      position = Vector2(x, y);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    lifeTimer += dt;
    
    // Remove after 3 seconds
    if (lifeTimer >= maxLifetime) {
      removeFromParent();
    }
    
    // Add some floating motion
    final floatOffset = sin(lifeTimer * 3) * 2; // Gentle floating
    position.y += floatOffset * dt;
  }
  
  @override
  bool onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Truck && gameRef.truck.isControlled) {
      // Heal player by 50%
      gameRef.health = (gameRef.health + 0.5).clamp(0.0, 1.0);
      gameRef.lives = (gameRef.health * 3).ceil().clamp(0, 3);
      
      // Play repair sound
      gameRef.playRepairSound();
      
      // Remove toolbox
      removeFromParent();
      
      return false;
    }
    return false;
  }
}