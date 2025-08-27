import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ParticleExplosion extends Component {
  final Vector2 position;
  final List<Color> colors;
  final List<Particle> particles = [];
  final int particleCount;
  final double speedMultiplier;
  final double sizeMultiplier;
  double lifetime = 0.0;
  final double maxLifetime = 1.0;
  
  ParticleExplosion({
    required this.position,
    Color? color,
    List<Color>? colors,
    this.particleCount = 8,
    this.speedMultiplier = 1.0,
    this.sizeMultiplier = 1.0,
  }) : colors = colors ?? [color ?? Colors.white];
  
  @override
  Future<void> onLoad() async {
    final random = Random();
    
    // Set explosion to very high priority to be in front of everything
    priority = 1000;
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi;
      final speed = (50 + random.nextDouble() * 50) * speedMultiplier;
      
      // Pick a random color from the available colors
      final particleColor = colors[random.nextInt(colors.length)];
      
      particles.add(Particle(
        position: position.clone(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        color: particleColor,
        size: (2 + random.nextDouble() * 3) * sizeMultiplier,
      ));
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    lifetime += dt;
    
    for (final particle in particles) {
      particle.update(dt);
    }
    
    if (lifetime >= maxLifetime) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    final opacity = (1.0 - (lifetime / maxLifetime)).clamp(0.0, 1.0);
    
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.position.x, particle.position.y),
        particle.size,
        paint,
      );
    }
  }
}

class Particle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double size;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
  });
  
  void update(double dt) {
    position += velocity * dt;
    velocity.y += 100 * dt; // Gravity effect
    velocity *= 0.98; // Friction
  }
}