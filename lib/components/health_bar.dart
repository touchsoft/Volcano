import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../volcano_game.dart';

class HealthBar extends PositionComponent with HasGameRef<VolcanoGame> {
  static const double barWidth = 200.0;
  static const double barHeight = 20.0;
  static const double borderWidth = 2.0;
  
  late RectangleComponent background;
  late RectangleComponent healthFill;
  late RectangleComponent border;
  
  int maxHealth = 3;
  int currentHealth = 3;
  
  @override
  Future<void> onLoad() async {
    position = Vector2(20, 20);
    
    // Background (dark)
    background = RectangleComponent(
      size: Vector2(barWidth, barHeight),
      paint: Paint()..color = const Color(0xFF333333),
    );
    add(background);
    
    // Health fill (starts green)
    healthFill = RectangleComponent(
      size: Vector2(barWidth, barHeight),
      paint: Paint()..color = Colors.green,
    );
    add(healthFill);
    
    // Border
    border = RectangleComponent(
      size: Vector2(barWidth, barHeight),
      paint: Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
    add(border);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // During health bonus, show the bonus health draining
    // After bonus, show actual health (which should be 0)
    final healthPercent = gameRef.isHealthBonus 
        ? gameRef.healthForBonus.clamp(0.0, 1.0)
        : gameRef.health.clamp(0.0, 1.0);
    
    // Update fill width
    healthFill.size.x = barWidth * healthPercent;
    
    // Update color based on health
    Color fillColor;
    
    // Use normal health colors during bonus animation, black when health is 0
    if (healthPercent <= 0.0 && !gameRef.isHealthBonus) {
      fillColor = Colors.black; // Black when health is 0 and not animating
    } else if (healthPercent > 0.75) {
      fillColor = Colors.green; // Full health
    } else if (healthPercent > 0.50) {
      fillColor = Colors.orange; // Good health
    } else if (healthPercent > 0.25) {
      fillColor = Colors.deepOrange; // Medium health
    } else if (healthPercent > 0.0) {
      fillColor = Colors.red; // Low health
    } else {
      fillColor = Colors.transparent; // No health
    }
    
    healthFill.paint.color = fillColor;
    
    // Add flashing effect when very low health
    if (healthPercent <= 0.25 && healthPercent > 0) {
      final flashIntensity = (sin(dt * 10) * 0.3 + 0.7).clamp(0.4, 1.0);
      healthFill.paint.color = fillColor.withOpacity(flashIntensity);
    }
  }
}