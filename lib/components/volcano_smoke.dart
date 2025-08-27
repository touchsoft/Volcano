import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class VolcanoSmoke extends Component {
  final Vector2 volcanoPosition;
  final List<SmokeParticle> smokeParticles = [];
  final Random random = Random();
  double spawnTimer = 0.0;
  final double spawnInterval = 0.1; // Spawn new smoke every 0.1 seconds
  
  VolcanoSmoke({required this.volcanoPosition});
  
  @override
  Future<void> onLoad() async {
    // Set high priority so smoke appears in front of volcano but behind explosions
    priority = 500;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    spawnTimer += dt;
    
    // Spawn new smoke particles
    if (spawnTimer >= spawnInterval) {
      _spawnSmokeParticle();
      spawnTimer = 0.0;
    }
    
    // Update existing particles
    smokeParticles.removeWhere((particle) {
      particle.update(dt);
      return particle.isDead;
    });
  }
  
  void _spawnSmokeParticle() {
    final particle = SmokeParticle(
      position: volcanoPosition.clone() + Vector2(
        (random.nextDouble() - 0.5) * 60, // Much wider spread from volcano mouth
        -75, // Start at volcano mouth center
      ),
      velocity: Vector2(
        (random.nextDouble() - 0.5) * 50, // More horizontal drift for spread
        -15 - random.nextDouble() * 25, // Upward movement
      ),
    );
    smokeParticles.add(particle);
  }
  
  @override
  void render(Canvas canvas) {
    for (final particle in smokeParticles) {
      particle.render(canvas);
    }
  }
}

class SmokeParticle {
  Vector2 position;
  Vector2 velocity;
  double size;
  double opacity;
  double lifetime;
  double maxLifetime;
  bool isDead = false;
  
  SmokeParticle({
    required this.position,
    required this.velocity,
  }) : size = 8 + Random().nextDouble() * 12, // 8-20 pixels
       opacity = 0.2 + Random().nextDouble() * 0.2, // 0.2-0.4 opacity (much more transparent)
       lifetime = 0.0,
       maxLifetime = 2.0 + Random().nextDouble() * 2.0; // 2-4 second lifetime
  
  void update(double dt) {
    lifetime += dt;
    
    // Move the particle
    position += velocity * dt;
    
    // Slow down over time (wind resistance)
    velocity *= 0.98;
    
    // Grow larger over time
    size += 15 * dt; // Grow 15 pixels per second
    
    // Fade out over time
    final fadeProgress = lifetime / maxLifetime;
    opacity = (1.0 - fadeProgress) * 0.3; // Even more transparent during fade
    
    // Die when lifetime exceeded or fully faded
    if (lifetime >= maxLifetime || opacity <= 0.0) {
      isDead = true;
    }
  }
  
  void render(Canvas canvas) {
    if (isDead) return;
    
    // Create gradient for smoke effect (almost white smoke)
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    // Draw multiple circles with decreasing opacity for soft smoke effect
    for (int i = 3; i > 0; i--) {
      final layerSize = size * (i / 3.0);
      final layerOpacity = opacity * (0.3 * i);
      paint.color = Colors.white.withOpacity(layerOpacity);
      
      canvas.drawCircle(
        Offset(position.x, position.y),
        layerSize,
        paint,
      );
    }
  }
}