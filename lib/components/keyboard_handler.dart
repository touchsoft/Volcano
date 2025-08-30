import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import '../volcano_game.dart';

class GameKeyboardHandler extends Component with HasGameRef<VolcanoGame> {
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Only handle keyboard input if truck is controlled
    if (!gameRef.truck.isControlled) return;
    
    // Check for up arrow key
    if (RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      if (!_pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
        gameRef.truck.startAccelerating();
        _pressedKeys.add(LogicalKeyboardKey.arrowUp);
      }
    } else {
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
        gameRef.truck.stopAccelerating();
        _pressedKeys.remove(LogicalKeyboardKey.arrowUp);
      }
    }
  }
}