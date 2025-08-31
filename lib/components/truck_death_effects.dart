import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TruckDeathEffects extends Component {
  final PositionComponent truck;
  final List<FlameParticle> flames = [];
  final List<SmokeParticle> smoke = [];
  final Random random = Random();
  double spawnTimer = 0.0;
  final double spawnInterval = 0.08; // Spawn particles faster than volcano
  
  TruckDeathEffects({required this.truck});
  
  @override
  Future<void> onLoad() async {
    priority = 600; // Above volcano smoke but below UI
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    spawnTimer += dt;
    
    // Spawn new particles
    if (spawnTimer >= spawnInterval) {
      _spawnFlameParticle();
      _spawnSmokeParticle();
      spawnTimer = 0.0;
    }
    
    // Update flames
    flames.removeWhere((particle) {
      particle.update(dt);
      return particle.isDead;
    });
    
    // Update smoke
    smoke.removeWhere((particle) {
      particle.update(dt);
      return particle.isDead;
    });
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Render flames
    for (final flame in flames) {
      flame.render(canvas);
    }
    
    // Render smoke
    for (final smokeParticle in smoke) {
      smokeParticle.render(canvas);
    }
  }
  
  void _spawnFlameParticle() {
    final particle = FlameParticle(
      position: truck.position.clone() + Vector2(
        (random.nextDouble() - 0.5) * 40, // Spread around truck
        random.nextDouble() * 10, // Slightly above truck
      ),
      velocity: Vector2(
        (random.nextDouble() - 0.5) * 30, // Random horizontal movement
        -50 - random.nextDouble() * 30, // Strong upward movement
      ),
    );
    flames.add(particle);
  }
  
  void _spawnSmokeParticle() {
    final particle = SmokeParticle(
      position: truck.position.clone() + Vector2(
        (random.nextDouble() - 0.5) * 50, // Wider spread than flames
        -10 + random.nextDouble() * 20, // Around truck level
      ),
      velocity: Vector2(
        (random.nextDouble() - 0.5) * 25, // Horizontal drift
        -20 - random.nextDouble() * 40, // Upward movement
      ),
    );
    smoke.add(particle);
  }
}

class FlameParticle {
  Vector2 position;
  Vector2 velocity;
  double life = 1.0;
  double maxLife = 1.0;
  bool isDead = false;
  late double initialSize;
  
  FlameParticle({required this.position, required this.velocity}) {
    final random = Random();
    maxLife = 0.3 + random.nextDouble() * 0.4; // 0.3 to 0.7 seconds
    life = maxLife;
    initialSize = 8.0 + random.nextDouble() * 8.0; // 8 to 16 pixels
  }
  
  void update(double dt) {
    life -= dt;
    
    if (life <= 0) {
      isDead = true;
      return;
    }
    
    // Update position
    position += velocity * dt;
    
    // Add some flicker to flame movement
    final random = Random();
    velocity += Vector2(
      (random.nextDouble() - 0.5) * 100 * dt, // Random horizontal flicker
      0,
    );
    
    // Flames rise and slow down
    velocity.y *= 0.98;
  }
  
  void render(Canvas canvas) {
    if (isDead) return;
    
    final lifePercent = life / maxLife;
    final size = initialSize * (0.5 + lifePercent * 0.5); // Shrink as it dies
    
    // Flame colors: bright orange/red to dark red
    Color color;
    if (lifePercent > 0.7) {
      color = Color.lerp(Colors.yellow, Colors.orange, 1 - lifePercent)!;
    } else if (lifePercent > 0.3) {
      color = Color.lerp(Colors.orange, Colors.red, 1 - lifePercent)!;
    } else {
      color = Color.lerp(Colors.red, Colors.brown, 1 - lifePercent)!;
    }
    
    color = color.withOpacity(lifePercent);
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(position.x, position.y), size, paint);
  }
}

class SmokeParticle {
  Vector2 position;
  Vector2 velocity;
  double life = 1.0;
  double maxLife = 1.0;
  bool isDead = false;
  late double initialSize;
  
  SmokeParticle({required this.position, required this.velocity}) {
    final random = Random();
    maxLife = 1.0 + random.nextDouble() * 1.5; // 1 to 2.5 seconds
    life = maxLife;
    initialSize = 6.0 + random.nextDouble() * 12.0; // 6 to 18 pixels
  }
  
  void update(double dt) {
    life -= dt;
    
    if (life <= 0) {
      isDead = true;
      return;
    }
    
    // Update position
    position += velocity * dt;
    
    // Smoke expands and slows down as it rises
    velocity *= 0.95;
  }
  
  void render(Canvas canvas) {
    if (isDead) return;
    
    final lifePercent = life / maxLife;
    final size = initialSize * (0.5 + (1 - lifePercent) * 1.5); // Grow as it ages
    
    // Smoke color: dark gray to light gray, fading out
    final grayValue = (100 + (1 - lifePercent) * 100).round().clamp(0, 255);
    final color = Color.fromARGB(
      (lifePercent * 180).round().clamp(0, 255), // Fade out alpha
      grayValue,
      grayValue,
      grayValue,
    );
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(position.x, position.y), size, paint);
  }
}