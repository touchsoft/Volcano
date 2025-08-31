import 'dart:async' as dart_async;
import 'dart:math';
import 'dart:typed_data';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'components/truck.dart';
import 'components/rock.dart';
import 'components/tap_to_restart.dart';
import 'components/particle_explosion.dart';
import 'components/volcano_smoke.dart';
import 'components/volcano_lava.dart';
import 'components/health_bar.dart';
import 'components/rock_indicator.dart';
import 'components/toolbox.dart';
import 'components/score_display.dart';
import 'components/truck_death_effects.dart';

// Bridge animation phases
enum BridgePhase { driving_to_bridge, fading_islands, crossing_bridge, completed }

class VolcanoGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  static const double gameWidth = 480.0;
  static const double gameHeight = 720.0;
  
  late Truck truck;
  late SpriteComponent island;
  late SpriteComponent volcano;
  late VolcanoSmoke volcanoSmoke;
  late VolcanoLava volcanoLava;
  late HealthBar healthBar;
  late RockIndicator rockIndicator;
  late ScoreDisplay scoreDisplay;
  
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
  double health = 1.0; // Health as percentage (1.0 = 100%, 0.0 = 0%)
  int greyRocksCollected = 0;
  int score = 0;
  int rocksNeededForBridge = 3; // Dynamic rocks needed based on level
  
  bool isGameOver = false;
  bool isBridgeSequence = false;
  bool isLevelTransition = false;
  bool isHealthBonus = false;
  bool isTruckDying = false;
  double truckDeathTimer = 0.0;
  static const double truckDeathDuration = 3.0; // 3 seconds of death animation
  TruckDeathEffects? truckDeathEffects;
  double bridgeAnimationTimer = 0.0;
  double levelTransitionTimer = 0.0;
  int currentLevel = 1;
  bool showingLevelText = false;
  
  BridgePhase bridgePhase = BridgePhase.driving_to_bridge;
  
  // Background music management
  bool rumblePlaying = false;
  
  // Flutter Sound player for sweep tones
  final FlutterSoundPlayer soundPlayer = FlutterSoundPlayer();
  
  // Toolbox system
  bool canSpawnToolbox = true;
  double toolboxCooldownTimer = 0.0;
  static const double toolboxCooldown = 20.0; // 20 seconds cooldown
  bool hasSpawnedToolboxThisLowHealth = false;
  
  // Health bonus animation variables
  double healthBonusTimer = 0.0;
  double healthForBonus = 0.0;
  int beepCount = 0;
  double bonusDuration = 3.0;
  
  // Keyboard handling
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  final Set<LogicalKeyboardKey> _pressedBrakeKeys = <LogicalKeyboardKey>{};
  
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
    await _initializeSound();
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
      'toolbox.png',
    ]);
    
    // Load sound effects
    await Future.wait([
      FlameAudio.audioCache.load('crash1.mp3'),
      FlameAudio.audioCache.load('crash2.mp3'),
      FlameAudio.audioCache.load('crash3.mp3'),
      FlameAudio.audioCache.load('crash4.mp3'),
      FlameAudio.audioCache.load('rumble.mp3'),
      FlameAudio.audioCache.load('collected.mp3'),
      FlameAudio.audioCache.load('repair.mp3'),
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
    // Position truck just above bridge initially
    truck.pathAngle = pi / 2; // Bottom of oval
    add(truck);
    
    healthBar = HealthBar();
    add(healthBar);
    
    rockIndicator = RockIndicator();
    add(rockIndicator);
    
    scoreDisplay = ScoreDisplay();
    add(scoreDisplay);
    
    add(_ControlsHUD());
    
    
    // Add tap to restart handler
    add(TapToRestart());
    
    // Show initial level text
    add(_LevelText(currentLevel));
    
    // Set initial level difficulty
    maxRocks = 2 + currentLevel; // Level 1: 3 rocks, Level 2: 4 rocks, etc.
    rocksNeededForBridge = (2 + currentLevel).clamp(3, 20); // Level 1: 3 needed, max 20
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
    
    // Handle health bonus animation
    if (isHealthBonus) {
      _updateHealthBonus(dt);
      return;
    }
    
    // Handle bridge sequence
    if (isBridgeSequence) {
      _updateBridgeSequence(dt);
      return;
    }
    
    // Handle truck death sequence
    if (isTruckDying) {
      _updateTruckDeath(dt);
      return;
    }
    
    _handleKeyboardInput();
    
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
        // Progressive group size: Level 1 = 3-5, Level 2 = 3-6, ..., Level 10+ = 3-12
        final maxGroupSize = (3 + currentLevel).clamp(5, 12); // Min 5, max 12
        totalRocksInGroup = 3 + random.nextInt(maxGroupSize - 2); // 3 to maxGroupSize
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
    
    if (health <= 0.0 && !isGameOver) {
      _startTruckDeath();
    }
    
    // Check for level completion - wait for rocks to be illuminated in indicator
    if (!isBridgeSequence && greyRocksCollected >= rocksNeededForBridge) {
      // Make sure all rock indicator slots are properly illuminated
      final illuminatedSlots = rockIndicator.rockSlots.where((slot) => slot.opacity > 0.5).length;
      if (illuminatedSlots >= rocksNeededForBridge) {
        _startBridgeSequence();
      }
    }
    
    // Handle toolbox spawning and cooldown
    _updateToolboxSystem(dt);
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
    // Calculate red rock percentage based on level
    double redRockPercentage;
    if (currentLevel == 1) {
      redRockPercentage = 0.0; // Level 1: All rocks are grey
    } else {
      // Level 2: 20%, Level 3: 30%, etc. up to max 90%
      redRockPercentage = (0.1 * currentLevel + 0.1).clamp(0.0, 0.9);
    }
    
    final isGrey = random.nextDouble() > redRockPercentage;
    RockSize rockSize = RockSize.medium;
    double damagePercent = 0.0;
    
    // For red rocks, randomly assign size and damage
    if (!isGrey) {
      final sizeIndex = random.nextInt(20); // 1 in 20 chance for xxlarge
      if (sizeIndex == 19) {
        // 5% chance for explosive xxlarge rock
        rockSize = RockSize.xxlarge;
        damagePercent = 0.5; // 50% damage - very dangerous!
      } else {
        // Normal red rock sizes
        final normalSizeIndex = random.nextInt(4);
        switch (normalSizeIndex) {
          case 0:
            rockSize = RockSize.small;
            damagePercent = 0.10; // 10% damage
            break;
          case 1:
            rockSize = RockSize.medium;
            damagePercent = 0.20; // 20% damage
            break;
          case 2:
            rockSize = RockSize.large;
            damagePercent = 0.25; // 25% damage
            break;
          case 3:
            rockSize = RockSize.xlarge;
            damagePercent = 0.33; // 33% damage
            break;
        }
      }
    }
    
    // Calculate speed multiplier based on level (10% increase per level)
    final speedMultiplier = 1.0 + (currentLevel - 1) * 0.1;
    
    final rock = Rock(
      isGrey: isGrey,
      startPosition: Vector2(size.x / 2, size.y / 2 - 85), // Volcano mouth (top of volcano)
      gameWidth: size.x,
      gameHeight: size.y,
      rockSize: rockSize,
      damagePercent: damagePercent,
      speedMultiplier: speedMultiplier,
    );
    add(rock);
    
    // Add particle explosion at volcano mouth to represent eruption spurt
    final volcanoMouthExplosion = ParticleExplosion(
      position: Vector2(size.x / 2, size.y / 2 - 85),
      color: Colors.orange,
    );
    add(volcanoMouthExplosion);
  }
  
  void collectRock(bool isGrey, {double damagePercent = 0.0}) {
    if (isGrey) {
      // Play collection sound
      FlameAudio.play('collected.mp3');
      
      // Trigger rock collection animation and increment counter when animation completes
      rockIndicator.triggerRockCollectionAnimation(greyRocksCollected, () {
        greyRocksCollected++;
        score += 100; // Award 100 points per grey rock
      });
    } else {
      // Apply percentage-based damage
      health -= damagePercent;
      health = health.clamp(0.0, 1.0);
      
      // Update lives based on health (for backwards compatibility)
      lives = (health * 3).ceil().clamp(0, 3);
      
      // Check if health is depleted
      if (health <= 0.0 && !isTruckDying && !isGameOver) {
        // Start truck death sequence instead of immediate game over
        _startTruckDeath();
      }
    }
  }
  
  void _startTruckDeath() {
    isTruckDying = true;
    truckDeathTimer = 0.0;
    
    // Stop truck movement immediately
    truck.isControlled = false;
    
    // Stop spawning new rocks
    isFiringGroup = false;
    
    // Add flames and smoke effects to truck
    truckDeathEffects = TruckDeathEffects(truck: truck);
    add(truckDeathEffects!);
  }
  
  void _updateTruckDeath(double dt) {
    truckDeathTimer += dt;
    
    if (truckDeathTimer >= truckDeathDuration) {
      // Create final explosion at truck position
      final explosion = ParticleExplosion(
        position: truck.position.clone(),
        colors: [Colors.red, Colors.orange, Colors.yellow, Colors.black, Colors.white],
        particleCount: 50,
        speedMultiplier: 3.0,
        sizeMultiplier: 2.5,
      );
      add(explosion);
      
      // Play explosion sound
      playRandomCrashSound();
      
      // Hide truck after explosion
      truck.opacity = 0.0;
      
      // Remove truck death effects
      if (truckDeathEffects != null) {
        truckDeathEffects!.removeFromParent();
        truckDeathEffects = null;
      }
      
      // Death animation complete, show game over
      _gameOver();
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
        _startHealthBonus();
        break;
    }
  }
  
  void _updateDrivingToBridge(double dt) {
    // Drive truck along oval path to bridge entrance
    final bridgeTopCenterX = size.x * 0.62; // Bridge center at top
    final bridgeY = size.y / 2 + 140; // Bridge entrance Y
    
    // Calculate target angle on oval path closest to bridge entrance
    final targetAngle = pi / 2; // Bottom of oval (90 degrees) - bridge position
    
    // Continue following oval path at half speed toward target angle
    final speed = 1.045; // Half of normal max speed (2.09 / 2)
    truck.pathAngle += speed * truck.direction * dt;
    
    // Normalize angle
    if (truck.pathAngle > 2 * pi) truck.pathAngle -= 2 * pi;
    if (truck.pathAngle < 0) truck.pathAngle += 2 * pi;
    
    // Update truck position using oval path (same as normal gameplay)
    final centerX = size.x / 2;
    final centerY = size.y / 2 + 40;
    final ovalWidth = 160.0;
    final ovalHeight = 50.0;
    
    final x = centerX + ovalWidth * cos(truck.pathAngle);
    final y = centerY + ovalHeight * sin(truck.pathAngle);
    truck.position = Vector2(x, y);
    
    // Update truck scale based on position (3D perspective effect)
    final normalizedY = (sin(truck.pathAngle) + 1) / 2;
    final minScale = 0.6;
    final maxScale = 0.9;
    final scaleValue = minScale + (maxScale - minScale) * normalizedY;
    truck.scale = Vector2.all(scaleValue);
    
    // Update truck rotation and sprite (same as normal gameplay)
    final a = ovalWidth;
    final b = ovalHeight;
    final dx = -a * sin(truck.pathAngle);
    final dy = b * cos(truck.pathAngle);
    
    double tangentAngle = atan2(dy, dx);
    if (truck.direction < 0) {
      tangentAngle += pi;
    }
    tangentAngle = tangentAngle % (2 * pi);
    if (tangentAngle < 0) tangentAngle += 2 * pi;
    
    truck.angle = tangentAngle;
    truck.updateSpriteForAngle();
    truck.angle = 0; // Reset after sprite update
    
    // Check if we've reached the bridge position (bottom of oval)
    final angleDistance = (truck.pathAngle - targetAngle).abs();
    final angleDistanceAlt = (truck.pathAngle - targetAngle + 2 * pi).abs();
    final minAngleDistance = min(angleDistance, angleDistanceAlt);
    
    if (minAngleDistance < 0.1) { // Close enough to bridge position
      // Position truck exactly at bridge entrance
      truck.position = Vector2(bridgeTopCenterX, bridgeY);
      truck.sprite = Sprite(images.fromCache('truck-180.png')); // Face downward
      truck.angle = 0;
      
      // Start fading islands
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
  
  void _startHealthBonus() {
    isBridgeSequence = false;
    isHealthBonus = true;
    healthBonusTimer = 0.0;
    healthForBonus = health; // Store the health to convert to points
    beepCount = 0;
    
    // Calculate bonus duration based on health percentage
    // 100% health = 3s, 66.67% health = 2s, 33.33% health = 1s, 0% health = 0s
    bonusDuration = health * 3.0;
    if (bonusDuration < 0.1) bonusDuration = 0.1; // Minimum duration to prevent divide by zero
    
    // Start the sweep tone
    _playSweepTone(200.0, 1000.0, bonusDuration);
  }
  
  void _updateHealthBonus(double dt) {
    healthBonusTimer += dt;
    
    // Calculate how many steps we need and step duration
    final totalSteps = (health * 100).round(); // 1 step per 1% health
    final stepDuration = bonusDuration / totalSteps; // Spread over calculated duration
    
    if (healthBonusTimer >= stepDuration && healthForBonus > 0.0) {
      // Reduce health by 1% and add 5 points
      healthForBonus -= 0.01;
      healthForBonus = healthForBonus.clamp(0.0, 1.0);
      score += 5;
      
      // No individual beeps needed - sweep tone plays continuously
      
      healthBonusTimer = 0.0;
      beepCount++;
    }
    
    // When health is fully depleted or time has passed
    if (healthForBonus <= 0.0 || (beepCount * stepDuration) >= bonusDuration) {
      // Set actual health to 0 after bonus completes - don't reset it
      health = 0.0;
      _startLevelTransition();
    }
  }
  
  void _startLevelTransition() {
    isHealthBonus = false;
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
  
  void playRepairSound() {
    FlameAudio.play('repair.mp3');
  }
  
  Future<void> _initializeSound() async {
    // Skip flutter_sound initialization for now due to web/desktop compatibility issues
    print('Sound system initialized (using FlameAudio fallback)');
  }
  
  Future<void> _playSweepTone(double startFreq, double endFreq, double durationSeconds) async {
    print('Playing bonus sound for 1.5s');
    FlameAudio.play('bonus.mp3');
  }
  
  void _updateToolboxSystem(double dt) {
    // Update cooldown timer
    if (!canSpawnToolbox) {
      toolboxCooldownTimer += dt;
      if (toolboxCooldownTimer >= toolboxCooldown) {
        canSpawnToolbox = true;
        toolboxCooldownTimer = 0.0;
        hasSpawnedToolboxThisLowHealth = false;
      }
    }
    
    // Check if we should spawn a toolbox
    if (canSpawnToolbox && health < 0.5 && !hasSpawnedToolboxThisLowHealth) {
      // Only spawn if no toolbox currently exists
      final existingToolbox = children.whereType<Toolbox>().isEmpty;
      if (existingToolbox) {
        print('Spawning toolbox! Health: ${(health * 100).round()}%');
        _spawnToolbox();
        hasSpawnedToolboxThisLowHealth = true;
      } else {
        print('Toolbox already exists, not spawning another');
      }
    }
    
    // Reset flag if health goes above 50%
    if (health >= 0.5) {
      hasSpawnedToolboxThisLowHealth = false;
    }
  }
  
  void _spawnToolbox() {
    if (!canSpawnToolbox) return;
    
    final toolbox = Toolbox();
    add(toolbox);
    
    // Start cooldown
    canSpawnToolbox = false;
    toolboxCooldownTimer = 0.0;
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
  
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Only handle keyboard input if truck is controlled
    if (!truck.isControlled) return KeyEventResult.ignored;
    
    // Handle spacebar for direction change (only on key down to prevent rapid toggling)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      truck.changeDirection();
      return KeyEventResult.handled;
    }
    
    return KeyEventResult.ignored;
  }
  
  
  void _handleKeyboardInput() {
    // Only handle keyboard input if truck is controlled
    if (!truck.isControlled) return;
    
    // Check for up arrow key (accelerate)
    if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowUp)) {
      if (!_pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
        truck.startAccelerating();
        _pressedKeys.add(LogicalKeyboardKey.arrowUp);
      }
    } else {
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
        truck.stopAccelerating();
        _pressedKeys.remove(LogicalKeyboardKey.arrowUp);
      }
    }
    
    // Check for down arrow key (brake)
    if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowDown)) {
      if (!_pressedBrakeKeys.contains(LogicalKeyboardKey.arrowDown)) {
        truck.startBraking();
        _pressedBrakeKeys.add(LogicalKeyboardKey.arrowDown);
      }
    } else {
      if (_pressedBrakeKeys.contains(LogicalKeyboardKey.arrowDown)) {
        truck.stopBraking();
        _pressedBrakeKeys.remove(LogicalKeyboardKey.arrowDown);
      }
    }
  }

  void _restartForNextLevel() {
    lives = 3;
    health = 1.0; // Reset health to 100%
    greyRocksCollected = 0;
    isGameOver = false;
    isBridgeSequence = false;
    isLevelTransition = false;
    isTruckDying = false;
    truckDeathTimer = 0.0;
    
    // Clean up truck death effects if any remain
    if (truckDeathEffects != null) {
      truckDeathEffects!.removeFromParent();
      truckDeathEffects = null;
    }
    
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
    truck.opacity = 1.0;
    
    // Position truck just above bridge (bottom center of oval)
    truck.pathAngle = pi / 2; // Bottom of oval (90 degrees)
    truck.speed = 0.0; // Start at zero speed
    truck.momentum = 0.0; // Start with zero momentum
    truck.isAccelerating = false;
    truck.isBraking = false;
    
    // Reset island
    island.sprite = Sprite(images.fromCache('island2.png'));
    island.opacity = 1.0;
    
    // Reset rock indicator
    rockIndicator.resetForNewLevel();
    
    // Reset toolbox system
    canSpawnToolbox = true;
    toolboxCooldownTimer = 0.0;
    hasSpawnedToolboxThisLowHealth = false;
    
    children.whereType<Rock>().toList().forEach((rock) => rock.removeFromParent());
    children.whereType<Toolbox>().toList().forEach((toolbox) => toolbox.removeFromParent());
    children.whereType<_GameOverText>().toList().forEach((text) => text.removeFromParent());
    children.whereType<_LevelText>().toList().forEach((text) => text.removeFromParent());
    
    // Add new level text
    add(_LevelText(currentLevel));
  }

  void restartGame() {
    currentLevel = 1;
    score = 0; // Reset score when restarting game
    rumblePlaying = false; // Stop current rumble
    _restartForNextLevel();
    _startRumbleLoop(); // Restart rumble for new game
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
      text: 'A = Accelerate, B = Brake, D = Direction (or ↑/↓/Space)\nCollect grey rocks, avoid red ones!',
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