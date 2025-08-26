import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'components/truck.dart';
import 'components/rock.dart';
import 'components/input_handler.dart';
import 'components/control_bar.dart';
import 'components/particle_explosion.dart';

class VolcanoGame extends FlameGame with HasCollisionDetection {
  static const double gameWidth = 480.0;
  static const double gameHeight = 720.0;
  
  late Truck truck;
  late SpriteComponent island;
  late SpriteComponent volcano;
  
  double rockSpawnTimer = 0;
  double rockSpawnInterval = 2.0;
  final Random random = Random();
  double gameTime = 0;
  int currentActiveRocks = 0;
  final int maxRocks = 5;
  bool volcanoShaking = false;
  double shakeTimer = 0;
  Vector2 originalVolcanoPosition = Vector2.zero();
  
  bool gameOverShaking = false;
  double gameOverShakeTimer = 0;
  Vector2 originalCameraPosition = Vector2.zero();
  
  int lives = 3;
  int greyRocksCollected = 0;
  int rocksNeededForBridge = 10;
  
  bool isGameOver = false;
  
  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

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
      'island.png',
      'volcano.png', 
      'truck.png',
      'rock-grey.png',
      'rock-red.png',
    ]);
  }
  
  void _setupGame() {
    island = SpriteComponent(
      sprite: Sprite(images.fromCache('island.png')),
      size: Vector2(400, 200),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2),
    );
    island.priority = -10; // Always at back
    add(island);
    
    originalVolcanoPosition = Vector2(size.x / 2, size.y / 2 - 75);
    volcano = SpriteComponent(
      sprite: Sprite(images.fromCache('volcano.png')),
      size: Vector2(150, 150),
      anchor: Anchor.center,
      position: originalVolcanoPosition.clone(),
    );
    volcano.priority = 10; // Always at front
    add(volcano);
    
    truck = Truck(gameWidth: size.x, gameHeight: size.y);
    add(truck);
    
    add(_GameHUD());
    add(_ControlsHUD());
    
    final inputHandler = InputHandler()
      ..size = Vector2(gameWidth, gameHeight)
      ..paint.color = const Color(0x00000000); // Transparent
    add(inputHandler);
    
    add(ControlBar());
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (isGameOver) return;
    
    gameTime += dt;
    
    // Update current rock count
    currentActiveRocks = children.whereType<Rock>().length;
    
    // Adjust spawn rate over time (faster spawning as time goes on)
    rockSpawnInterval = (2.0 - (gameTime * 0.02)).clamp(0.5, 2.0);
    
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
    
    // Handle volcano shaking
    if (volcanoShaking) {
      shakeTimer += dt;
      final shakeIntensity = 2.0;
      final shakeX = (random.nextDouble() - 0.5) * shakeIntensity;
      final shakeY = (random.nextDouble() - 0.5) * shakeIntensity;
      volcano.position = originalVolcanoPosition + Vector2(shakeX, shakeY);
      
      if (shakeTimer >= 0.3) { // Shake for 0.3 seconds
        volcanoShaking = false;
        shakeTimer = 0;
        volcano.position = originalVolcanoPosition.clone();
        _spawnRock();
      }
    } else {
      rockSpawnTimer += dt;
      if (rockSpawnTimer >= rockSpawnInterval && currentActiveRocks < maxRocks) {
        _startVolcanoShake();
        rockSpawnTimer = 0;
      }
    }
    
    if (lives <= 0) {
      _gameOver();
    } else if (greyRocksCollected >= rocksNeededForBridge) {
      _levelComplete();
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
      startPosition: Vector2(size.x / 2, size.y / 2 - 150), // Volcano mouth (top of volcano)
      gameWidth: size.x,
      gameHeight: size.y,
    );
    add(rock);
    
    // Add particle explosion at volcano mouth to represent eruption spurt
    final volcanoMouthExplosion = ParticleExplosion(
      position: Vector2(size.x / 2, size.y / 2 - 150),
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
  
  void _levelComplete() {
    isGameOver = true;
    add(_LevelCompleteText());
  }
  
  void restartGame() {
    lives = 3;
    greyRocksCollected = 0;
    isGameOver = false;
    gameTime = 0; // Reset game time
    rockSpawnInterval = 2.0; // Reset to slow spawn rate
    volcanoShaking = false; // Stop any shaking
    shakeTimer = 0;
    volcano.position = originalVolcanoPosition.clone(); // Reset volcano position
    children.whereType<Rock>().toList().forEach((rock) => rock.removeFromParent());
    children.whereType<_GameOverText>().toList().forEach((text) => text.removeFromParent());
    children.whereType<_LevelCompleteText>().toList().forEach((text) => text.removeFromParent());
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
    rocksText.text = 'Rocks: ${game.greyRocksCollected}/10';
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

class _LevelCompleteText extends TextComponent {
  _LevelCompleteText() : super(
    text: 'Level Complete!\nBridge Built!',
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Colors.green,
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