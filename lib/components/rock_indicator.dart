import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../volcano_game.dart';

class RockIndicator extends PositionComponent with HasGameRef<VolcanoGame> {
  late List<SpriteComponent> rockSlots;
  int currentRocks = 0;
  int maxRocks = 3;
  final Set<int> animatingSlots = <int>{}; // Track which slots are being animated to
  
  static const double rockSize = 24.0;
  static const double spacing = 8.0;
  
  @override
  Future<void> onLoad() async {
    position = Vector2(20, 55); // Below health bar
    
    rockSlots = [];
    
    // Create rock slots
    for (int i = 0; i < maxRocks; i++) {
      final rockSlot = SpriteComponent(
        sprite: Sprite(gameRef.images.fromCache('rock-grey.png')),
        size: Vector2(rockSize, rockSize),
        position: Vector2(i * (rockSize + spacing), 0),
        anchor: Anchor.topLeft,
      );
      
      // Start with faint/empty appearance
      rockSlot.opacity = 0.2;
      add(rockSlot);
      rockSlots.add(rockSlot);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    final newMaxRocks = gameRef.rocksNeededForBridge;
    
    // Update max rocks if changed (level progression)
    if (newMaxRocks != maxRocks) {
      _updateMaxRocks(newMaxRocks);
      maxRocks = newMaxRocks;
    }
    
    // Don't automatically update rock display - let animations handle it
    currentRocks = gameRef.greyRocksCollected;
  }
  
  void _updateMaxRocks(int newMax) {
    // Remove excess slots
    while (rockSlots.length > newMax) {
      final slot = rockSlots.removeLast();
      slot.removeFromParent();
    }
    
    // Add new slots if needed
    while (rockSlots.length < newMax) {
      final index = rockSlots.length;
      final rockSlot = SpriteComponent(
        sprite: Sprite(gameRef.images.fromCache('rock-grey.png')),
        size: Vector2(rockSize, rockSize),
        position: Vector2(index * (rockSize + spacing), 0),
        anchor: Anchor.topLeft,
      );
      rockSlot.opacity = 0.2;
      add(rockSlot);
      rockSlots.add(rockSlot);
    }
  }
  
  void _updateRockDisplay(int rocksCollected) {
    for (int i = 0; i < rockSlots.length; i++) {
      if (i < rocksCollected) {
        rockSlots[i].opacity = 1.0; // Filled
      } else {
        rockSlots[i].opacity = 0.2; // Empty/faint
      }
    }
  }
  
  void triggerRockCollectionAnimation(int ignoredIndex, VoidCallback onCounterIncrement) {
    // Find the first empty slot that's not currently being animated to
    int targetSlot = -1;
    for (int i = 0; i < rockSlots.length; i++) {
      if (rockSlots[i].opacity < 0.5 && !animatingSlots.contains(i)) {
        targetSlot = i;
        break;
      }
    }
    
    if (targetSlot != -1) {
      final slot = rockSlots[targetSlot];
      
      // Mark this slot as being animated to
      animatingSlots.add(targetSlot);
      
      // Create jumping animation
      final jumpAnimation = RockJumpAnimation(
        startPosition: gameRef.truck.position.clone(),
        endPosition: position + slot.position + Vector2(rockSize/2, rockSize/2),
        onComplete: () {
          slot.opacity = 1.0; // Fill the slot
          animatingSlots.remove(targetSlot); // Remove from animating set
          onCounterIncrement(); // Increment the counter after animation
        },
      );
      
      gameRef.add(jumpAnimation);
    }
  }
  
  void resetForNewLevel() {
    // Reset all slots to empty/faint state
    for (final slot in rockSlots) {
      slot.opacity = 0.2;
    }
    currentRocks = 0;
    animatingSlots.clear(); // Clear any pending animations
  }
}

class RockJumpAnimation extends Component {
  final Vector2 startPosition;
  final Vector2 endPosition;
  final VoidCallback onComplete;
  
  late SpriteComponent animatedRock;
  double animationTimer = 0.0;
  static const double animationDuration = 0.8;
  
  RockJumpAnimation({
    required this.startPosition,
    required this.endPosition,
    required this.onComplete,
  });
  
  @override
  Future<void> onLoad() async {
    final game = findGame()! as VolcanoGame;
    
    animatedRock = SpriteComponent(
      sprite: Sprite(game.images.fromCache('rock-grey.png')),
      size: Vector2(16, 16), // Smaller than indicator rocks
      position: startPosition.clone(),
      anchor: Anchor.center,
    );
    animatedRock.priority = 500; // High priority to show above other elements
    add(animatedRock);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    animationTimer += dt;
    final progress = (animationTimer / animationDuration).clamp(0.0, 1.0);
    
    if (progress >= 1.0) {
      onComplete();
      removeFromParent();
      return;
    }
    
    // Parabolic trajectory
    final linearX = startPosition.x + (endPosition.x - startPosition.x) * progress;
    final linearY = startPosition.y + (endPosition.y - startPosition.y) * progress;
    
    // Add arc (jump height)
    final arcHeight = 60.0 * sin(progress * pi);
    
    animatedRock.position = Vector2(linearX, linearY - arcHeight);
    
    // Scale effect - grow then shrink
    final scaleEffect = progress < 0.5 
        ? 1.0 + (progress * 0.4) // Grow in first half
        : 1.2 - ((progress - 0.5) * 0.4); // Shrink in second half
    animatedRock.scale = Vector2.all(scaleEffect);
    
    // Fade out near the end
    if (progress > 0.8) {
      final fadeProgress = (progress - 0.8) / 0.2;
      animatedRock.opacity = 1.0 - fadeProgress;
    }
  }
}