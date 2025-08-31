import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../volcano_game.dart';
import 'truck.dart';
import 'particle_explosion.dart';

enum RockSize { small, medium, large, xlarge, xxlarge }

class Rock extends SpriteComponent with CollisionCallbacks {
  final bool isGrey;
  final double gameWidth;
  final double gameHeight;
  final RockSize rockSize;
  final double damagePercent;
  
  late Vector2 velocity;
  late Vector2 startPosition;
  final double gravity = 300.0;
  bool hasCollided = false;
  late double targetX;
  late double targetY;
  bool isBehindVolcano = false;
  late double startTime;
  late double flightDuration;
  
  // Special red rock mechanics
  bool isSpecialRed = false;
  bool hasLanded = false;
  double landTime = 0.0;
  late double initialSize;
  
  // Explosive red rock mechanics
  bool isExplosiveRed = false;
  bool hasExploded = false;
  double explosionTimer = 0.0;
  
  static const double ovalWidth = 140.0;
  static const double ovalHeight = 80.0;
  
  final double speedMultiplier;
  
  Rock({
    required this.isGrey,
    required Vector2 startPosition,
    required this.gameWidth,
    required this.gameHeight,
    this.rockSize = RockSize.medium,
    this.damagePercent = 0.0,
    this.speedMultiplier = 1.0,
  }) : this.startPosition = startPosition;
  
  @override
  Future<void> onLoad() async {
    final game = findGame()! as VolcanoGame;
    sprite = Sprite(game.images.fromCache(isGrey ? 'rock-grey.png' : 'rock-red.png'));
    
    // Set size based on rock size enum
    final baseSize = 20.0;
    double sizeMultiplier;
    switch (rockSize) {
      case RockSize.small:
        sizeMultiplier = 2.0 / 3.0; // 2/3 size (about 13.3px)
        break;
      case RockSize.medium:
        sizeMultiplier = 1.0; // Same size (20px)
        break;
      case RockSize.large:
        sizeMultiplier = 1.33; // 1.33x size (about 26.6px)
        break;
      case RockSize.xlarge:
        sizeMultiplier = 1.66; // 1.66x size (about 33.2px)
        break;
      case RockSize.xxlarge:
        sizeMultiplier = 2.0; // 2x size (40px) - explosive rock
        break;
    }
    
    final rockSizeValue = baseSize * sizeMultiplier;
    size = Vector2(rockSizeValue, rockSizeValue);
    initialSize = rockSizeValue;
    anchor = Anchor.center;
    
    add(RectangleHitbox());
    
    position = startPosition.clone();
    startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    final random = Random();
    
    // XXLarge rocks are always explosive red rocks
    if (rockSize == RockSize.xxlarge) {
      isExplosiveRed = true;
      explosionTimer = 1.0 + random.nextDouble(); // Explode after 1-2 seconds in flight
    } else if (!isGrey && random.nextInt(5) == 0) {
      // 1 in 5 red rocks are special (don't explode on landing, stay for a while)
      isSpecialRed = true;
    }
    
    _calculateTrajectory();
  }
  
