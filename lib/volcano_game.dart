import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'components/truck.dart';
import 'components/rock.dart';
import 'components/input_handler.dart';
import 'components/control_bar.dart';
import 'components/particle_explosion.dart';
import 'components/volcano_smoke.dart';
import 'components/volcano_lava.dart';

// Bridge animation phases
enum BridgePhase { driving_to_bridge, fading_islands, crossing_bridge, completed }

class VolcanoGame extends FlameGame with HasCollisionDetection {
  static const double gameWidth = 480.0;
  static const double gameHeight = 720.0;
  
  late Truck truck;
  late SpriteComponent island;
  late SpriteComponent volcano;
  late VolcanoSmoke volcanoSmoke;
  late VolcanoLava volcanoLava;
  
  double rockSpawnTimer = 0;
  double rockSpawnInterval = 5.0; // Start with 5 second pause between groups
  final Random random = Random();
  double gameTime = 0;
  int currentActiveRocks = 0;
  int maxRocks = 3; // Dynamic max rocks based on level
  
  // Group firing variables
  bool isFiringGroup = false;
  int rocksInCurrentGroup = 0;
  int totalRocksInGroup = 0;
  double groupFireTimer = 0;
  final double groupFireInterval = 0.3; // 0.3 seconds between rocks in group
  int completedCycles = 0;
  bool volcanoShaking = false;
  double shakeTimer = 0;
  Vector2 originalVolcanoPosition = Vector2.zero();
  
  bool gameOverShaking = false;
  double gameOverShakeTimer = 0;
  Vector2 originalCameraPosition = Vector2.zero();
  
  int lives = 3;
  int greyRocksCollected = 0;
  int rocksNeededForBridge = 3; // Dynamic rocks needed based on level
  
  bool isGameOver = false;
  bool isBridgeSequence = false;
  bool isLevelTransition = false;
  double bridgeAnimationTimer = 0.0;
  double levelTransitionTimer = 0.0;
  int currentLevel = 1;
  bool showingLevelText = false;
  
  BridgePhase bridgePhase = BridgePhase.driving_to_bridge;
  
  // Background music management
  bool rumblePlaying = false;
  
  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Handle island fade during bridge sequence
    if (isBridgeSequence && bridgePhase == BridgePhase.fading_islands) {
      final fadeProgress = (bridgeAnimationTimer / 1.0).clamp(0.0, 1.0);
      
      // Render island3 overlay with increasing opacity
      final island3Paint = Paint()..color = Colors.white.withOpacity(fadeProgress);
      final island3Sprite = Sprite(images.fromCache('island3.png'));
      island3Sprite.render(
        canvas, 
        size: Vector2(size.x, size.y),
        position: Vector2(size.x / 2, size.y / 2),
        anchor: Anchor.center,
        overridePaint: island3Paint,
      );
    }
    
