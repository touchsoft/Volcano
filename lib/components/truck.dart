import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import '../volcano_game.dart';

class Truck extends SpriteComponent with CollisionCallbacks {
  final double gameWidth;
  final double gameHeight;
  
  double angle = 0;
  double speed = 1.0;
  int direction = 1; // 1 for clockwise, -1 for counter-clockwise
  
  static const double minSpeed = 0.5;
  static const double maxSpeed = 3.0;
  static const double ovalWidth = 140.0;  // Half width of the blue oval path
  static const double ovalHeight = 80.0;  // Half height of the blue oval path
  static const double minScale = 0.6;     // Smallest size when at top
  static const double maxScale = 0.9;     // Largest size when at bottom
  
  Truck({required this.gameWidth, required this.gameHeight});
  
  @override
  Future<void> onLoad() async {
    sprite = Sprite((findGame()! as VolcanoGame).images.fromCache('truck.png'));
    size = Vector2(32, 24);
    anchor = Anchor.center;
    
    add(RectangleHitbox());
    
    _updatePosition();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    angle += speed * direction * dt;
    
    if (angle > 2 * pi) angle -= 2 * pi;
    if (angle < 0) angle += 2 * pi;
    
    _updatePosition();
  }
  
  void _updatePosition() {
    final centerX = gameWidth / 2;
    final centerY = gameHeight / 2;
    
    final x = centerX + ovalWidth * cos(angle);
    final y = centerY + ovalHeight * sin(angle);
    
    position = Vector2(x, y);
    
    final normalizedY = (sin(angle) + 1) / 2;
    final scaleValue = minScale + (maxScale - minScale) * normalizedY;
    scale = Vector2.all(scaleValue);
    
    if (sin(angle) < -0.7) {
      opacity = max(0.0, 1.0 - (-0.7 - sin(angle)) / 0.3);
    } else {
      opacity = 1.0;
    }
  }
  
  
  void increaseSpeed() {
    speed = (speed + 0.2).clamp(minSpeed, maxSpeed);
  }
  
  void decreaseSpeed() {
    speed = (speed - 0.2).clamp(minSpeed, maxSpeed);
  }
}