  void _calculateTrajectory() {
    final random = Random();
    
    // Target should be on the island edge (truck path area)
    // Use angles that avoid the very top of the screen: 30° to 330° (avoiding 330°-30°)
    final angle = random.nextDouble() * (5 * pi / 3) + pi / 6; // 30° to 330°
    
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
    
    final baseInitialSpeed = 150.0 + random.nextDouble() * 100.0;
    final initialSpeed = baseInitialSpeed * speedMultiplier;
    final baseDuration = 1.5 + random.nextDouble() * 1.0;
    flightDuration = baseDuration / speedMultiplier; // Faster rocks have shorter flight time
    
    velocity = Vector2(
      distance.x / flightDuration,
      distance.y / flightDuration - 0.5 * gravity * flightDuration,
    );
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (hasCollided) return;
    
    // Special red rocks that have landed should not move or spin
    if (hasLanded && isSpecialRed) {
      // Do nothing - rock stays in place
    } else {
      // Normal physics for flying rocks
      position += velocity * dt;
      velocity.y += gravity * dt;
      
      // Spin the rock on its center axis during flight
      angle += 3.0 * dt; // 3 radians per second spin
    }
    
    // Calculate flight progress (0.0 = just launched, 1.0 = about to land)
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final elapsedTime = currentTime - startTime;
    final flightProgress = (elapsedTime / flightDuration).clamp(0.0, 1.0);
    
    // Handle explosive red rock mid-flight explosion
    if (isExplosiveRed && !hasExploded) {
      explosionTimer -= dt;
      if (explosionTimer <= 0) {
        _explodeInFlight();
        return; // Exit early after explosion
      }
    }
    
    // All rocks are in front of volcano and get larger during flight  
    final targetScale = 1.4; // End up quite large
    final currentScale = 1.0 + (flightProgress * (targetScale - 1.0));
    scale = Vector2.all(currentScale);
    opacity = 1.0;
    
    // Check if rock hits the island ground (truck path level on the thick blue line)  
    final centerX = gameWidth / 2;
    final centerY = gameHeight / 2;
    final truckPathY = centerY + ovalHeight * 0.8; // Ground level of truck path (thick blue line)
    
    if (position.y >= truckPathY && !hasLanded) {
      if (isSpecialRed) {
        // Special red rock lands but doesn't explode immediately
        hasLanded = true;
        landTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
        velocity = Vector2.zero(); // Stop moving
        position.y = truckPathY; // Lock to ground level
        angle = 0; // Stop spinning
      } else {
        // Normal rock explodes on impact
        final game = findGame()! as VolcanoGame;
        final explosion = ParticleExplosion(
          position: position.clone(),
          color: isGrey ? Colors.grey : Colors.red,
        );
        game.add(explosion);
        
        // Play random crash sound
        game.playRandomCrashSound();
        
        hasCollided = true;
        removeFromParent();
        return;
      }
    }
    
    // Handle special red rock growth and delayed explosion
    if (hasLanded && isSpecialRed) {
      final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final timeSinceLanding = currentTime - landTime;
      
      if (timeSinceLanding < 2.0) {
        // Grow over 2 seconds
        final growthProgress = timeSinceLanding / 2.0;
        final currentSize = initialSize + (initialSize * growthProgress); // Double in size
        size = Vector2.all(currentSize);
      } else {
        // After 2 seconds, explode
        final game = findGame()! as VolcanoGame;
        final explosion = ParticleExplosion(
          position: position.clone(),
          color: Colors.red,
        );
        game.add(explosion);
        
        // Play random crash sound
        game.playRandomCrashSound();
        
        hasCollided = true;
        removeFromParent();
        return;
      }
    }
    
    if (position.y > gameHeight + 50 || 
        position.x < -50 || 
        position.x > gameWidth + 50) {
      removeFromParent();
    }
  }
  
  void _explodeInFlight() {
    hasExploded = true;
    final game = findGame()! as VolcanoGame;
    
    // Create big explosion for the main rock
    final explosion = ParticleExplosion(
      position: position.clone(),
      colors: [Colors.red, Colors.orange, Colors.yellow, Colors.black],
      particleCount: 40,
      speedMultiplier: 2.5,
      sizeMultiplier: 2.0,
    );
    game.add(explosion);
    
    // Play crash sound
    game.playRandomCrashSound();
    
    // Spawn 4 smaller red rocks in different directions
    final random = Random();
    for (int i = 0; i < 4; i++) {
      final angle = (i * pi / 2) + random.nextDouble() * 0.5; // Spread them out
      final distance = 30.0 + random.nextDouble() * 20.0; // 30-50 pixel spread
      
      final smallRockPosition = position + Vector2(
        cos(angle) * distance,
        sin(angle) * distance,
      );
      
      final smallRock = Rock(
        isGrey: false,
        startPosition: smallRockPosition,
        gameWidth: gameWidth,
        gameHeight: gameHeight,
        rockSize: RockSize.small,
        damagePercent: 0.15, // Less damage than normal rocks
        speedMultiplier: 0.8, // Slower than normal rocks
      );
      
      game.add(smallRock);
    }
    
    // Remove the main explosive rock
    removeFromParent();
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
          colors: [Colors.red, Colors.red, Colors.red, Colors.red, Colors.orange, Colors.black], // Predominantly red
          particleCount: 25, // More particles
          speedMultiplier: 2.0, // Faster particles
          sizeMultiplier: 1.5, // Smaller particles
        );
        game.add(explosion);
      }
      
      // Play random crash sound for truck collisions
      game.playRandomCrashSound();
      
      // Special red rocks that have landed still cause life loss when hit
      if (isSpecialRed && hasLanded) {
        // Instant explosion for landed special red rock
        final bigExplosion = ParticleExplosion(
          position: position.clone(),
          colors: [Colors.red, Colors.red, Colors.red, Colors.red, Colors.red, Colors.orange, Colors.black, Colors.yellow], // Predominantly red
          particleCount: 35, // Even more particles for landed rock
          speedMultiplier: 3.0, // Faster explosion
          sizeMultiplier: 1.8, // Smaller particles but more of them
        );
        game.add(bigExplosion);
      }
      
      game.collectRock(isGrey, damagePercent: damagePercent);
      
      removeFromParent();
      return false;
    }
    return true;
  }
}