    // Handle level transition fade effects
    if (isLevelTransition) {
      final fadeColor = Colors.black;
      
      if (!showingLevelText) {
        // Fade to black over 1 second
        final fadeProgress = (levelTransitionTimer / 1.0).clamp(0.0, 1.0);
        final fadePaint = Paint()..color = fadeColor.withOpacity(fadeProgress);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x, size.y),
          fadePaint,
        );
      } else {
        // Fade from black after showing level text
        final fadeProgress = (levelTransitionTimer / 1.0).clamp(0.0, 1.0);
        final fadePaint = Paint()..color = fadeColor.withOpacity(1.0 - fadeProgress);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x, size.y),
          fadePaint,
        );
      }
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    camera.viewfinder.visibleGameSize = Vector2(gameWidth, gameHeight);
    camera.viewfinder.position = Vector2(gameWidth / 2, gameHeight / 2);
    camera.viewfinder.anchor = Anchor.center;
    
    await _loadSprites();
    _setupGame();
  }
  
  Future<void> _loadSprites() async {
    await images.loadAll([
      'island2.png',
      'island3.png',
      'volcano2.png', 
      'truck-0.png',
      'truck-45.png',
      'truck-90.png',
      'truck-135.png',
      'truck-180.png',
      'truck-225.png',
      'truck-270.png',
      'truck-315.png',
      'rock-grey.png',
      'rock-red.png',
    ]);
    
    // Load sound effects
    await Future.wait([
      FlameAudio.audioCache.load('crash1.mp3'),
      FlameAudio.audioCache.load('crash2.mp3'),
      FlameAudio.audioCache.load('crash3.mp3'),
      FlameAudio.audioCache.load('crash4.mp3'),
      FlameAudio.audioCache.load('rumble.mp3'),
    ]);
    
    // Start background rumble music loop
    _startRumbleLoop();
  }
  
  void _setupGame() {
    island = SpriteComponent(
      sprite: Sprite(images.fromCache('island2.png')),
      size: Vector2(size.x, size.y), // Full screen size
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2),
    );
    island.priority = -10; // Always at back
    add(island);
    
    originalVolcanoPosition = Vector2(size.x / 2, size.y / 2 - 10);
    volcano = SpriteComponent(
      sprite: Sprite(images.fromCache('volcano2.png')),
      size: Vector2(150, 150),
      anchor: Anchor.center,
      position: originalVolcanoPosition.clone(),
    );
    volcano.priority = 10; // Always at front
    add(volcano);
    
    volcanoLava = VolcanoLava(volcanoPosition: originalVolcanoPosition.clone());
    add(volcanoLava);
    
    volcanoSmoke = VolcanoSmoke(volcanoPosition: originalVolcanoPosition.clone());
    add(volcanoSmoke);
    
    truck = Truck(gameWidth: size.x, gameHeight: size.y);
    add(truck);
    
    add(_GameHUD());
    add(_ControlsHUD());
    
    final inputHandler = InputHandler()
      ..size = Vector2(gameWidth, gameHeight)
      ..paint.color = const Color(0x00000000); // Transparent
    add(inputHandler);
    
    add(ControlBar());
    
    // Show initial level text
    add(_LevelText(currentLevel));
    
    // Set initial level difficulty
    maxRocks = 2 + currentLevel; // Level 1: 3 rocks, Level 2: 4 rocks, etc.
    rocksNeededForBridge = 2 + currentLevel; // Level 1: 3 needed, Level 2: 4 needed, etc.
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (isGameOver) return;
    
    // Handle level transition
    if (isLevelTransition) {
      _updateLevelTransition(dt);
      return;
    }
    
    // Handle bridge sequence
    if (isBridgeSequence) {
      _updateBridgeSequence(dt);
      return;
    }
    
    gameTime += dt;
    
    // Update current rock count
    currentActiveRocks = children.whereType<Rock>().length;
    
    // Handle group firing system
    if (isFiringGroup) {
      groupFireTimer += dt;
      if (groupFireTimer >= groupFireInterval && rocksInCurrentGroup < totalRocksInGroup) {
        _spawnRock();
        rocksInCurrentGroup++;
        groupFireTimer = 0;
        
        // If we've fired all rocks in the group, end the firing phase
        if (rocksInCurrentGroup >= totalRocksInGroup) {
          isFiringGroup = false;
          completedCycles++;
          // Reduce pause time by 0.1 seconds each cycle, min 1.5 seconds
          rockSpawnInterval = (5.0 - (completedCycles * 0.1)).clamp(1.5, 5.0);
          rockSpawnTimer = 0; // Reset timer for next pause
        }
      }
    } else {
      // Handle pause between groups
      rockSpawnTimer += dt;
      if (rockSpawnTimer >= rockSpawnInterval && currentActiveRocks < maxRocks) {
        // Start new group
        isFiringGroup = true;
        totalRocksInGroup = 3 + random.nextInt(3); // 3 to 5 rocks
        rocksInCurrentGroup = 0;
        groupFireTimer = 0;
        _startVolcanoShake();
      }
    }
    
    // Handle game over shaking
    if (gameOverShaking) {
      gameOverShakeTimer += dt;
      final shakeIntensity = 5.0; // Stronger shake for game over
      final shakeX = (random.nextDouble() - 0.5) * shakeIntensity;
      final shakeY = (random.nextDouble() - 0.5) * shakeIntensity;
      camera.viewfinder.position = Vector2(size.x / 2, size.y / 2) + Vector2(shakeX, shakeY);
      
      if (gameOverShakeTimer >= 1.0) { // Shake for 1 second
        gameOverShaking = false;
        gameOverShakeTimer = 0;
        camera.viewfinder.position = Vector2(size.x / 2, size.y / 2);
      }
    }
    
    // Handle volcano shaking (now only for group start)
    if (volcanoShaking) {
      shakeTimer += dt;
      final shakeIntensity = 2.0;
      final shakeX = (random.nextDouble() - 0.5) * shakeIntensity;
      final shakeY = (random.nextDouble() - 0.5) * shakeIntensity;
      volcano.position = originalVolcanoPosition + Vector2(shakeX, shakeY);
      
      if (shakeTimer >= 0.3) { // Shake for 0.3 seconds at start of group
        volcanoShaking = false;
        shakeTimer = 0;
        volcano.position = originalVolcanoPosition.clone();
      }
    }
    
    if (lives <= 0) {
      _gameOver();
    } else if (greyRocksCollected >= rocksNeededForBridge && !isBridgeSequence) {
      _startBridgeSequence();
    }
  }
  
  void _startVolcanoShake() {
    volcanoShaking = true;
    shakeTimer = 0;
  }
  
  void _startGameOverShake() {
    gameOverShaking = true;
    gameOverShakeTimer = 0;
    originalCameraPosition = camera.viewfinder.position.clone();
  }
  
  void _spawnRock() {
    final isGrey = random.nextBool();
    final rock = Rock(
      isGrey: isGrey,
      startPosition: Vector2(size.x / 2, size.y / 2 - 85), // Volcano mouth (top of volcano)
      gameWidth: size.x,
      gameHeight: size.y,
    );
    add(rock);
    
    // Add particle explosion at volcano mouth to represent eruption spurt
    final volcanoMouthExplosion = ParticleExplosion(
      position: Vector2(size.x / 2, size.y / 2 - 85),
      color: Colors.orange,
    );
    add(volcanoMouthExplosion);
  }
  
  void collectRock(bool isGrey) {
    if (isGrey) {
      greyRocksCollected++;
    } else {
      lives--;
      
      // Check if this is the last life
      if (lives <= 0) {
        // Create large explosion at truck position
        final largeExplosion = ParticleExplosion(
          position: truck.position.clone(),
          color: Colors.orange,
        );
        add(largeExplosion);
        
        // Hide truck
        truck.opacity = 0.0;
        
        // Start screen shake
        _startGameOverShake();
      }
    }
  }
  
  void _gameOver() {
    isGameOver = true;
    add(_GameOverText());
  }
  
  void _startBridgeSequence() {
    isBridgeSequence = true;
    bridgePhase = BridgePhase.driving_to_bridge;
    bridgeAnimationTimer = 0.0;
    
    // Stop truck controls immediately
    truck.isControlled = false;
  }
  
  void _updateBridgeSequence(double dt) {
    bridgeAnimationTimer += dt;
    
    switch (bridgePhase) {
      case BridgePhase.driving_to_bridge:
        _updateDrivingToBridge(dt);
        break;
      case BridgePhase.fading_islands:
        _updateFadingIslands(dt);
        break;
      case BridgePhase.crossing_bridge:
        _updateCrossingBridge(dt);
        break;
      case BridgePhase.completed:
        _startLevelTransition();
        break;
    }
  }
  
  void _updateDrivingToBridge(double dt) {
    // Drive truck to bridge entrance (bridge center at 62% of screen width)
    final bridgeTopCenterX = size.x * 0.62; // Bridge center at top (adjusted +0.02)
    final targetPosition = Vector2(bridgeTopCenterX, size.y / 2 + 140); // Bridge entrance
    final distance = (targetPosition - truck.position).length;
    
    if (distance > 10) {
      // Still driving to bridge - use same logic as normal truck movement
      final direction = (targetPosition - truck.position).normalized();
      truck.position += direction * 100 * dt; // Move at constant speed
      
      // Use exact same sprite logic as when user is controlling
      final movementAngle = atan2(direction.y, direction.x);
      truck.angle = movementAngle; // Set the angle for sprite selection
      // Call truck's existing sprite update method
      truck.updateSpriteForAngle();
      // Reset angle to 0 like the truck normally does (sprites are pre-rotated)
      truck.angle = 0;
      
    } else {
      // Reached bridge position - stop and face downward
      truck.position = targetPosition; // Lock to exact position
      truck.sprite = Sprite(images.fromCache('truck-180.png')); // Face downward
      truck.angle = 0; // Ensure no rotation is applied
      
      // Immediately start fading islands (no delay)
      bridgePhase = BridgePhase.fading_islands;
      bridgeAnimationTimer = 0.0;
    }
  }
  
  void _updateTruckSpriteForDirection(double movementAngle) {
    double angleDegrees = (movementAngle * 180 / pi) % 360;
    if (angleDegrees < 0) angleDegrees += 360;
    
    String spriteFile;
    if (angleDegrees >= 337.5 || angleDegrees < 22.5) {
      spriteFile = 'truck-0.png';      // Moving right
    } else if (angleDegrees >= 22.5 && angleDegrees < 67.5) {
      spriteFile = 'truck-45.png';     // Moving down-right
    } else if (angleDegrees >= 67.5 && angleDegrees < 112.5) {
      spriteFile = 'truck-90.png';     // Moving down
    } else if (angleDegrees >= 112.5 && angleDegrees < 157.5) {
      spriteFile = 'truck-135.png';    // Moving down-left
    } else if (angleDegrees >= 157.5 && angleDegrees < 202.5) {
      spriteFile = 'truck-180.png';    // Moving left
    } else if (angleDegrees >= 202.5 && angleDegrees < 247.5) {
      spriteFile = 'truck-225.png';    // Moving up-left
    } else if (angleDegrees >= 247.5 && angleDegrees < 292.5) {
      spriteFile = 'truck-270.png';    // Moving up
    } else {
      spriteFile = 'truck-315.png';    // Moving up-right
    }
    
    truck.sprite = Sprite(images.fromCache(spriteFile));
  }
  
  void _updateFadingIslands(double dt) {
    // Fade between island2 and island3 over 1 second
    final fadeProgress = (bridgeAnimationTimer / 1.0).clamp(0.0, 1.0);
    
    if (fadeProgress >= 1.0) {
      // Switch to island3 completely
      island.sprite = Sprite(images.fromCache('island3.png'));
      island.opacity = 1.0;
      bridgePhase = BridgePhase.crossing_bridge;
      bridgeAnimationTimer = 0.0;
    } else {
      // Blend between islands
      island.opacity = 1.0 - fadeProgress * 0.5; // Fade out island2 partially
      // We'll overlay island3 in render method
    }
  }
  
  void _updateCrossingBridge(double dt) {
    // Drive truck down the bridge and off screen
    truck.position.y += 80 * dt; // Move downward
    
    // Scale truck up by 40% over the crossing (starting from bridge entrance)
    final bridgeStart = size.y / 2 + 140;
    final bridgeLength = size.y * 0.4; // Bridge extends down 40% of screen height
    final crossingProgress = ((truck.position.y - bridgeStart) / bridgeLength).clamp(0.0, 1.0);
    final scaleValue = 1.0 + (0.4 * crossingProgress);
    truck.scale = Vector2.all(scaleValue);
    
    // Adjust truck X position to follow bridge center as it narrows
    // Bridge center: 62% at top, 68% at bottom (adjusted +0.02 for both)
    final bridgeTopCenterX = size.x * 0.62;
    final bridgeBottomCenterX = size.x * 0.68;
    final currentCenterX = bridgeTopCenterX + (crossingProgress * (bridgeBottomCenterX - bridgeTopCenterX));
    truck.position.x = currentCenterX;
    
    // Fade truck out as it approaches the end of the bridge (last 25% of crossing)
    if (crossingProgress > 0.75) {
      final fadeProgress = (crossingProgress - 0.75) / 0.25; // 0.0 to 1.0 over last 25%
      truck.opacity = 1.0 - fadeProgress;
    } else {
      truck.opacity = 1.0;
    }
    
    // When truck goes off screen, complete sequence
    if (truck.position.y > size.y + 50) {
      bridgePhase = BridgePhase.completed;
    }
  }
  
  void _startLevelTransition() {
    isBridgeSequence = false;
    isLevelTransition = true;
    levelTransitionTimer = 0.0;
    showingLevelText = false;
  }
  
  void _updateLevelTransition(double dt) {
    levelTransitionTimer += dt;
    
    if (!showingLevelText && levelTransitionTimer >= 1.0) {
      // After 1s fade to black, show level text
      showingLevelText = true;
      currentLevel++;
      levelTransitionTimer = 0.0;
    }
    
    if (showingLevelText && levelTransitionTimer >= 2.0) {
      // After 2s showing level text, restart game
      _restartForNextLevel();
    }
  }
  
  void playRandomCrashSound() {
    final soundIndex = random.nextInt(4) + 1; // 1-4
    FlameAudio.play('crash$soundIndex.mp3');
  }

  void _startRumbleLoop() async {
    if (!rumblePlaying) {
      rumblePlaying = true;
      while (rumblePlaying && !isGameOver) {
        await FlameAudio.play('rumble.mp3', volume: 0.5);
        // Small delay to prevent overlapping if the sound finishes quickly
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  void _restartForNextLevel() {
    lives = 3;
    greyRocksCollected = 0;
    isGameOver = false;
    isBridgeSequence = false;
    isLevelTransition = false;
    gameTime = 0;
    rockSpawnInterval = 5.0;
    volcanoShaking = false;
    shakeTimer = 0;
    volcano.position = originalVolcanoPosition.clone();
    
    // Update level-based difficulty
    maxRocks = 2 + currentLevel; // Level 1: 3 rocks, Level 2: 4 rocks, etc.
    rocksNeededForBridge = 2 + currentLevel; // Level 1: 3 needed, Level 2: 4 needed, etc.
    
    // Reset group firing variables
    isFiringGroup = false;
    rocksInCurrentGroup = 0;
    totalRocksInGroup = 0;
    groupFireTimer = 0;
    completedCycles = 0;
    
    // Reset truck
    truck.isControlled = true;
    truck.scale = Vector2.all(1.0);
    truck.pathAngle = 0;
    truck.opacity = 1.0;
    
    // Reset island
    island.sprite = Sprite(images.fromCache('island2.png'));
    island.opacity = 1.0;
    
    children.whereType<Rock>().toList().forEach((rock) => rock.removeFromParent());
    children.whereType<_GameOverText>().toList().forEach((text) => text.removeFromParent());
    children.whereType<_LevelText>().toList().forEach((text) => text.removeFromParent());
    
    // Add new level text
    add(_LevelText(currentLevel));
  }

  void restartGame() {
    currentLevel = 1;
    rumblePlaying = false; // Stop current rumble
    _restartForNextLevel();
    _startRumbleLoop(); // Restart rumble for new game
  }
  
}

class _GameHUD extends Component {
  late TextComponent livesText;
  late TextComponent rocksText;
  
  @override
  Future<void> onLoad() async {
    livesText = TextComponent(
      text: 'Lives: 3',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(20, 20),
    );
    add(livesText);
    
    rocksText = TextComponent(
      text: 'Rocks: 0/10',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(20, 50),
    );
    add(rocksText);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    final game = findGame()! as VolcanoGame;
    livesText.text = 'Lives: ${game.lives}';
    rocksText.text = 'Rocks: ${game.greyRocksCollected}/${game.rocksNeededForBridge}';
  }
}

class _GameOverText extends TextComponent {
  _GameOverText() : super(
    text: 'Game Over!\nTap to restart',
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Colors.red,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    ),
  ) {
    priority = 100; // Very high priority to be at front
  }
  
  @override
  Future<void> onLoad() async {
    position = Vector2(
      (findGame()! as VolcanoGame).size.x / 2 - size.x / 2,
      (findGame()! as VolcanoGame).size.y / 2 - size.y / 2,
    );
  }
}

class _LevelText extends TextComponent {
  final int level;
  double displayTimer = 0.0;
  
  _LevelText(this.level) : super(
    text: 'Level $level',
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Colors.red,
        fontSize: 48,
        fontWeight: FontWeight.bold,
      ),
    ),
  ) {
    priority = 1001; // Very high priority to be at front
  }
  
  @override
  Future<void> onLoad() async {
    position = Vector2(
      (findGame()! as VolcanoGame).size.x / 2 - size.x / 2,
      (findGame()! as VolcanoGame).size.y / 2 - size.y / 2,
    );
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    displayTimer += dt;
    
    // Remove after 2 seconds
    if (displayTimer >= 2.0) {
      removeFromParent();
    }
  }
}

class _ControlsHUD extends Component {
  late TextComponent controlsText;
  
  @override
  Future<void> onLoad() async {
    controlsText = TextComponent(
      text: 'Drag the control bar to steer and accelerate\nCollect grey rocks, avoid red ones!',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),
      position: Vector2(20, VolcanoGame.gameHeight - 120),
    );
    add(controlsText);
  }
}