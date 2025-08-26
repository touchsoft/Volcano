import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../volcano_game.dart';

class ControlBar extends RectangleComponent with DragCallbacks, HasGameRef<VolcanoGame> {
  late RectangleComponent handle;
  late RectangleComponent track;
  
  double handlePosition = 0.0; // -1.0 to 1.0, 0 is center
  bool isDragging = false;
  final double trackWidth = 200.0;
  final double trackHeight = 20.0;
  final double handleWidth = 30.0;
  final double handleHeight = 30.0;
  
  @override
  Future<void> onLoad() async {
    size = Vector2(trackWidth + handleWidth, handleHeight + 10);
    position = Vector2(
      (gameRef.size.x - size.x) / 2,
      gameRef.size.y - size.y - 20,
    );
    paint.color = Colors.transparent;
    
    // Create track
    track = RectangleComponent(
      size: Vector2(trackWidth, trackHeight),
      position: Vector2(handleWidth / 2, (size.y - trackHeight) / 2),
      paint: Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );
    add(track);
    
    // Create handle
    handle = RectangleComponent(
      size: Vector2(handleWidth, handleHeight),
      position: Vector2(
        handleWidth / 2 + trackWidth / 2 - handleWidth / 2,
        (size.y - handleHeight) / 2,
      ),
      paint: Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.fill,
    );
    add(handle);
    
    // Round the corners
    track.paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    handle.paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Auto-return to center when not dragging
    if (!isDragging) {
      if (handlePosition.abs() > 0.01) {
        handlePosition *= 0.95; // Smooth return to center
        _updateHandlePosition();
        _updateTruckSpeed();
      }
    }
  }
  
  void _updateHandlePosition() {
    final centerX = handleWidth / 2 + trackWidth / 2 - handleWidth / 2;
    final maxOffset = trackWidth / 2 - handleWidth / 2;
    handle.position.x = centerX + (handlePosition * maxOffset);
  }
  
  void _updateTruckSpeed() {
    final truck = gameRef.truck;
    final speedMultiplier = handlePosition.abs() * 2.0;
    truck.speed = 0.5 + speedMultiplier; // Base speed + control (lower base speed)
    
    // Only change direction when there's significant movement
    if (handlePosition.abs() > 0.1) {
      truck.direction = handlePosition < 0 ? -1 : 1;
    }
    // When close to center, let truck continue in current direction but slow down
  }
  
  @override
  bool onDragStart(DragStartEvent event) {
    isDragging = true;
    return true;
  }
  
  @override
  bool onDragUpdate(DragUpdateEvent event) {
    final localX = event.localStartPosition.x + event.localDelta.x;
    final trackCenterX = handleWidth / 2 + trackWidth / 2;
    final maxOffset = trackWidth / 2 - handleWidth / 2;
    
    final offset = localX - trackCenterX;
    handlePosition = (offset / maxOffset).clamp(-1.0, 1.0);
    
    _updateHandlePosition();
    _updateTruckSpeed();
    
    return true;
  }
  
  @override
  bool onDragEnd(DragEndEvent event) {
    isDragging = false;
    return true;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw rounded track
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        track.position.x,
        track.position.y,
        track.size.x,
        track.size.y,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(trackRect, track.paint);
    
    // Draw rounded handle
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        handle.position.x,
        handle.position.y,
        handle.size.x,
        handle.size.y,
      ),
      const Radius.circular(15),
    );
    canvas.drawRRect(handleRect, handle.paint);
    
    // Draw center indicator
    final centerX = handleWidth / 2 + trackWidth / 2;
    final centerY = track.position.y + track.size.y / 2;
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(centerX, centerY), 3, centerPaint);
  }
}