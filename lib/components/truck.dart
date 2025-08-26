import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import '../volcano_game.dart';

class Truck extends SpriteComponent with CollisionCallbacks {
  final double gameWidth;
  final double gameHeight;
  
  double pathAngle = 0; // Position on the oval path
  double speed = 1.0;
  int direction = 1; // 1 for clockwise, -1 for counter-clockwise
  
  static const double minSpeed = 0.5;
  static const double maxSpeed = 3.0;
  static const double ovalWidth = 180.0;  // Half width of the blue oval path
  static const double ovalHeight = 100.0; // Half height of the blue oval path
  static const double minScale = 0.6;     // Smallest size when at top
  static const double maxScale = 0.9;     // Largest size when at bottom
  
  Truck({required this.gameWidth, required this.gameHeight});
  
  @override
  Future<void> onLoad() async {
    sprite = Sprite((findGame()! as VolcanoGame).images.fromCache('truck.png'));
    size = Vector2(48, 36);
    anchor = Anchor.center;
    
    add(RectangleHitbox());
    
    _updatePosition();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    final previousPathAngle = pathAngle;
    pathAngle += speed * direction * dt;
    
    if (pathAngle > 2 * pi) pathAngle -= 2 * pi;
    if (pathAngle < 0) pathAngle += 2 * pi;
    
    _updatePosition();
    _updateRotation(previousPathAngle);
  }
  
  void _updatePosition() {
    final centerX = gameWidth / 2;
    final centerY = gameHeight / 2;
    
    final x = centerX + ovalWidth * cos(pathAngle);
    final y = centerY + ovalHeight * sin(pathAngle);
    
    position = Vector2(x, y);
    
    final normalizedY = (sin(pathAngle) + 1) / 2;
    final scaleValue = minScale + (maxScale - minScale) * normalizedY;
    scale = Vector2.all(scaleValue);
    
    // Keep truck always visible - volcano will naturally obscure it
    opacity = 1.0;
  }
  
  void _updateRotation(double previousPathAngle) {
    // Calculate the tangent angle for the oval path
    final a = ovalWidth;  // Semi-major axis
    final b = ovalHeight; // Semi-minor axis
    
    // Calculate tangent slope
    final dx = -a * sin(pathAngle);
    final dy = b * cos(pathAngle);
    
    // Get the angle of the tangent vector
    double tangentAngle = atan2(dy, dx);
    
    // Adjust for direction
    if (direction < 0) {
      tangentAngle += pi; // Flip 180 degrees for opposite direction
    }
    
    // Normalize angle to [0, 2π]
    tangentAngle = tangentAngle % (2 * pi);
    if (tangentAngle < 0) tangentAngle += 2 * pi;
    
    // CRITICAL: Ensure wheels are always pointing downward
    // If the truck would be upside down (wheels up), flip it 180 degrees
    if (tangentAngle > pi/2 && tangentAngle < 3*pi/2) {
      tangentAngle += pi; // Flip 180 degrees to keep wheels down
      tangentAngle = tangentAngle % (2 * pi);
    }
    
    // Apply rotation
    angle = tangentAngle;
  }
  
  void increaseSpeed() {
    speed = (speed + 0.2).clamp(minSpeed, maxSpeed);
  }
  
  void decreaseSpeed() {
    speed = (speed - 0.2).clamp(minSpeed, maxSpeed);
  }
}