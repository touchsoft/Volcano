import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class VolcanoLava extends Component {
  final Vector2 volcanoPosition;
  final List<LavaParticle> lavaParticles = [];
  final Random random = Random();
  double spawnTimer = 0.0;
  final double spawnInterval = 0.05; // Spawn lava every 0.05 seconds
  
  VolcanoLava({required this.volcanoPosition});
  
  @override
  Future<void> onLoad() async {
    // Set priority so lava appears behind smoke but in front of volcano
    priority = 600;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    spawnTimer += dt;
    
    // Spawn new lava particles
    if (spawnTimer >= spawnInterval) {
      _spawnLavaParticle();
      spawnTimer = 0.0;
    }
    
    // Update existing particles
    lavaParticles.removeWhere((particle) {
      particle.update(dt);
      return particle.isDead;
    });
  }
  
  void _spawnLavaParticle() {
    final particle = LavaParticle(
      position: volcanoPosition.clone() + Vector2(
        (random.nextDouble() - 0.5) * 30, // Small random offset from volcano mouth
        -75, // Start at volcano mouth center
      ),
      velocity: Vector2(
        (random.nextDouble() - 0.5) * 80, // Strong horizontal spread
        -40 - random.nextDouble() * 60, // Strong upward movement
      ),
    );
    lavaParticles.add(particle);
  }
  
  @override
  void render(Canvas canvas) {
    for (final particle in lavaParticles) {
      particle.render(canvas);
    }
  }
}

class LavaParticle {
  Vector2 position;
  Vector2 velocity;
  double size;
  double opacity;
  double lifetime;
  double maxLifetime;
  bool isDead = false;
  Color color;
  
  LavaParticle({
    required this.position,
    required this.velocity,
  }) : size = 3 + Random().nextDouble() * 6, // 3-9 pixels (smaller than smoke)
       opacity = 0.8 + Random().nextDouble() * 0.2, // 0.8-1.0 opacity (bright)
       lifetime = 0.0,
       maxLifetime = 0.8 + Random().nextDouble() * 1.2, // 0.8-2.0 second lifetime (shorter than smoke)
       color = _getRandomLavaColor();
  
  static Color _getRandomLavaColor() {
    final random = Random();
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Color(0xFFFF4500), // OrangeRed
      Color(0xFFFF6347), // Tomato
    ];
    return colors[random.nextInt(colors.length)];
  }
  
  void update(double dt) {
    lifetime += dt;
    
    // Move the particle
    position += velocity * dt;
    
    // Strong gravity for lava
    velocity.y += 200 * dt; // Stronger gravity than smoke
    
    // Air resistance
    velocity *= 0.95;
    
    // Fade out over time
    final fadeProgress = lifetime / maxLifetime;
    opacity = (1.0 - fadeProgress) * 0.9;
    
    // Die when lifetime exceeded or fully faded
    if (lifetime >= maxLifetime || opacity <= 0.0) {
      isDead = true;
    }
  }
  
  void render(Canvas canvas) {
    if (isDead) return;
    
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    // Draw glowing lava particle
    canvas.drawCircle(
      Offset(position.x, position.y),
      size,
      paint,
    );
    
    // Add glow effect
    final glowPaint = Paint()
      ..color = Colors.yellow.withOpacity(opacity * 0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(position.x, position.y),
      size * 1.5,
      glowPaint,
    );
  }
}