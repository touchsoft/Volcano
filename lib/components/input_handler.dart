import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../volcano_game.dart';
import 'truck.dart';

class InputHandler extends RectangleComponent with HasGameRef<VolcanoGame> {
  Vector2? _panStart;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Add gesture recognizers for better mobile support
    gameRef.gestureDetectors.add<PanGestureRecognizer>(
      PanGestureRecognizer.new,
      (recognizer) {
        recognizer.onStart = _onPanStart;
        recognizer.onUpdate = _onPanUpdate;
        recognizer.onEnd = _onPanEnd;
      },
    );
    
    gameRef.gestureDetectors.add<TapGestureRecognizer>(
      TapGestureRecognizer.new,
      (recognizer) {
        recognizer.onTapDown = _onTapDown;
      },
    );
  }
  
  void _onTapDown(TapDownDetails details) {
    if (gameRef.isGameOver) {
      gameRef.restartGame();
      return;
    }
    
    final tapPosition = details.localPosition;
    final centerX = gameRef.size.x / 2;
    
    if (tapPosition.dx < centerX) {
      gameRef.truck.direction = -1;  // Counter-clockwise
    } else {
      gameRef.truck.direction = 1;   // Clockwise
    }
    
    if (tapPosition.dy < gameRef.size.y / 2) {
      gameRef.truck.increaseSpeed();
    } else {
      gameRef.truck.decreaseSpeed();
    }
  }
  
  void _onPanStart(DragStartDetails details) {
    _panStart = Vector2(details.localPosition.dx, details.localPosition.dy);
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    // Not used for swipe detection
  }
  
  void _onPanEnd(DragEndDetails details) {
    if (_panStart == null || gameRef.isGameOver) return;
    
    final panEnd = Vector2(details.localPosition.dx, details.localPosition.dy);
    final deltaX = panEnd.x - _panStart!.x;
    final deltaY = panEnd.y - _panStart!.y;
    
    // Check if this was a horizontal swipe
    if (deltaX.abs() > 50 && deltaX.abs() > deltaY.abs()) {
      if (deltaX > 0) {
        // Swipe right = counter-clockwise (left direction)
        gameRef.truck.direction = -1;
      } else {
        // Swipe left = clockwise (right direction)
        gameRef.truck.direction = 1;
      }
    }
    
    _panStart = null;
  }
}