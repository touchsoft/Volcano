import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../volcano_game.dart';
import 'truck.dart';

class Rock extends SpriteComponent with CollisionCallbacks {
  final bool isGrey;
  final double gameWidth;
  final double gameHeight;
  
  late Vector2 velocity;
  late Vector2 startPosition;
  final double gravity = 300.0;
  bool hasCollided = false;
  
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
    size = Vector2(16, 16);
    anchor = Anchor.center;
    
    add(RectangleHitbox());
    
    position = startPosition.clone();
    
    _calculateTrajectory();
  }
  
  void _calculateTrajectory() {
    final random = Random();
    
    final angle = random.nextDouble() * 2 * pi;
    final targetRadius = 0.7 + random.nextDouble() * 0.6; // Random point on or near the oval
    
    final targetX = gameWidth / 2 + ovalWidth * targetRadius * cos(angle);
    final targetY = gameHeight / 2 + ovalHeight * targetRadius * sin(angle);
    
    final distance = Vector2(targetX - position.x, targetY - position.y);
    
    final initialSpeed = 150.0 + random.nextDouble() * 100.0;
    final timeOfFlight = 1.5 + random.nextDouble() * 1.0;
    
    velocity = Vector2(
      distance.x / timeOfFlight,
      distance.y / timeOfFlight - 0.5 * gravity * timeOfFlight,
    );
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (hasCollided) return;
    
    position += velocity * dt;
    velocity.y += gravity * dt;
    
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
      game.collectRock(isGrey);
      
      removeFromParent();
      return false;
    }
    return true;
  }
}