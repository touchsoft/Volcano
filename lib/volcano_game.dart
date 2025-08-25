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

class VolcanoGame extends FlameGame with HasCollisionDetection {
  static const double gameWidth = 400.0;
  static const double gameHeight = 600.0;
  
  late Truck truck;
  late SpriteComponent island;
  late SpriteComponent volcano;
  
  double rockSpawnTimer = 0;
  final double rockSpawnInterval = 2.0;
  final Random random = Random();
  
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
      size: Vector2(320, 160),
      position: Vector2(gameWidth / 2 - 160, gameHeight / 2 - 80),
    );
    add(island);
    
    volcano = SpriteComponent(
      sprite: Sprite(images.fromCache('volcano.png')),
      size: Vector2(120, 120),
      position: Vector2(gameWidth / 2 - 60, gameHeight / 2 - 80),
    );
    add(volcano);
    
    truck = Truck(gameWidth: gameWidth, gameHeight: gameHeight);
    add(truck);
    
    add(_GameHUD());
    add(_ControlsHUD());
    
    final inputHandler = InputHandler()
      ..size = Vector2(gameWidth, gameHeight)
      ..paint.color = const Color(0x00000000); // Transparent
    add(inputHandler);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (isGameOver) return;
    
    rockSpawnTimer += dt;
    if (rockSpawnTimer >= rockSpawnInterval) {
      _spawnRock();
      rockSpawnTimer = 0;
    }
    
    if (lives <= 0) {
      _gameOver();
    } else if (greyRocksCollected >= rocksNeededForBridge) {
      _levelComplete();
    }
  }
  
  void _spawnRock() {
    final isGrey = random.nextBool();
    final rock = Rock(
      isGrey: isGrey,
      startPosition: Vector2(gameWidth / 2, gameHeight / 2),
      gameWidth: gameWidth,
      gameHeight: gameHeight,
    );
    add(rock);
  }
  
  void collectRock(bool isGrey) {
    if (isGrey) {
      greyRocksCollected++;
    } else {
      lives--;
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
  );
  
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
  );
  
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
      text: 'Swipe left/right or tap sides to change direction\nTap top/bottom to change speed\nCollect grey rocks, avoid red ones!',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),
      position: Vector2(20, VolcanoGame.gameHeight - 80),
    );
    add(controlsText);
  }
}