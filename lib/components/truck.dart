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
  bool isControlled = true; // Whether player controls are active
  
  static const double minSpeed = 0.5;
  static const double maxSpeed = 3.0;
  static const double ovalWidth = 160.0;  // Half width of the blue oval path (slightly reduced)
  static const double ovalHeight = 50.0;  // Half height of the blue oval path (further reduced)
  static const double minScale = 0.6;     // Smallest size when at top
  static const double maxScale = 0.9;     // Largest size when at bottom
  
  Truck({required this.gameWidth, required this.gameHeight});
  
  @override
  Future<void> onLoad() async {
    sprite = Sprite((findGame()! as VolcanoGame).images.fromCache('truck-0.png'));
    size = Vector2(72, 54); // 50% bigger (48*1.5, 36*1.5)
    anchor = Anchor.center;
    
    add(RectangleHitbox());
    
    _updatePosition();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Only follow oval path if controlled by player
    if (isControlled) {
      final previousPathAngle = pathAngle;
      pathAngle += speed * direction * dt;
      
      if (pathAngle > 2 * pi) pathAngle -= 2 * pi;
      if (pathAngle < 0) pathAngle += 2 * pi;
      
      _updatePosition();
      _updateRotation(previousPathAngle);
      
      // Debug: Let's see what angle we actually have
      final debugAngle = (angle * 180 / pi) % 360;
      
      _updateSprite();
      
      // Don't apply angle rotation - sprites are already pre-rotated
      angle = 0;
    }
    // When not controlled, position is managed by the game's bridge sequence
  }
  
  void _updatePosition() {
    final centerX = gameWidth / 2;
    final centerY = gameHeight / 2 + 40; // Move center point down a bit more
    
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
    
    // No wheel-down logic needed - sprites are pre-rotated with wheels always down
    
    // Apply rotation
    angle = tangentAngle;
  }
  
  void increaseSpeed() {
    speed = (speed + 0.2).clamp(minSpeed, maxSpeed);
  }
  
  void decreaseSpeed() {
    speed = (speed - 0.2).clamp(minSpeed, maxSpeed);
  }
  
  void updateSpriteForAngle() {
    _updateSprite();
  }
  
  void _updateSprite() {
    final game = findGame()! as VolcanoGame;
    
    // Convert current angle to degrees and normalize to 0-360
    double angleDegrees = (angle * 180 / pi) % 360;
    if (angleDegrees < 0) angleDegrees += 360;
    
    // Map movement direction to correct truck sprite:
    // truck-0: moving UP, truck-90: moving RIGHT, truck-180: moving DOWN, truck-270: moving LEFT
    String spriteFile;
    
    // Debug: Let's ensure right-to-left uses truck-270
    if (angleDegrees >= 337.5 || angleDegrees < 22.5) {
      spriteFile = 'truck-90.png';    // Moving right (0°) -> truck-90 ✓
    } else if (angleDegrees >= 22.5 && angleDegrees < 67.5) {
      spriteFile = 'truck-135.png';   // Moving down-right -> truck-135
    } else if (angleDegrees >= 67.5 && angleDegrees < 112.5) {
      spriteFile = 'truck-180.png';   // Moving down (90°) -> truck-180
    } else if (angleDegrees >= 112.5 && angleDegrees < 157.5) {
      spriteFile = 'truck-225.png';   // Moving down-left -> truck-225
    } else if (angleDegrees >= 157.5 && angleDegrees < 202.5) {
      spriteFile = 'truck-270.png';   // Moving LEFT (180°) -> truck-270 ✓
    } else if (angleDegrees >= 202.5 && angleDegrees < 247.5) {
      spriteFile = 'truck-315.png';   // Moving up-left -> truck-315
    } else if (angleDegrees >= 247.5 && angleDegrees < 292.5) {
      spriteFile = 'truck-0.png';     // Moving up (270°) -> truck-0
    } else {
      spriteFile = 'truck-45.png';    // Moving up-right -> truck-45
    }
    
    sprite = Sprite(game.images.fromCache(spriteFile));
  }
}