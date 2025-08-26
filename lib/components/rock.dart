import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../volcano_game.dart';
import 'truck.dart';
import 'particle_explosion.dart';

class Rock extends SpriteComponent with CollisionCallbacks {
  final bool isGrey;
  final double gameWidth;
  final double gameHeight;
  
  late Vector2 velocity;
  late Vector2 startPosition;
  final double gravity = 300.0;
  bool hasCollided = false;
  late double targetX;
  late double targetY;
  bool isBehindVolcano = false;
  late double startTime;
  late double flightDuration;
  
  static const double ovalWidth = 140.0;
  static const double ovalHeight = 80.0;
  
  Rock({
    required this.isGrey,
    required Vector2 startPosition,
    required this.gameWidth,
    required this.gameHeight,
  }) : this.startPosition = startPosition;
  
  @override
  Future<void> onLoad() async {
    final game = findGame()! as VolcanoGame;
    sprite = Sprite(game.images.fromCache(isGrey ? 'rock-grey.png' : 'rock-red.png'));
    size = Vector2(20, 20); // All rocks start same size
    anchor = Anchor.center;
    
    add(RectangleHitbox());
    
    position = startPosition.clone();
    startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    _calculateTrajectory();
  }
  
  void _calculateTrajectory() {
    final random = Random();
    
    // Target should be on the island edge (truck path area)
    final angle = random.nextDouble() * 2 * pi;
    
    // Calculate island boundaries (edge of the yellow island)
    final islandRadiusX = ovalWidth * 1.6; // Island is larger than truck path
    final islandRadiusY = ovalHeight * 1.4;
    
    // Target point on island edge
    targetX = gameWidth / 2 + islandRadiusX * cos(angle);
    targetY = gameHeight / 2 + islandRadiusY * sin(angle);
    
    // All rocks land in front of volcano on the thick blue line
    isBehindVolcano = false; // No rocks go behind anymore
    priority = 15; // All rocks in front of volcano (volcano is priority 10)
    
    final distance = Vector2(targetX - position.x, targetY - position.y);
    
    final initialSpeed = 150.0 + random.nextDouble() * 100.0;
    flightDuration = 1.5 + random.nextDouble() * 1.0;
    
    velocity = Vector2(
      distance.x / flightDuration,
      distance.y / flightDuration - 0.5 * gravity * flightDuration,
    );
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (hasCollided) return;
    
    position += velocity * dt;
    velocity.y += gravity * dt;
    
    // Calculate flight progress (0.0 = just launched, 1.0 = about to land)
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final elapsedTime = currentTime - startTime;
    final flightProgress = (elapsedTime / flightDuration).clamp(0.0, 1.0);
    
    // All rocks are in front of volcano and get larger during flight  
    final targetScale = 1.4; // End up quite large
    final currentScale = 1.0 + (flightProgress * (targetScale - 1.0));
    scale = Vector2.all(currentScale);
    opacity = 1.0;
    
    // Check if rock hits the island ground (truck path level on the thick blue line)  
    final centerX = gameWidth / 2;
    final centerY = gameHeight / 2;
    final truckPathY = centerY + ovalHeight * 0.8; // Ground level of truck path (thick blue line)
    
    if (position.y >= truckPathY) {
      // Rock hit the ground, create explosion
      final game = findGame()! as VolcanoGame;
      final explosion = ParticleExplosion(
        position: position.clone(),
        color: isGrey ? Colors.grey : Colors.red,
      );
      game.add(explosion);
      
      hasCollided = true;
      removeFromParent();
      return;
    }
    
    if (position.y > gameHeight + 50 || 
        position.x < -50 || 
        position.x > gameWidth + 50) {
      removeFromParent();
    }
  }
  
  @override
  bool onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Truck && !hasCollided) {
      hasCollided = true;
      
      final game = findGame()! as VolcanoGame;
      
      // Create explosion for red rock hits
      if (!isGrey) {
        final explosion = ParticleExplosion(
          position: position.clone(),
          color: Colors.red,
          particleCount: 16, // More particles
          speedMultiplier: 2.0, // Faster particles
          sizeMultiplier: 2.5, // Larger particles
        );
        game.add(explosion);
      }
      
      game.collectRock(isGrey);
      
      removeFromParent();
      return false;
    }
    return true;
  }
}